/*
 * consumer.c — call Paganini from C against a BINARY-ONLY build.
 *
 * This file ships in flow-master-examples and contains NO Paganini source:
 * the four entry points are re-declared inline below, exactly matching the
 * stable C ABI (see dist/include/paganini.h, which the build script also
 * puts on the include path). At link time we resolve them from the compiled
 * libpaganini.{a,dylib,so} — no Rust, no headers from the library required.
 *
 * Build & run:  ./build_and_run.sh   (needs PAGANINI_DIST set; see ../../scripts)
 */
#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <math.h>

/* ---- Paganini stable C ABI (mirrors dist/include/paganini.h) ---------- */
extern uint32_t paganini_abi_version(void);
extern int32_t  paganini_as_quote(double mid, double inventory, double gamma,
                                  double k, double sigma, double time_left,
                                  double *out_bid, double *out_ask);
extern double   paganini_microprice(double bid, double ask,
                                    double bid_qty, double ask_qty);
extern double   paganini_sample_variance(const double *xs, size_t n);
/* ----------------------------------------------------------------------- */

int main(void) {
    /* 1. ABI probe — confirms we linked the library we expect. */
    printf("paganini ABI version: %u\n", paganini_abi_version());

    /* 2. Avellaneda-Stoikov: optimal symmetric quote around a 100.00 mid
     *    with flat inventory. Returns 0 and brackets the mid (bid < ask). */
    double bid = 0.0, ask = 0.0;
    int rc = paganini_as_quote(/*mid*/100.0, /*inventory*/0.0, /*gamma*/0.1,
                               /*k*/1.5, /*sigma*/0.2, /*time_left*/1.0,
                               &bid, &ask);
    if (rc != 0) { fprintf(stderr, "as_quote failed rc=%d\n", rc); return 1; }
    printf("AS quote bid=%.4f ask=%.4f spread=%.4f\n", bid, ask, ask - bid);

    /* 3. Microprice: size-weighted fair value, provably within [bid, ask].
     *    Heavier ask size (15 vs 5) pulls the fair value toward the bid. */
    double mp = paganini_microprice(99.0, 101.0, /*bid_qty*/5.0, /*ask_qty*/15.0);
    printf("microprice=%.4f\n", mp);

    /* 4. Welford streaming variance over a small sample. Bessel-corrected;
     *    equals the batch sample variance. */
    double xs[5] = {100.0, 101.0, 99.0, 102.0, 98.0};
    double var = paganini_sample_variance(xs, 5);
    printf("variance=%.4f\n", var);

    /* NaN guards return NaN rather than trapping. */
    if (isnan(paganini_sample_variance(xs, 1)))
        printf("variance(n<2)=NaN (guard OK)\n");

    return 0;
}
