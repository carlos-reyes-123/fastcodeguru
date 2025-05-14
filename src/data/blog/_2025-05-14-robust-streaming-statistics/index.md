+++
draft       = false
featured    = false
title       = "Robust Streaming Statistics: When Every Byte Counts"
slug        = "robust-streaming-statistics"
description = "Have you ever tried to compute statistics on a dataset so large it wouldn't fit in memory?"
ogImage     = "./robust-streaming-statistics.png"
pubDatetime = 2025-05-14T16:00:00Z
author      = "Carlos Reyes"
tags        = [
    "Streaming Algorithms",
    "Running Mean",
    "Welford Algorithm",
    "Streaming Variance",
    "Streaming Skewness",
    "Streaming Kurtosis",
    "Quantile Estimation",
    "P2 Algorithm",
    "T-Digest",
    "Interquartile Range",
    "Outlier Detection",
    "Bloom Filters",
    "Count-Min Sketch",
    "Top-K Heavy Hitters",
    "Gaussian Noise",
    "Median Absolute Deviation",
    "High-Frequency Trading",
    "Performance Monitoring",
    "SIMD Optimization",
    "C++23 Tutorial",
]
+++

![Robust Streaming Statistics](./robust-streaming-statistics.png "Robust Streaming Statistics")

## Table of Contents

---

## Introduction

Have you ever tried to compute statistics on a dataset so large it wouldn't fit in memory? I've been there, and it's why streaming statistics have become one of my favorite topics to explore. Whether I'm analyzing real-time trading data, monitoring game server performance, or processing sensor readings from IoT devices, streaming algorithms have saved me countless times.

Today, I'll take you on a deep dive into the world of robust streaming statistics. We'll explore why they matter, how they work, and I'll share implementations that you can use in your own high-performance applications.

## Why Streaming Statistics Matter

Let me start with a war story. A few years ago, I was working on a high-frequency trading system that needed to monitor price movements across thousands of instruments. The naive approach—storing all values and computing statistics at the end—would have blown through our memory budget in minutes. That's when I discovered the elegance of streaming algorithms.

Streaming statistics allow us to:
- Process data that exceeds available memory
- Maintain constant memory usage regardless of data size
- Provide real-time updates as data arrives
- Handle unbounded data streams

> **Key Insight**: In streaming statistics, we trade perfect accuracy for bounded memory usage. The art lies in making this trade-off intelligently.

## The Fundamentals: Mean and Variance

Let's start with the basics. Computing a running mean is straightforward—keep a sum and count:

```cpp
class RunningMean {
private:
    double sum = 0.0;
    size_t count = 0;

public:
    void update(double value) {
        sum += value;
        ++count;
    }

    double mean() const {
        return count > 0 ? sum / count : 0.0;
    }
};
```

But what about variance? This is where things get interesting.

### Welford's Online Algorithm

In 1962, B.P. Welford published an elegant algorithm for computing variance in a single pass. His insight was to track the mean and sum of squared differences incrementally:

```cpp
class WelfordVariance {
private:
    size_t count = 0;
    double mean = 0.0;
    double M2 = 0.0;  // Sum of squared differences from mean

public:
    void update(double value) {
        ++count;
        double delta = value - mean;
        mean += delta / count;
        double delta2 = value - mean;
        M2 += delta * delta2;
    }

    double variance() const {
        return count > 1 ? M2 / (count - 1) : 0.0;
    }

    double stddev() const {
        return std::sqrt(variance());
    }
};
```

The beauty of Welford's algorithm is its numerical stability. Unlike the naive approach of computing Σ(x²) - (Σx)²/n, it avoids catastrophic cancellation.

### Higher Moments: Skewness and Kurtosis

We can extend Welford's approach to compute higher moments. Here's how I implement the complete set:

```cpp
class StreamingMoments {
private:
    size_t n = 0;
    double M1 = 0.0;  // Mean
    double M2 = 0.0;  // Variance * (n-1)
    double M3 = 0.0;  // For skewness
    double M4 = 0.0;  // For kurtosis

public:
    void update(double x) {
        size_t n1 = n;
        n = n + 1;
        double delta = x - M1;
        double delta_n = delta / n;
        double delta_n2 = delta_n * delta_n;
        double term1 = delta * delta_n * n1;

        M1 += delta_n;
        M4 += term1 * delta_n2 * (n*n - 3*n + 3) + 6 * delta_n2 * M2 - 4 * delta_n * M3;
        M3 += term1 * delta_n * (n - 2) - 3 * delta_n * M2;
        M2 += term1;
    }

    double mean() const { return M1; }
    double variance() const { return n > 1 ? M2 / (n - 1) : 0.0; }
    double skewness() const {
        if (n < 3) return 0.0;
        return sqrt(double(n)) * M3 / pow(M2, 1.5);
    }
    double kurtosis() const {
        if (n < 4) return 0.0;
        return double(n) * M4 / (M2 * M2) - 3.0;
    }
};
```

> **Compiler Note**: These algorithms work well with all modern C++ compilers. For maximum performance, enable vectorization with `-O3 -march=native` on GCC/Clang or `/O2 /arch:AVX2` on MSVC.

## Quantiles: The Art of Approximation

Computing exact quantiles in a streaming context is impossible without storing all values. However, several brilliant approximation algorithms exist.

### The P² Algorithm

One of my favorites is the P² (Piecewise-Parabolic) algorithm by Jain and Chlamtac. It maintains five markers that track specific quantiles:

```cpp
class P2Quantile {
private:
    static constexpr int MARKERS = 5;
    double q[MARKERS];      // Marker positions
    double n[MARKERS];      // Ideal positions
    double np[MARKERS];     // Desired positions
    double dn[MARKERS];     // Increments
    int count = 0;
    double p;               // Quantile to track (0-1)

public:
    P2Quantile(double quantile) : p(quantile) {
        // Initialize markers
        dn[0] = 0.0; dn[1] = p/2.0; dn[2] = p; dn[3] = (1+p)/2.0; dn[4] = 1.0;
        for (int i = 0; i < MARKERS; ++i) {
            n[i] = i;
            np[i] = 1.0 + 2.0 * p * i;
        }
    }

    void update(double x) {
        if (count < MARKERS) {
            q[count] = x;
            if (count == MARKERS - 1) {
                std::sort(q, q + MARKERS);
            }
            count++;
            return;
        }

        // Update markers...
        // [Implementation details omitted for brevity]
    }

    double quantile() const {
        return count >= MARKERS ? q[2] : 0.0;
    }
};
```

For a complete implementation, see [this excellent paper](https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf).

### T-Digest: The Industry Standard

In production systems, I often use T-Digest, developed by Ted Dunning. It's particularly effective for extreme quantiles:

| Algorithm | Memory | Accuracy | Best For |
|-----------|--------|----------|----------|
| P² | O(1) | ±1% | Single quantile |
| T-Digest | O(compression) | ±0.01% | Extreme quantiles |
| GK-Summary | O(1/ε log(εN)) | ε-approximate | Multiple quantiles |

T-Digest is available as a [C++ library](https://github.com/tdunning/t-digest) and handles the full quantile range efficiently.

## Interquartile Range and Outlier Detection

The interquartile range (IQR) is the difference between the 75th and 25th percentiles. It's robust to outliers, unlike standard deviation. Here's how I implement streaming IQR:

```cpp
class StreamingIQR {
private:
    P2Quantile q25{0.25};
    P2Quantile q75{0.75};

public:
    void update(double x) {
        q25.update(x);
        q75.update(x);
    }

    double iqr() const {
        return q75.quantile() - q25.quantile();
    }

    bool is_outlier(double x) const {
        double iqr_val = iqr();
        double lower = q25.quantile() - 1.5 * iqr_val;
        double upper = q75.quantile() + 1.5 * iqr_val;
        return x < lower || x > upper;
    }
};
```

## Probabilistic Data Structures

When dealing with categorical data or unique counts, probabilistic data structures shine. Let me share some of my go-to tools.

### Bloom Filters

Bloom filters test set membership with zero false negatives but possible false positives. They're perfect for duplicate detection in streams:

```cpp
template<size_t BITS>
class BloomFilter {
private:
    std::bitset<BITS> bits;
    static constexpr int K = 3;  // Number of hash functions

    size_t hash_i(const std::string& item, int i) const {
        // Simple hash combination
        return (std::hash<std::string>{}(item) + i * 0x9e3779b9) % BITS;
    }

public:
    void insert(const std::string& item) {
        for (int i = 0; i < K; ++i) {
            bits.set(hash_i(item, i));
        }
    }

    bool possibly_contains(const std::string& item) const {
        for (int i = 0; i < K; ++i) {
            if (!bits.test(hash_i(item, i))) {
                return false;
            }
        }
        return true;
    }
};
```

> **Industry Example**: At a game development studio I consulted for, we used Bloom filters to track unique player IDs in real-time analytics, reducing memory usage by 90%.

### Count-Min Sketch

For frequency estimation, Count-Min Sketch is invaluable:

```cpp
class CountMinSketch {
private:
    std::vector<std::vector<uint32_t>> counts;
    size_t width;
    size_t depth;

public:
    CountMinSketch(size_t w, size_t d) : width(w), depth(d) {
        counts.resize(depth, std::vector<uint32_t>(width, 0));
    }

    void update(const std::string& item, int32_t delta = 1) {
        for (size_t i = 0; i < depth; ++i) {
            size_t h = hash_function(item, i) % width;
            counts[i][h] += delta;
        }
    }

    uint32_t estimate(const std::string& item) const {
        uint32_t min_count = UINT32_MAX;
        for (size_t i = 0; i < depth; ++i) {
            size_t h = hash_function(item, i) % width;
            min_count = std::min(min_count, counts[i][h]);
        }
        return min_count;
    }
};
```

For more details, check out the [original paper](http://dimacs.rutgers.edu/~graham/pubs/papers/cmencyc.pdf).

### Top-K Heavy Hitters

Combining Count-Min Sketch with a min-heap gives us efficient top-K tracking:

```cpp
class TopKTracker {
private:
    CountMinSketch cms;
    std::priority_queue<
        std::pair<uint32_t, std::string>,
        std::vector<std::pair<uint32_t, std::string>>,
        std::greater<>
    > min_heap;
    size_t k;
    std::unordered_map<std::string, uint32_t> heap_counts;

public:
    TopKTracker(size_t k_items, size_t width, size_t depth)
        : cms(width, depth), k(k_items) {}

    void update(const std::string& item) {
        cms.update(item);
        uint32_t count = cms.estimate(item);

        if (heap_counts.count(item)) {
            // Item already in heap, update count
            heap_counts[item] = count;
        } else if (min_heap.size() < k) {
            // Heap not full, add item
            min_heap.push({count, item});
            heap_counts[item] = count;
        } else if (count > min_heap.top().first) {
            // New item exceeds minimum
            heap_counts.erase(min_heap.top().second);
            min_heap.pop();
            min_heap.push({count, item});
            heap_counts[item] = count;
        }
    }
};
```

## Gaussian Noise and Robustness

Real-world data is noisy. Here are techniques I use to handle Gaussian noise:

| Technique | Use Case | Pros | Cons |
|-----------|----------|------|------|
| Median Absolute Deviation | Scale estimation | Robust to outliers | Requires quantile estimation |
| Huber M-estimator | Location estimation | Balances efficiency and robustness | More complex implementation |
| Hampel identifier | Outlier detection | Multiple robustness levels | Computationally intensive |

Here's a streaming MAD implementation:

```cpp
class StreamingMAD {
private:
    P2Quantile median{0.5};
    P2Quantile mad_median{0.5};
    std::deque<double> deviation_buffer;
    static constexpr size_t BUFFER_SIZE = 1000;

public:
    void update(double x) {
        median.update(x);

        if (deviation_buffer.size() >= BUFFER_SIZE) {
            deviation_buffer.pop_front();
        }

        double dev = std::abs(x - median.quantile());
        deviation_buffer.push_back(dev);

        for (double d : deviation_buffer) {
            mad_median.update(d);
        }
    }

    double mad() const {
        return 1.4826 * mad_median.quantile();  // Scale to match standard deviation
    }
};
```

## Real-World Applications

Let me share some experiences from different domains:

### Finance: Tick Data Analysis

High-frequency trading processes millions of price updates daily. Here's a pattern I like:

```cpp
struct TickAnalyzer {
    WelfordVariance price_variance;
    StreamingIQR spread_iqr;
    TopKTracker volume_leaders{10, 10000, 5};

    void process_tick(const Tick& tick) {
        price_variance.update(tick.price);
        spread_iqr.update(tick.ask - tick.bid);
        volume_leaders.update(tick.symbol + ":" + std::to_string(tick.volume));

        if (spread_iqr.is_outlier(tick.ask - tick.bid)) {
            // Flag unusual spread for investigation
        }
    }
};
```

### Systems: Performance Monitoring

For monitoring service latencies, I combine multiple techniques:

```cpp
class LatencyMonitor {
    StreamingMoments moments;
    P2Quantile p50{0.50}, p95{0.95}, p99{0.99};
    CountMinSketch error_counter{1000, 5};

public:
    void record_request(double latency_ms, const std::string& endpoint) {
        moments.update(latency_ms);
        p50.update(latency_ms);
        p95.update(latency_ms);
        p99.update(latency_ms);

        if (latency_ms > 100.0) {  // Threshold breach
            error_counter.update(endpoint);
        }
    }
};
```

> **Performance Tip**: When implementing these algorithms in production, use SIMD instructions where possible. Modern CPUs can vectorize many of these operations. On x86-64, AVX2 instructions can provide 2-4x speedups for batch updates.

## A Complete C++23 Library

Let's put it all together in a modern C++23 library:

```cpp
#include <concepts>
#include <ranges>
#include <span>
#include <mdspan>

namespace streaming_stats {

template<std::floating_point T>
class Statistics {
private:
    struct Impl;
    std::unique_ptr<Impl> pImpl;

public:
    Statistics();
    ~Statistics();

    // Single value update
    void update(T value);

    // Batch update using C++23 features
    void update(std::span<const T> values) {
        for (auto v : values) {
            update(v);
        }
    }

    // Range update
    template<std::ranges::input_range R>
    requires std::same_as<std::ranges::range_value_t<R>, T>
    void update(R&& range) {
        for (auto v : range) {
            update(v);
        }
    }

    // Getters
    [[nodiscard]] T mean() const noexcept;
    [[nodiscard]] T variance() const noexcept;
    [[nodiscard]] T stddev() const noexcept;
    [[nodiscard]] T skewness() const noexcept;
    [[nodiscard]] T kurtosis() const noexcept;

    // Quantiles
    [[nodiscard]] T median() const noexcept;
    [[nodiscard]] T quantile(double p) const;
    [[nodiscard]] T iqr() const noexcept;

    // Utilities
    [[nodiscard]] size_t count() const noexcept;
    void reset() noexcept;
};

// Implementation of pImpl idiom for ABI stability
template<std::floating_point T>
struct Statistics<T>::Impl {
    StreamingMoments moments;
    P2Quantile median{0.5};
    P2Quantile q25{0.25};
    P2Quantile q75{0.75};
    std::unordered_map<double, P2Quantile> quantile_cache;

    T get_quantile(double p) {
        if (auto it = quantile_cache.find(p); it != quantile_cache.end()) {
            return it->second.quantile();
        }

        // For dynamic quantiles, we'd need a more sophisticated approach
        // This is a simplified version
        if (p == 0.5) return median.quantile();
        if (p == 0.25) return q25.quantile();
        if (p == 0.75) return q75.quantile();

        // Create new tracker for this quantile
        quantile_cache.emplace(p, P2Quantile{p});
        return T{0};  // Will be accurate after more updates
    }
};

// Concepts for constraining template parameters
template<typename T>
concept StreamableNumeric = requires(T t) {
    { t + t } -> std::convertible_to<T>;
    { t - t } -> std::convertible_to<T>;
    { t * t } -> std::convertible_to<T>;
    { t / t } -> std::convertible_to<T>;
};

// Parallel processing support using C++23 execution policies
template<StreamableNumeric T>
class ParallelStatistics {
private:
    static constexpr size_t NUM_SHARDS = 16;
    std::array<Statistics<T>, NUM_SHARDS> shards;
    std::atomic<size_t> next_shard{0};

public:
    void update(std::span<const T> values, std::execution::parallel_unsequenced_policy) {
        std::for_each(std::execution::par_unseq, values.begin(), values.end(),
            [this](T value) {
                size_t shard =
                    next_shard.fetch_add(1, std::memory_order_relaxed) % NUM_SHARDS;
                shards[shard].update(value);
            });
    }

    // Merge results from all shards
    [[nodiscard]] T mean() const {
        // Implementation would merge partial results
        // This is a simplified placeholder
        T total_mean = 0;
        size_t total_count = 0;
        for (const auto& shard : shards) {
            total_mean += shard.mean() * shard.count();
            total_count += shard.count();
        }
        return total_count > 0 ? total_mean / total_count : T{0};
    }
};

// C++23 mdspan support for multi-dimensional data
template<std::floating_point T>
void process_matrix(std::mdspan<T, std::dextents<size_t, 2>> data) {
    std::vector<Statistics<T>> row_stats(data.extent(0));
    std::vector<Statistics<T>> col_stats(data.extent(1));

    for (size_t i = 0; i < data.extent(0); ++i) {
        for (size_t j = 0; j < data.extent(1); ++j) {
            row_stats[i].update(data[i, j]);
            col_stats[j].update(data[i, j]);
        }
    }
}

} // namespace streaming_stats
```

## Performance Considerations

Through extensive benchmarking, I've learned several optimization tricks:

1. **Cache Alignment**: Align your data structures to cache line boundaries (typically 64 bytes):

```cpp
struct alignas(64) CacheAlignedStats {
    double sum;
    size_t count;
    // ... other members
};
```

2. **Branch Prediction**: Minimize branches in hot paths. Use conditional moves where possible:

```cpp
// Instead of:
if (value > max) max = value;

// Consider:
max = std::max(max, value);  // Often compiles to cmov instruction
```

3. **SIMD Vectorization**: Modern compilers can auto-vectorize, but sometimes manual intervention helps:

```cpp
void update_batch(const float* values, size_t n) {
    // Process 8 values at a time with AVX
    for (size_t i = 0; i < n; i += 8) {
        __m256 v = _mm256_loadu_ps(&values[i]);
        // Process vector...
    }

    // Handle remainder
    for (size_t i = (n / 8) * 8; i < n; ++i) {
        update(values[i]);
    }
}
```

> **Portability Note**: When using SIMD intrinsics, always provide fallback implementations and use feature detection:

```cpp
#ifdef __AVX2__
    // AVX2 implementation
#elif defined(__SSE4_2__)
    // SSE implementation
#else
    // Scalar fallback
#endif
```

## Conclusion

Streaming statistics are essential for modern high-performance computing. They enable us to process infinite data streams with bounded memory, provide real-time insights, and scale to massive datasets.

The algorithms I've shared here form the foundation of many production systems I've worked on. Whether you're building financial analytics, game telemetry, or IoT monitoring, these techniques will serve you well.

Remember: the key to robust streaming statistics is choosing the right algorithm for your use case. Start simple with Welford's algorithm for basic moments, add quantile estimation when needed, and reach for probabilistic data structures when dealing with high-cardinality data.

Want to dive deeper? Here are some resources I regularly reference:

- [The Art of Computer Programming, Vol. 2](https://www.amazon.com/dp/0201896842) - Knuth's seminal work on numerical algorithms
- [Sketching Algorithms for Big Data](https://www.sketchingbigdata.org/) - Comprehensive course on streaming algorithms
- [DataSketches Library](https://datasketches.apache.org/) - Production-ready implementations
- [Moment-Based Statistics](https://en.wikipedia.org/wiki/Moment_(mathematics)) - Mathematical foundations

Happy streaming! Feel free to reach out with questions or share your own experiences with these algorithms.

---

*What streaming statistics challenges have you faced? Leave a comment below or connect with me on [Twitter](https://twitter.com) to continue the discussion.*
