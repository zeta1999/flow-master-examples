// main.go — call Paganini from Go via cgo, against a BINARY-ONLY build.
//
// No Paganini source: the four stable C-ABI entry points are declared in the
// cgo preamble below and resolved at link time from libpaganini. The link
// flags (-L/-lpaganini) and the runtime loader path are supplied by run.sh
// through CGO_LDFLAGS / DYLD_LIBRARY_PATH, since the dist location is dynamic.
package main

/*
#include <stddef.h>
#include <stdint.h>

uint32_t paganini_abi_version(void);
int32_t  paganini_as_quote(double mid, double inventory, double gamma,
                           double k, double sigma, double time_left,
                           double *out_bid, double *out_ask);
double   paganini_microprice(double bid, double ask, double bid_qty, double ask_qty);
double   paganini_sample_variance(const double *xs, size_t n);
*/
import "C"

import (
	"fmt"
	"math"
	"os"
	"unsafe"
)

func main() {
	fmt.Printf("paganini ABI version: %d\n", uint32(C.paganini_abi_version()))

	var bid, ask C.double
	rc := C.paganini_as_quote(100.0, 0.0, 0.1, 1.5, 0.2, 1.0, &bid, &ask)
	if rc != 0 {
		fmt.Fprintln(os.Stderr, "as_quote: no quote")
		os.Exit(1)
	}
	fmt.Printf("AS quote bid=%.4f ask=%.4f spread=%.4f\n",
		float64(bid), float64(ask), float64(ask-bid))

	mp := C.paganini_microprice(99.0, 101.0, 5.0, 15.0)
	fmt.Printf("microprice=%.4f\n", float64(mp))

	xs := []C.double{100.0, 101.0, 99.0, 102.0, 98.0}
	v := C.paganini_sample_variance((*C.double)(unsafe.Pointer(&xs[0])), C.size_t(len(xs)))
	fmt.Printf("variance=%.4f\n", float64(v))

	one := []C.double{100.0}
	if math.IsNaN(float64(C.paganini_sample_variance((*C.double)(unsafe.Pointer(&one[0])), 1))) {
		fmt.Println("variance(n<2)=NaN (guard OK)")
	}
}
