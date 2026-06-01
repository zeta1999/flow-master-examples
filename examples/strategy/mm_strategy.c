/*
 * mm_strategy.c — a minimal MARKET-MAKING strategy SKELETON built on
 * Paganini's algorithms, consumed from a BINARY-ONLY build (links
 * libpaganini; no Paganini source here).
 *
 * Per tick the strategy uses three Paganini algos to decide its quotes:
 *   1. paganini_microprice      → size-weighted fair value from the book
 *   2. paganini_sample_variance → realised vol over a rolling window (Welford)
 *   3. paganini_as_quote        → Avellaneda-Stoikov inventory-skewed bid/ask
 * It runs an inventory band, simulates fills against the next mid, and marks
 * the book to market. This is the skeleton you extend into a real strategy
 * (swap the synthetic feed for live ticks; add regime/impact via
 * paganini_bocpd_changepoints / paganini_kyle_lambda).
 *
 * Build & run:  ./run.sh
 */
#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <math.h>

extern int32_t paganini_as_quote(double mid, double inventory, double gamma,
                                 double k, double sigma, double time_left,
                                 double *out_bid, double *out_ask);
extern double  paganini_microprice(double bid, double ask,
                                   double bid_qty, double ask_qty);
extern double  paganini_sample_variance(const double *xs, size_t n);

#define N_TICKS   200   /* ticks to simulate                       */
#define WINDOW    20    /* rolling vol window                      */
#define INV_LIMIT 5     /* max absolute inventory (quoting band)   */

/* Deterministic synthetic mid: a mean-reverting oscillation around 100.
 * (Add a drift term here — e.g. + 0.01*i — to see how a naive symmetric
 * maker bleeds against a trend; that's where regime/impact algos come in.) */
static double mid_path(int i) {
    return 100.0 + 2.0 * sin((double)i * 0.10);
}

int main(void) {
    double rets[WINDOW];     /* rolling window of mid RETURNS (Δmid) */
    int    count = 0;        /* returns seen so far                  */
    double prev_mid = mid_path(0);
    double inventory = 0.0;  /* current position (units)             */
    double cash = 0.0;       /* realised cash flow                   */
    int    fills = 0;

    for (int i = 1; i < N_TICKS; i++) {
        double mid = mid_path(i);
        rets[(i - 1) % WINDOW] = mid - prev_mid;   /* per-tick return */
        prev_mid = mid;
        if (count < WINDOW) count++;

        /* Warm up the vol window before quoting. */
        if (count < WINDOW) continue;

        /* 1. Per-tick realised vol = std of returns (Welford variance). */
        double var = paganini_sample_variance(rets, (size_t)count);
        double sigma = sqrt(var);
        if (!(sigma > 0.01)) sigma = 0.01;   /* floor; also covers NaN */

        /* 2. Fair value = microprice of a tight book with mild imbalance. */
        double bid_qty = 8.0 + (double)(i % 5);
        double ask_qty = 8.0 + (double)((i * 2) % 5);
        double fair = paganini_microprice(mid - 0.05, mid + 0.05, bid_qty, ask_qty);

        /* 3. Avellaneda-Stoikov quote around fair, skewed by inventory.
         *    k is order-book liquidity (larger k → tighter optimal spread).
         *    gamma is risk aversion: it scales the inventory skew term
         *    q·gamma·sigma², so with small per-tick sigma it must be large
         *    for inventory control to matter relative to the spread. */
        double my_bid = 0.0, my_ask = 0.0;
        if (paganini_as_quote(fair, inventory, /*gamma*/ 20.0, /*k*/ 15.0,
                              sigma, /*time_left*/ 1.0, &my_bid, &my_ask) != 0)
            continue;

        /* Inventory band: stop quoting the side that would breach the limit. */
        int can_buy  = inventory <  (double)INV_LIMIT;
        int can_sell = inventory > -(double)INV_LIMIT;

        /* Fill model: the next mid reveals where the market traded. If it
         * dips to our bid we get hit (we buy); if it lifts our ask we get
         * lifted (we sell). At most one fill per tick. */
        double next_mid = mid_path(i + 1);
        if (can_buy && next_mid <= my_bid) {
            inventory += 1.0; cash -= my_bid; fills++;
        } else if (can_sell && next_mid >= my_ask) {
            inventory -= 1.0; cash += my_ask; fills++;
        }
    }

    double final_mid = mid_path(N_TICKS);
    double mtm_pnl = cash + inventory * final_mid;
    double last_var = paganini_sample_variance(rets, WINDOW);

    printf("MM ticks=%d fills=%d\n", N_TICKS, fills);
    printf("MM final_inventory=%.0f cash=%.4f\n", inventory, cash);
    printf("MM MtM_PnL=%.4f final_sigma=%.4f\n", mtm_pnl, sqrt(last_var));
    return 0;
}
