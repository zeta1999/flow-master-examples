// consumer.cpp — idiomatic C++ over Paganini's binary-only C ABI.
//
// No Paganini source here: we declare the C entry points in an `extern "C"`
// block and wrap them in a small `paganini` namespace that speaks C++
// (std::optional, std::vector, std::span-free). Links against the compiled
// libpaganini.{a,dylib,so}.
//
// Build & run:  ./build_and_run.sh
#include <cstdint>
#include <cstddef>
#include <cmath>
#include <optional>
#include <vector>
#include <iostream>
#include <iomanip>

extern "C" {
    std::uint32_t paganini_abi_version(void);
    std::int32_t  paganini_as_quote(double mid, double inventory, double gamma,
                                    double k, double sigma, double time_left,
                                    double *out_bid, double *out_ask);
    double        paganini_microprice(double bid, double ask,
                                      double bid_qty, double ask_qty);
    double        paganini_sample_variance(const double *xs, std::size_t n);
}

namespace paganini {

inline std::uint32_t abi_version() { return paganini_abi_version(); }

struct Quote { double bid, ask; };

// AS optimal quote; std::nullopt on degenerate params (the ABI's rc=-1).
inline std::optional<Quote> as_quote(double mid, double inventory, double gamma,
                                     double k, double sigma, double time_left) {
    double bid = 0.0, ask = 0.0;
    if (paganini_as_quote(mid, inventory, gamma, k, sigma, time_left, &bid, &ask) != 0)
        return std::nullopt;
    return Quote{bid, ask};
}

inline double microprice(double bid, double ask, double bid_qty, double ask_qty) {
    return paganini_microprice(bid, ask, bid_qty, ask_qty);
}

// Variance over any contiguous container of doubles.
inline double sample_variance(const std::vector<double>& xs) {
    return paganini_sample_variance(xs.data(), xs.size());
}

} // namespace paganini

int main() {
    std::cout << std::fixed << std::setprecision(4);
    std::cout << "paganini ABI version: " << paganini::abi_version() << "\n";

    if (auto q = paganini::as_quote(100.0, 0.0, 0.1, 1.5, 0.2, 1.0)) {
        std::cout << "AS quote bid=" << q->bid << " ask=" << q->ask
                  << " spread=" << (q->ask - q->bid) << "\n";
    } else {
        std::cerr << "as_quote: no quote\n";
        return 1;
    }

    std::cout << "microprice=" << paganini::microprice(99.0, 101.0, 5.0, 15.0) << "\n";

    std::vector<double> xs{100.0, 101.0, 99.0, 102.0, 98.0};
    std::cout << "variance=" << paganini::sample_variance(xs) << "\n";

    if (std::isnan(paganini::sample_variance({100.0})))
        std::cout << "variance(n<2)=NaN (guard OK)\n";

    return 0;
}
