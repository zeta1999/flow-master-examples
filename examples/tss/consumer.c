/*
 * tss/consumer.c — MASS time-series similarity search against a BINARY-ONLY
 * Paganini build. No Paganini source here: the entry points are re-declared
 * inline and resolved from libpaganini at link time.
 *
 * Build & run:  ./build_and_run.sh
 */
#include <stdio.h>
#include <stddef.h>
#include <stdint.h>

extern int32_t paganini_mass_profile(const double *series, size_t n,
                                     const double *query, size_t m, double *out);
extern int32_t paganini_mass_best_match(const double *series, size_t n,
                                        const double *query, size_t m,
                                        size_t *out_index, double *out_dist);

int main(void) {
    /* A series with an embedded repeat of the first 4 samples at offset 4. */
    double series[8] = {1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0};
    double query[4]  = {1.0, 2.0, 3.0, 4.0};
    size_t n = 8, m = 4;

    /* Full z-normalised distance profile (length n - m + 1 = 5). */
    double prof[5];
    if (paganini_mass_profile(series, n, query, m, prof) != 0) {
        fprintf(stderr, "mass_profile failed\n");
        return 1;
    }
    printf("MASS profile_len=%zu\n", n - m + 1);
    printf("MASS profile[0]=%.4f profile[4]=%.4f\n", prof[0], prof[4]);

    /* Nearest-subsequence convenience. */
    size_t idx = (size_t)-1;
    double dist = -1.0;
    if (paganini_mass_best_match(series, n, query, m, &idx, &dist) != 0) {
        fprintf(stderr, "mass_best_match failed\n");
        return 1;
    }
    printf("MASS best_index=%zu best_dist=%.4f\n", idx, dist);
    return 0;
}
