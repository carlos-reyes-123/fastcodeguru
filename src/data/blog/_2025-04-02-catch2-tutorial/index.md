+++
draft       = false
featured    = false
title       = "Unit Testing at Speed with Catch2"
slug        = "unit-testing-speed-catch2"
description = "A Practical Guide to Catch2 v3 for Modern C++ Projects."
ogImage     = "./catch2-tutorial.png"
author      = "Carlos Reyes"
pubDatetime = 2025-04-02T16:00:00Z
tags        = [
    "benchmarking",
    "C++",
    "catch2",
    "testing",
]
+++

> Unit tests are the double-entry bookkeeping of software engineering: they cost something, but you discover errors while they are still inexpensive.

— Paraphrasing Martin Fowler

Modern C++ development moves quickly. Templates, ranges, coroutines, modules, heterogeneous builds, and automatic CI pipelines mean that your test framework has to keep up without dragging compile times or alienating newcomers. Catch2 v3 is one of the leanest ways to stay in control of quality and performance. In this tutorial we will

* integrate Catch2 v3 with CMake (and FetchContent/CPM);
* write expressive, zero-boilerplate tests, BDD scenarios, and micro-benchmarks;
* squeeze build times and run-time performance;
* avoid five common gotchas that bite C++23 projects; and
* decide when Catch2 is —or is not—the right tool.

Throughout we’ll work against a small header-only math library, but everything applies to large code bases.

---

## Why Catch2 v3?

Catch2 is a header-first test library that grew into a **normal compiled library** offering unit testing, BDD macros, generators, custom matchers, and an opt-in micro-benchmark runner—all in modern C++14-and-later dialects.[^github]

[^github]: [GitHub - catchorg/Catch2: A modern, C++-native, test framework for unit-tests, TDD and BDD - using C++14, C++17 and later (C++11 support is in v2.x branch, and C++03 on the Catch1.x branch)](https://github.com/catchorg/Catch2)

Version 3 moved away from the single-header mantra: you now link against `Catch2::Catch2` (implementation) and optionally `Catch2::Catch2WithMain` (drops in `main()`). This split gives you **faster incremental builds**, cleaner modularisation, and paves the way for future features.[^catch2-rel]

[^catch2-rel]: [Catch2/docs/release-notes.md at devel · catchorg/Catch2 · GitHub](https://github.com/catchorg/Catch2/blob/devel/docs/release-notes.md)

When you need a framework that

* compiles everywhere a freestanding C++14 library does,
* costs almost zero learning curve for new contributors,
* integrates cleanly with CMake/CTest/CTest-CDash,
* provides first-class assertions that look like real C++ expressions, and
* embraces property-based testing, BDD, and benchmarking,

Catch2 is an excellent default. Where it may fall short (we will come back to this) is at the heavy enterprise end where you need mocks, death tests, or fine-grained test fixture control—areas where GoogleTest still shines.

---

## Getting v3: Package, FetchContent or Amalgamation

### Option A: System Package

On most Linux distributions, macOS Homebrew, and vcpkg you can simply:

```bash
brew install catch2      # macOS
sudo pacman -S catch2    # Arch
vcpkg install catch2     # Windows cross-platform
```

This gives you an imported CMake target `Catch2::Catch2` and the helper scripts in `${CMAKE_INSTALL_PREFIX}/lib/cmake/Catch2`.

### Option B: FetchContent (CMake ≥3.14)

```cmake
include(FetchContent)
FetchContent_Declare(
  catch2
  GIT_REPOSITORY https://github.com/catchorg/Catch2.git
  GIT_TAG        v3.8.1 # pin for reproducible builds
)
FetchContent_MakeAvailable(catch2)
```

The above downloads, configures, and adds the same `Catch2::Catch2` and `Catch2::Catch2WithMain` targets, **without polluting your source tree**.

### Option C: Amalgamated Drop-in

If your build system is not CMake, grab `extras/catch_amalgamated.hpp` and `extras/catch_amalgamated.cpp` and slap them next to your sources, then compile the `.cpp` once. This is also convenient for *single-file hacking sessions*.

---

## CMake Integration in Depth

Catch2 ships a set of helper CMake scripts under `extras/`. The most important is **`catch_discover_tests()`**, which introspects your compiled test executable at *configure time* (or just-before-run if you request `DISCOVERY_MODE PRE_TEST`) and registers each `TEST_CASE` with CTest.[^integration]

[^integration]: [Catch2/docs/cmake-integration.md at devel · catchorg/Catch2 · GitHub](https://github.com/catchorg/Catch2/blob/master/docs/cmake-integration.md)

```cmake
enable_testing()
add_executable(example_tests example.cpp)
target_link_libraries(example_tests PRIVATE Catch2::Catch2WithMain)

include(CTest)
include(Catch)                 # <--- adds the function
catch_discover_tests(
  example_tests
  TEST_PREFIX  "Example."      # optional
  DISCOVERY_MODE PRE_TEST      # cross-compilation friendly
  ADD_TAGS_AS_LABELS           # CTest dashboards love this
)
```

### Why `Catch2WithMain`?

*Linking `Catch2::Catch2WithMain`* injects a ready-made `int main(int, char**)` that parses Catch2’s rich CLI. If you need your own startup (e.g., to seed RNGs or parse extra flags), link against `Catch2::Catch2` and `#include <catch2/catch_session.hpp>`:

```cpp
int main( int argc, char* argv[] ) {
    Catch::Session session;
    // parse argv, set config via session.configData()...
    return session.run( argc, argv );
}
```

### Gotcha #1: Object Libraries & Dead Code Stripping

When you split many small test files into an OBJECT library, some linkers drop object files that contain only tests because nothing in the main TU references them. Link with `--whole-archive` (GNU/Clang) or create an *ordinary* static library instead.

---

## Writing Clean Unit Tests

Include only the headers you need. For basic tests:

```cpp
#include <catch2/catch_test_macros.hpp>

uint32_t factorial(uint32_t n) {
    return n <= 1 ? 1 : n * factorial(n - 1);
}

TEST_CASE("Factorials are computed", "[math][factorial]") {
    REQUIRE(factorial(3) == 6);
    REQUIRE(factorial(10) == 3'628'800);
}
```

### Tags and Filtering

* Tags in `[]` are powerful. Run just fast math tests:
  `example_tests "[math][!slow]"`

* Exclude slow tests globally in CI:
  `ctest -L 'NOT slow'`

### Sections for Local Fixtures

```cpp
TEST_CASE("vector operations") {
    std::vector<int> v{1,2,3};

    SECTION("push_back") {
        v.push_back(4);
        REQUIRE(v.size() == 4);
    }
    SECTION("erase") {
        v.erase(v.begin());
        REQUIRE(v == std::vector{2,3});
    }
}
```

Each `SECTION` runs **independently** in its own stack frame, giving you miniature fixtures without class gymnastics.

---

## BDD Style Scenarios

Prefer BDD when you want your test names to read like specifications.

```cpp
#include <catch2/catch_test_macros.hpp>
#include <catch2/catch_message.hpp>

SCENARIO("Bank account transfers") {
    GIVEN("Two accounts with initial balance") {
        Account a{100}, b{50};

        WHEN("money is transferred") {
            a.transfer(b, 40);

            THEN("balances reflect the transfer") {
                REQUIRE(a.balance() == 60);
                REQUIRE(b.balance() == 90);
            }
        }
    }
}
```

`SCENARIO`, `GIVEN`, `WHEN`, `THEN`, and `AND_*` are thin aliases that expand to `TEST_CASE`/`SECTION` while decorating the names.[^catch2-tut] They cost nothing at run-time and make reports easier to scan.

[^catch2-tut]: [Catch2/docs/tutorial.md at devel - GitHub](https://github.com/catchorg/catch2/blob/devel/docs/tutorial.md?utm_source=chatgpt.com)

---

## Micro-Benchmarking

Benchmark blocks are hidden behind the `[!benchmark]` tag so production test suites do not waste cycles.[^github]

```cpp
#include <catch2/benchmark/catch_benchmark.hpp>

BENCHMARK("Fibonacci 30") {
    return fibonacci(30);
};
```

Run only benchmarks:

```bash
example_tests "[!benchmark]"
```

Tips:

* Compile with `-O3 -DNDEBUG` for realistic numbers.
* Benchmarks run for a minimum clock duration (≈ 0.5 s) and report mean, median, and standard deviation.
* Treat Catch2’s micro-benchmarks as *sanity checks*, not as a replacement for `perf`/`VTune`.

---

## Five Common Gotchas

| # | Symptom | Root Cause | Remedy |
|---|---------|------------|--------|
| 1 | *Tests not discovered in CI* | Executable built after CMake configure, but `catch_discover_tests()` ran before. | `DISCOVERY_MODE PRE_TEST` or run `cmake --build . --target tests` before `ctest`. |
| 2 | *Massive compile times* | Using convenience header `catch_all.hpp`. | Include only `<catch2/catch_test_macros.hpp>` or specific headers; keep tests in separate TU. |
| 3 | *Linker errors for `main`* | Both your own `main()` and `Catch2WithMain` linked. | Link **either** `Catch2::Catch2WithMain` **or** write your own, never both. |
| 4 | *CTest dashboards ignore tags* | Older Catch2 helper script. | Upgrade to `catch_discover_tests()` ≥ 3.3.0 or add `ADD_TAGS_AS_LABELS`. ([Catch2/docs/release-notes.md at devel · catchorg/Catch2 · GitHub](https://github.com/catchorg/Catch2/blob/devel/docs/release-notes.md)) |
| 5 | *Assertion expression compiled out* | `REQUIRE_FALSE` on `constexpr` expr with -O3; compiler folds it away before macro sees it. | Wrap value in a lambda or `volatile` to force evaluation; or use `STATIC_REQUIRE` for compile-time checks. |

---

## Missing Features & Limitations

1. **No mocking framework**. If you rely on heavy mocking (death tests, mocks with expectations), pair Catch2 with trompeloeil or FakeIt, or choose GoogleTest.
2. **No XML schema guarantee**. The JUnit output is sufficient for most CI tools but not as stable as GoogleTest’s.
3. **Limited parameterised-test syntax**. Generators help but you cannot write *typed* test suites as elegantly as `TYPED_TEST_SUITE` in GTest.
4. **Compile-time cost on monster headers**. Even after v3’s modularisation, Catch2 macros instantiate a fair amount of template machinery—place tests in separate targets to avoid polluting the library build.
5. **Static-library model complicates pre-C++14 projects**. v3 requires C++14 and later.[^catch2-rel]

---

## Benchmark vs Unit Test: A Workflow

| Phase | Focus | Catch2 feature |
|-------|-------|----------------|
| Tight CI loop (< 2 min) | Logic correctness | `TEST_CASE`, `SECTION`, `STATIC_REQUIRE` |
| Nightly build | Behaviour regressions & API contracts | BDD macros with descriptive names |
| Weekly performance watch | Hot-path timing | `[!benchmark]`, tagged out of default run |
| Profiling deep dive | CPU/GPU counters | Use system profilers; Catch2 only to pin entry points |

---

## When **Not** to Use Catch2

* Your team depends on *strict* JUnit XML features that Catch2 does not emit.
* You need shared fixtures initialised once per entire test run (Catch2 can emulate with listeners but it’s clumsier than GTest’s `::testing::Environment`).
* You require parameterised and typed tests across hundreds of type permutations—GoogleTest’s matrix helpers scale better.
* You must interoperate with an existing codebase already standardised on GTest/GMock to avoid split tooling.

---

## Putting It All Together—A Mini Project

```
example/
├── CMakeLists.txt
├── include/
│   └── math.hpp
└── test/
    └── math_tests.cpp
```

### CMakeLists.txt (root)

```cmake
cmake_minimum_required(VERSION 3.20)
project(example LANGUAGES CXX VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 23)
add_library(math INTERFACE)
target_include_directories(math INTERFACE include)

# ---------- tests ----------
option(BUILD_TESTING "Build unit tests" ON)
if(BUILD_TESTING)
    enable_testing()
    include(FetchContent)
    FetchContent_Declare(catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG        v3.8.1)
    FetchContent_MakeAvailable(catch2)

    add_executable(math_tests test/math_tests.cpp)
    target_link_libraries(math_tests PRIVATE math Catch2::Catch2WithMain)

    include(Catch)
    catch_discover_tests(
        math_tests
        TEST_PREFIX   "Math."
        DISCOVERY_MODE PRE_TEST
    )
endif()
```

### math_tests.cpp

```cpp
#include <catch2/catch_test_macros.hpp>
#include <catch2/benchmark/catch_benchmark.hpp>
#include "math.hpp"

SCENARIO("absolute value") {
    GIVEN("negative and positive inputs") {
        WHEN("abs() is applied") {
            THEN("result is non-negative") {
                REQUIRE(abs_val(-3) == 3);
                REQUIRE(abs_val(42) == 42);
            }
        }
    }
}

TEST_CASE("sqrt approximation", "[benchmark]") {
    BENCHMARK("sqrt 10 000 doubles") {
        std::vector<double> v(10'000, 3.14);
        for (auto& x : v) x = fast_sqrt(x);
        return v;
    };
}
```

Build & run:

```bash
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build
cd build && ctest --output-on-failure
```

Add `-L benchmark` or `-T Test` in CI as needed.

---

## Verdict

Catch2 v3 hits a unique sweet spot:

* **Small footprint**—single library with optional amalgamation.
* **Expressive syntax**—assertions read like real C++.
* **CMake-native discovery**—works with CTest dashboards and modern CI.
* **Safety nets**—BDD style, generators, property checks, micro-benchmarks.

For teams with performance-critical C++ and no heavy mocking requirements, Catch2 v3 is hard to beat. When you grow into cross-platform pipelines, split your tests into sharded targets, tag everything religiously, and let `catch_discover_tests()` glue it all together. And when your profiler cries, drop in a `[!benchmark]` block before reaching for heavier artillery.

Happy (fast) coding!
