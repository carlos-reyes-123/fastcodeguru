+++
draft       = false
featured    = false
title       = "C++ Prime Number Generator"
slug        = "c++-prime-number-generator"
description = "Classic and modern prime number generators for C++."
ogImage     = "./c++-prime-number-generator.png"
pubDatetime = 2025-05-20T16:00:00Z
author      = "Carlos Reyes"
tags        = [
    "C++23",
    "Prime Number Generation",
    "Coroutines",
    "std::generator",
    "Range Views",
    "Trial Division",
    "Wheel Factorization",
    "SIMD Optimization",
    "Auto Vectorization",
    "Lazy Evaluation",
    "Input Range",
    "Template Programming",
    "Square Root Optimization",
    "Standard Library Only",
    "Systems Programming",
    "Numerical Algorithms",
    "Infinite Sequences",
    "Performance Techniques",
    "Code Simplicity",
    "Deep Dive",
]
+++

![C++ Prime Generator](./c++-prime-number-generator.png "C++ Prime Generator")

## Table of Contents

---

## Introduction

Let's take a look at two prime number generators for C++. One is a classic implementation and the other is a much more modern take in C++23. They are very different from each other.

## Simple Prime Number Generator

This small C++ program demonstrates a straightforward, efficient way to test for primality and then uses that test to print all primes in the range 100 000 … 101 000. Under the hood, it combines a few simple observations to cut down the amount of work to roughly one-third of a naïve trial‐division approach.

---

### 1. A Generic `is_prime` Function

```cpp
template<class Integral>
bool is_prime(const Integral& number)
{
  if (number <= 1)   return false;      // 0 and 1 are not prime
  if (number <= 3)   return true;       // 2 and 3 are prime

  if (number % 2 == 0)  return false;   // eliminate evens
  if (number % 3 == 0)  return false;   // eliminate multiples of 3

  // Only test factors of the form 6k ± 1 up to √number
  for (Integral factor = 6, limit = std::sqrt(number); factor <= limit; factor += 6)
  {
    if (number % (factor - 1) == 0)     return false;
    if (number % (factor + 1) == 0)     return false;
  }

  return true;
}
```

1. **Edge cases**

   * Numbers ≤ 1 are not prime.
   * 2 and 3 are handled as special “small primes.”

2. **Even and multiple-of-3 quick checks**

   * Testing `number % 2` and `number % 3` catches half of the composites right away.

3. **The 6k ± 1 wheel optimization**

   * All primes greater than 3 lie at distance 1 from a multiple of 6 (i.e. they are of the form 6k ± 1).
   * We loop a single variable `factor = 6, 12, 18, …` up to √n, and at each step only test `factor – 1` and `factor + 1`.
   * Computing `limit = std::sqrt(number)` once per call keeps us from recomputing the square root on every iteration.

Overall, this yields an O(√n) test but does only two divisibility checks per six integers, cutting the constant factor by roughly three compared to testing every odd number.

---

### 2. Generating Primes in a Range

```cpp
int main()
{
  for (int n = 100'000; n <= 101'000; ++n)
    if (is_prime(n))
      std::cout << n << "\n";
}
```

* **Digit separators**
  C++14’s single‐quote digit separator (`100'000`) makes large literals more readable.
* **Output**
  When run, this prints all primes between 100 000 and 101 000 inclusive. The commented block at the end of the file lists the exact results for verification.

---

### 3. Why This Approach?

* **Simplicity:** Relies only on `<cmath>` and `%`, no external libraries.
* **Speed:** Eliminates obvious multiples (2 and 3), then uses the 6k ± 1 pattern to minimize checks.
* **Generality:** Templated on any integral type—`int`, `long`, even user‐defined big‐integer types with `%` and `sqrt` support.

This pattern is a classic “wheel factorization” for small‐to‐medium inputs. For very large numbers or cryptographic uses, one would switch to probabilistic tests (e.g., Miller–Rabin) or specialized libraries. But for everyday use—finding all primes up to a few million—this is efficient, easy to read, and widely portable across compilers.

## C++23 Infinite Prime Generator

### 1. Using C++23 Coroutines and Ranges

We implement a coroutine that **lazily yields** each prime number. In C++23, the new `std::generator<T>` (in `<generator>`) lets us write a function with `co_yield` to produce a sequence of values on demand. Importantly, `std::generator` models a *range view* (and specifically an `input_range`), so the returned object can be used in range-based for loops or piped into range adaptors. For example, one can write a Fibonacci generator and then do `fibonacci() | std::views::drop(6) | std::views::take(3)` to slice it. We apply the same idea to primes: our function `primes(start)` returns `std::generator<unsigned long long>` and uses `co_yield` to emit each prime ≥ *start*.

---

### 2. Trial Division Algorithm

A straightforward method is to keep a list of found primes and test each new candidate by division. Concretely:

* If `start <= 2`, yield 2 immediately. Then set `start = 3` (to proceed with odd numbers).
* If `start` is even, increment it by 1 to make it odd.
* Maintain a `std::vector<uint64_t>` of known primes (initially `{2}`).
* For each odd `candidate` from `start` upward (incrementing by 2):

  * Compute `limit = sqrt(candidate)`.
  * Check divisibility: for each prime `p` in the list, stop if `p > limit`; if `candidate % p == 0`, mark as composite and break.
  * If no divisor is found, the candidate is prime: append it to the list and `co_yield` it.

This loop runs “forever,” but each `co_yield` suspends the coroutine and returns one prime at a time. Because `std::generator` is an *input range*, it integrates seamlessly with range-based loops and views.  Note that trial-division is easy to implement but has higher asymptotic cost than the classic sieve: generating primes up to *n* this way is roughly $O(n\sqrt n/\log n)$, whereas the Sieve of Eratosthenes is $O(n\log\log n)$. For truly large ranges, one could switch to a segmented sieve (not shown) for better scalability, but even the simple method below is efficient for moderately large sequences.

---

### 3. SIMD-Friendly Structure

We write tight loops over contiguous data with few branches, enabling auto-vectorization. For instance, the inner loop reads the `prime_list` sequentially and does only a comparison and a modulo. The code skips even numbers (increment by 2) so there is minimal branching. Modern compilers’ auto-vectorizer will use SIMD registers when possible. (In general, replacing division-based checks with a segmented boolean sieve would further increase vectorizability, since marking a flag array is very linear.) In summary, our code avoids complicated control flow and uses simple arithmetic in loops, which helps CPUs exploit SIMD.

```cpp
#include <generator>    // std::generator coroutine (C++23)
#include <vector>
#include <cmath>
#include <cstdint>
#include <ranges>
#include <iostream>

// Coroutine that generates primes >= start.
template<std::integral T = std::uint64_t>
std::generator<T> primes(T start = 2) {
    if (start <= 2) {
        co_yield 2;          // yield the first prime
        start = 3;
    }
    if (start % 2 == 0) ++start; // ensure start is odd

    // Build initial list of primes up to sqrt(start) for testing.
    std::vector<T> prime_list = {2};
    T initial_limit = static_cast<T>(std::sqrt(start));
    for (T n = 3; n <= initial_limit; n += 2) {
        bool is_prime = true;
        T r = static_cast<T>(std::sqrt(n));
        for (T p : prime_list) {
            if (p > r) break;
            if (n % p == 0) { is_prime = false; break; }
        }
        if (is_prime) prime_list.push_back(n);
    }

    // Generate primes starting from 'start'
    for (T candidate = start; ; candidate += 2) {
        bool is_prime = true;
        T limit = static_cast<T>(std::sqrt(candidate));
        for (T p : prime_list) {
            if (p > limit) break;
            if (candidate % p == 0) { is_prime = false; break; }
        }
        if (is_prime) {
            prime_list.push_back(candidate);
            co_yield candidate;  // suspend and yield the prime
        }
    }
}
```

---

### 4. Explanation

The function `primes<T>(start)` returns a `std::generator<T>`, which is a coroutine-based range. Inside, we first handle small cases (yield 2 if needed). We then ensure `start` is odd. We pre-generate all primes up to `sqrt(start)` so that the first candidate can be checked correctly. After that, we loop over odd candidates forever. Each time we find a new prime, we `co_yield` it and also append it to the `prime_list` for future checks. The `while(true)`-style loop with `co_yield` is safe: each `co_yield` suspends the coroutine, so an “infinite loop” does not block the program.

Because `std::generator` is a ranges view, one can write code like:

```cpp
auto first10 = primes() | std::views::take(10); // primes ≥ 2
for (auto p : first10) {
    std::cout << p << ' ';
}
```

This prints the first 10 primes (`2 3 5 7 11 13 17 19 23 29`). Similarly:

```cpp
for (auto p : primes(50) | std::views::take(5)) // primes ≥ 50
    std::cout << p << ' ';
```

This might print `53 59 61 67 71`. Here the generator skips composites and only yields primes, and the `take(5)` stops after 5 values.

---

### 5. Efficiency

This code is single-threaded and fairly efficient. The main loop does only essential work: computing a square root and doing integer mods for each prime ≤ √candidate. The complexity is manageable for many applications, but one should note (as sources confirm) that trial-division is asymptotically slower than the true sieve. For huge upper limits, a segmented sieve using a boolean buffer (striding by primes) would be preferable. However, our implementation shows how to use **modern C++23 features** (ranges, coroutines, concepts) idiomatically in a prime generator. The loops are simple and contiguous, encouraging compilers to auto-vectorize them for SIMD hardware when possible. All components are from the C++ standard library, making the code fully standard-compliant and easy to integrate into range pipelines.

---

### 6. References

The C++23 coroutine generator is documented as a range view (`std::generator` models `input_range`). Microsoft’s C++ blog gives examples of using `std::generator` with range adaptors like `drop` and `take` on infinite sequences. Algorithmic references note that trial division has higher complexity than the sieve of Eratosthenes, and compiler docs explain that simple loop structures can be auto-vectorized for SIMD. Our code reflects these principles to provide a clean, composable prime number sequence generator in modern C++23.
