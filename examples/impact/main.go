// impact/main.go — calibrate Kyle's lambda (price impact) from a trade tape
// via cgo, against a BINARY-ONLY Paganini build. No Paganini source here;
// the entry point is declared in the cgo preamble and linked from libpaganini
// (flags supplied by run.sh).
package main

/*
#include <stddef.h>
double paganini_kyle_lambda(const double *signed_volumes, const double *mids,
                            size_t n, double lambda_ff, double p0);
*/
import "C"

import (
	"fmt"
	"unsafe"
)

func main() {
	// Synthetic tape: each trade moves the mid by trueLambda * signedVolume,
	// so RLS should recover trueLambda. +qty = buy, -qty = sell.
	trueLambda := 0.05
	vols := []float64{10, -5, 8, -12, 6, -3, 9, -7, 4, -6}

	mids := make([]float64, len(vols))
	mid := 100.0
	for i, v := range vols {
		mid += trueLambda * v // price impact of this trade
		mids[i] = mid         // mid AFTER the trade
	}

	cVols := make([]C.double, len(vols))
	cMids := make([]C.double, len(mids))
	for i := range vols {
		cVols[i] = C.double(vols[i])
		cMids[i] = C.double(mids[i])
	}

	lambda := C.paganini_kyle_lambda(
		(*C.double)(unsafe.Pointer(&cVols[0])),
		(*C.double)(unsafe.Pointer(&cMids[0])),
		C.size_t(len(vols)), 0.99, 1.0,
	)

	fmt.Printf("Kyle trades=%d true_lambda=%.4f\n", len(vols), trueLambda)
	fmt.Printf("Kyle estimated_lambda=%.4f\n", float64(lambda))
}
