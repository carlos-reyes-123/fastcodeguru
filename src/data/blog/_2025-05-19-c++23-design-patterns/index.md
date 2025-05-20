+++
draft       = false
featured    = false
title       = "Modern C++23 Design Patterns for High-Performance Code"
slug        = "c++23-design-patterns"
description = "In high-performance C++, design patterns are not just academic exercises – they’re essential tools."
ogImage     = "./c++23-design-patterns.png"
pubDatetime = 2025-05-19T16:00:00Z
author      = "Carlos Reyes"
tags        = [
    "C++23 Design Patterns",
    "Ranges Library",
    "Coroutines and Generators",
    "Scope Guards",
    "Compile-Time Evaluation",
    "Thread Synchronization",
    "Fluent Builder Pattern",
    "Monostate Pattern",
    "Observer Pattern",
    "Concepts and Constraints",
    "Lazy Evaluation",
    "Type Erasure",
    "Pipeline Processing",
    "Static Strategy Pattern",
    "Deducing This",
    "Concurrency Primitives",
    "Functional Style C++",
    "Declarative Programming",
    "Game Engine Design",
    "Systems Programming",
]
+++

![Modern C++23 Design Patterns](./c++23-design-patterns.png "Modern C++23 Design Patterns")

## Table of Contents

---

## Introduction

In high-performance C++, design patterns are not just academic exercises – they’re essential tools.  They structure complex systems, improve maintainability, and document intent.  But modern C++ (C++20/23) has so many new features that many classic patterns can be reimagined.  For example, as Rainer Grimm observes, *“thanks to the ranges library in C++20, the Pipes-and-Filters Pattern is directly supported in C++.”*.  In this article I’ll walk through eight patterns – from pipelines to observers – and show how C++23 features let us write them more succinctly and safely, with real-world examples.  I’ll cover the problem each pattern solves, highlight the C++23 features that help, show annotated code, discuss portability and compiler support, and share use-cases from industries like games, finance, and systems.  I’ll also note when you might combine these ideas. Let’s dive in.

## Range-Based Pipeline (Pipes-and-Filters)

**Problem:**  In data-intensive code we often want to process a sequence through multiple stages – e.g. filtering, transforming, aggregating – without writing low-level loops.  In older C++ we’d either write nested loops or use libraries like Boost.Range to chain algorithms.  That code was often verbose and error-prone (bounds checks, intermediate containers).

**Modern C++ Solution:**  The `<ranges>` library (introduced in C++20, with enhancements in C++23) lets us build **lazy pipelines** by chaining *views* with the pipe (`|`) operator.  This directly implements the *Pipes-and-Filters* pattern: each stage is a filter or transformer that takes a range and returns a new range, all composed naturally.  For example, the code below generates the first 10 prime numbers after 1000 by pipelining iota, filter, and take views:

```cpp
#include <ranges>
#include <vector>
// (Assume isPrime(int) is defined)
int main() {
    // 1) Start from 1000
    // 2) Keep odd numbers only
    // 3) Keep primes only
    // 4) Take first 10 of those
    // 5) Collect into std::vector (std::ranges::to is C++23)
    auto primes = std::views::iota(1000)
                | std::views::filter([](int n){ return n % 2 != 0; })
                | std::views::filter(isPrime)
                | std::views::take(10)
                | std::ranges::to<std::vector>();  // (C++23)
    // primes now contains the 10 primes ≥1000
}
```

Here we use `std::views::iota`, `filter`, `take`, and finally `std::ranges::to` (a C++23 convenience) to funnel data through a pipeline.  Each `|` stage is *lazy*: no work is done until we iterate or call `to`, so no temporary containers are created.

> *"The ranges-based implementation has several advantages over the loop-based one: the size of the window is easily changed... the original code would have needed bounds checking... the ranges code does that automatically..."*.  In fact, as shown by Nicolai Greitemann, a range-based “sliding window” function can avoid manual bounds checks and even be returned as a lazy range for further processing.  The pipe-and-filter style makes the code more **declarative**: you read left-to-right what happens to each element, rather than juggling indices.

**C++23 Features:**  - The **Ranges library** (`<ranges>`) provides `std::views::` adaptors like `filter`, `transform`, `take`, `drop`, and (new in C++23) `std::views::slide` for sliding windows.  - The pipe operator (`|`) is a C++20 feature that composes range adaptors.  - `std::ranges::to<Container>` (C++23) converts a range into a container (like `std::vector`) without writing an explicit loop.  - We often use C++23 *lambdas* (with `auto` parameters) to define filters inline.

**Annotated Example:**  In the code above, each pipeline stage is marked by a comment:

* **(1)** `std::views::iota(1000)` generates an infinite range \[1000, 1001, 1002, …].
* **(2)** `filter(n%2!=0)` keeps only odd `n`.
* **(3)** `filter(isPrime)` keeps only primes.
* **(4)** `take(10)` takes the first 10 elements.
* **(5)** `to<std::vector>()` materializes the result into a `std::vector<int>` (new in C++23).

**Caveats:**  Pipelines require relatively recent compilers: C++20 ranges are widely supported (gcc 10+, Clang 10+, MSVC 19.28+), but *some* adaptors (like `views::slide`) and `std::ranges::to` need C++23 support (gcc 14+, MSVC 19.36+, Clang head).  If you can’t use C++23 yet, Boost.Range or Range-v3 provides similar functionality.  Also remember: lazy ranges don’t pre-allocate, so if you read the same range twice, work is redone (you’d need to `to` once, or cache results).

**Use Cases:**  Pipelines shine in data processing tasks.  For instance, in **finance** I’ve used range pipelines to filter and transform streaming market data (e.g. “take all trades over \$1000, convert to EUR, then accumulate”).  In **game dev**, one might pipeline entity lists (`views::filter`, `views::transform`) for culling and rendering.  In **systems code**, pipelines simplify tasks like log processing or data mining, because they avoid manual index math.  Pipelines can also be used with infinite streams (e.g. procedural generation).

**Related:**  This is basically the *Pipes-and-Filters* pattern. For more, see Rainer Grimm’s blog on pipelines or Range-v3 documentation.  C++23’s `std::ranges::to` came from WG21 proposal \[P2300], improving ergonomics for pipelines.

## Lazy Generator (Coroutines with `co_yield`)

**Problem:**  Often you want to define a sequence of values on-the-fly (e.g. numbers, events, file lines) without computing them all upfront or storing them in memory.  In older C++ we wrote iterators or used external libraries for generators, which was tedious.

**Modern C++ Solution:**  C++20 introduced **coroutines**, and C++23 adds `std::generator` (in `<generator>`).  A coroutine can `co_yield` values lazily whenever the caller requests them.  This implements the *Generator* pattern (like Python’s generators) natively.  You write a function with `co_yield`, and it automatically becomes an iterable range.  For example, here’s an infinite Fibonacci generator:

```cpp
#include <generator>
#include <ranges>
#include <iostream>

std::generator<int> fib() {
    int a = 0, b = 1;
    while (true) {
        co_yield a;         // (1) yield current value
        int next = a + b;
        a = b;
        b = next;
    }
}

int main() {
    // Print first 10 Fibonacci numbers
    for (int x : fib() | std::views::take(10)) {
        std::cout << x << ' ';  // outputs: 0 1 1 2 3 5 8 13 21 34
    }
}
```

Here **(1)** we `co_yield a` each time through the loop.  The function `fib()` is a coroutine: each `co_yield` suspends it and produces a value. The `std::generator<int>` return type means the coroutine is a range of `int`.  We can then use range adaptors (`take(10)`) and a range-based for-loop to consume it lazily.

> *“`std::generator` in C++23 is the first concrete coroutine. A `std::generator` generates a sequence of elements by repeatedly resuming the coroutine from which it was paused.”*.  In practice, this means you can write *stateful loops* naturally: `fib()` contains its own state `(a,b)`, and calling it yields values on demand.  The caller never has to manage that state manually.

**C++23 Features:**  - **Coroutines** (`co_yield`) and the new `<generator>` header.  - `std::generator<T>` is a C++23 standard library type that wraps a coroutine producing `T` values.  - We can still use ranges with it (`co_yield`+`std::generator` models `std::ranges::input_range`).  - (Also related: `if consteval` we’ll mention later can differentiate code paths inside coroutines if needed.)

**Annotated Example:**  In the code above, line **(1)** shows `co_yield a;`, which suspends the coroutine and returns `a`. When the caller’s loop asks for the next value, execution resumes after the `co_yield`.  This loop never terminates on its own (infinite sequence), but we safely take only 10 values.

**Caveats:**  As of 2025, support for `std::generator` is spotty. Microsoft’s standard library (MSVC 17.13+) implements it, and newer GCC/Clang versions are catching up (see cppreference’s compiler support).  If unavailable, you’d use a library (e.g. [cppcoro](https://lewissbaker.github.io/CppCoro/) or Boost) or write a custom range type.  Also, coroutines can be confusing if you’re not familiar, and debugging can be tricky since the control flow is “split” between caller and coroutine.

**Use Cases:**  Lazy generators are great when dealing with large or infinite sequences.  In **game dev** you might generate procedural content or enemy spawn waves lazily.  In **finance**, maybe process a stream of ticks or market events one by one without buffering them all.  In **systems**, you could lazily read lines from a file or stream events from the OS.  Anywhere you want “on-demand” data, a generator simplifies the code (no manual iterator struct).  For example, the Microsoft blog shows summing a portion of a Fibonacci stream using ranges, illustrating how coroutines fit into pipelines.

**Link:**  See the WG21 proposal \[P2502R2] (via Microsoft) for `std::generator` and Sy Brand’s C++ Team Blog for details.  Compared to writing custom range-iterator classes, `std::generator` requires far less boilerplate and ties directly into `<ranges>`.

## Fluent Builder (with Designated Init and CTAD)

**Problem:**  Some objects (e.g. configuration objects, complex structs) have many parameters.  A constructor with a long parameter list is error-prone and hard to use. The classic *Builder* pattern (method chaining) helps, but often involved verbose code or separate “builder” classes.

**Modern C++ Solution:**  C++20’s **designated initializers** and C++17’s **Class Template Argument Deduction (CTAD)** make builders more concise.  For aggregates (plain `struct`s), you can now write:

```cpp
struct Config {
    std::string host = "localhost";
    int port = 8080;
    bool useTLS = true;
};

// Designated initializer (C++20)
Config cfg { .host="example.com", .port=443 };
// Only override what's needed; order doesn’t matter.
```

This feels like “named parameters” and often obviates a Builder class entirely.  But for non-aggregate classes or fluent interfaces, we can still do a builder with CTAD to infer types.  For example:

```cpp
struct Rectangle {
    int width{0}, height{0};
    std::string color{"white"};
};

// A simple fluent builder using CTAD (C++17) and method chaining
template<typename T>
struct Builder {
    T obj;
    Builder(T init) : obj(init) {}

    auto& setWidth(int w)   { obj.width = w; return *this; }
    auto& setHeight(int h)  { obj.height = h; return *this; }
    auto& setColor(std::string c) { obj.color = std::move(c); return *this; }

    // Allow conversion to T (end of chain)
    operator T() &&        { return obj; }
};

int main() {
    // Deduction guides make this infer Builder<Rectangle>
    auto rect = Builder{Rectangle{}}  // CTAD deduces Builder<Rectangle>
                  .setWidth(100)
                  .setHeight(50)
                  .setColor("red");
    // rect is a Rectangle with the given fields set
}
```

Here we use CTAD so that writing `Builder{Rectangle{}}` deduces the `T=Rectangle`.  The methods return `*this` so calls chain.  We then convert the builder to `Rectangle` via the converting operator.  This “fluent builder” feels very natural, and we didn’t have to spell `Builder<Rectangle>` thanks to CTAD.  In contrast, pre-C++17 one often wrote `Builder<Rectangle> builder(Rectangle{});` or used a static `create()`.

**C++23 Features:**  - **Designated initializers** (C++20) let us do `Config{ .host="x", .port=123 }`, improving readability and avoiding the need for many constructors.  - **CTAD** (C++17) lets `Builder{Type{}}` infer the template.  - We also rely on move semantics (from C++11+) in builder code, but no new C++23 language feature is strictly needed here beyond these.

**Annotated Example:**  In the builder code above, note how CTAD infers the template, and how each `setX(...)` returns `*this` so you can chain calls.  Compared to older code, you no longer need a separate `build()` call if you use the converting operator, and you don’t have to specify template args.

**Caveats:**  Designated initializers only work on **aggregates** (no user constructors).  If your type has invariants to enforce, you might still need a custom builder.  Also, CTAD only works if the constructor signature is unambiguous.  Some older compilers may not fully support designated init (e.g. MSVC < VS2019 16.8 needed updates). But by C++23 all major compilers handle these.

**Use Cases:**  Fluent builders are common for configuration or policy objects.  For instance, in **finance** I might have a `ChartOptions` builder to set colors, styles, etc.  In **game engines**, builders create complex objects (like scene nodes) with many optional parameters.  In **systems code**, builders or designated init make structs like network `Request` or graphics `Vertex` much clearer to initialize.  For small objects, even designated initializers can replace builders entirely.

**Alternate View:**  Sometimes, if your class is just an aggregate of options, you can skip builders and rely on `Type{ .a=x, .b=y }`.  Still, method-chaining builders remain useful when constructing an object involves non-trivial logic or when the type has non-public members.

## Scoped Cleanup (Scope Guards with `<scope>`)

**Problem:** In C++, managing resources (locks, files, memory, etc.) safely is crucial.  We want to ensure cleanup code runs on *every* exit path from a scope (normal exit, return, exceptions). Pre-C++23 idioms included writing custom RAII classes or using hacks (`try/finally`-like macros, or `std::unique_ptr` with deleters).

**Modern C++ Solution:**  C++23 introduced the `<scope>` header (Library Fundamentals TS v3) with **`std::scope_exit`**, **`std::scope_fail`**, and **`std::scope_success`**. These are standardized *scope guards*.  The simplest is `std::scope_exit`, which executes a lambda when its own object is destroyed at scope exit.  For example:

```cpp
#include <scope>   // C++23 header
#include <iostream>
#include <mutex>

void example() {
    std::mutex m;
    m.lock();
    // Create a guard that unlocks 'm' when we leave the block
    auto unlocker = std::scope_exit([&]{ m.unlock(); });

    std::cout << "Critical section\n";
    if (some_error) {
        return;  // even on early return, m.unlock() will run
    }
    // ...
}  // m.unlock() is automatically called here
```

In this snippet, `unlocker` is a local object whose destructor calls the lambda, releasing the mutex. No matter how we leave the scope (normal exit or exception), the guard runs.  This is basically a standard `finally`/`defer` mechanism.

> *`std::scope_exit` is a nice feature to do some cleanup job when control flow will leave a current block. It’s a much easier alternative to creating RAII classes on your own.*.

**C++23 Features:**  - The `<scope>` header and `std::scope_exit` (new in C++23, based on Library Fundamentals TS v3).  - Optionally, `std::scope_fail` (only runs the lambda if leaving by exception) and `std::scope_success` (only on normal exit).  - These are standard now; previously one might use Boost.ScopeGuard or implement a small RAII guard manually.

**Annotated Example:**  In the code above, the comment shows that `unlocker` will call `m.unlock()` on destruction.  We bind the lambda at creation time.  This is often clearer and less error-prone than writing a dedicated RAII class or remembering to unlock in each return branch.

**Caveats:**  Because these are in C++23, you need an up-to-date compiler with the `<scope>` header.  As of 2025, major compilers (GCC 14+, Clang 17+, MSVC 19.x+) implement it. If not available, use `std::unique_ptr` with a custom deleter, or Boost’s `BOOST_SCOPE_EXIT`.  Also, lambdas in scope guards should be `noexcept`-safe, since throwing in a destructor leads to `std::terminate`.  Be mindful of what you capture in the lambda (e.g. avoid capturing objects by reference if they might expire first).

**Use Cases:**  In **systems programming**, `std::scope_exit` is great for releasing locks or file handles.  For example, a database transaction object could use it to `commit()` or `rollback()` at scope end.  In **game dev**, one might use it to reset graphics state or restore rendering targets after a block.  Anywhere you have “clean up on exit” code, scope guards shine.  Nikoli Kutiavin notes it’s perfect *“where exceptions or early returns could otherwise leave resources dangling”* – like unlocking a mutex or closing a file.

**Related:**  This is essentially the *Scope Guard* idiom made standard. It combines well with RAII (zero overhead). Contrast: before C++23, one often wrote constructs like:

```cpp
auto guard = std::unique_ptr<void, std::function<void(void*)>>(nullptr, [&](void*){ m.unlock(); });
```

or a custom struct.  Now it’s one line of standard library.

## Compile-Time Policy Selection (concepts + consteval)

**Problem:**  Sometimes we want flexible behavior (policies) but determined at compile-time for efficiency.  For example, a numeric algorithm might have different strategies (slow-but-general vs fast-special-case).  We want to pick which code path at compile-time based on types or flags.  In the past, we’d use template specialization or tag dispatch or even runtime branching. In prehistoric times, we used `#if` preprocessor conditionals--shudder.

**Modern C++ Solution:**  C++20 concepts allow us to define *policy interfaces* and constrain templates, and C++23’s `if consteval` helps branch at compile-time evaluation.  Essentially, we can write code like:

```cpp
// Define a policy concept (interface requirements)
template<typename P>
concept Policy = requires(P p, int x) {
    { p.process(x) } -> std::convertible_to<int>;
};

// A consteval function (must be evaluated at compile-time if reached)
consteval int compileTimeCompute(int x) {
    return x * x;  // must be compile-time
}

template<Policy P>
constexpr int run(const P& policy, int value) {
    if consteval {
        // In a constexpr context, do extra compile-time work
        return compileTimeCompute(policy.process(value));
    } else {
        // Regular runtime path
        return policy.process(value);
    }
}
```

Here, `Policy` is a **concept** (since C++20) that says what methods a policy type must have.  The function `run()` is `constexpr`; inside it we use C++23’s `if consteval` (from proposal P0592) to choose a branch if the function call is being evaluated at compile-time.  This lets us combine `consteval` functions with normal code: the `compileTimeCompute` is only invoked in a constant-evaluation context (e.g. in a `constexpr` initializer), while the `else` branch runs at runtime.

Conceptually, this is a “compile-time strategy pattern”: we select which code to run based on template parameters and whether we’re in a constant-expression.  The compiler can eliminate branches not taken at compile-time, leading to zero overhead dispatch.  And concepts ensure any `P` we pass meets the requirements.

**C++23 Features:**  - **Concepts** (C++20) let us name and enforce requirements on policies (e.g. `template<Policy P>`).  - **`if consteval`** (C++23) is a new statement that checks *at compile-time* whether the function is being evaluated as a constant expression.  - **`consteval`** (C++20) marks a function to be run only at compile-time.  - Combined, these let us write functions that do different things in compile-time vs runtime contexts seamlessly.

**Annotated Example:**  In `run()` above, note:

* We constrain `P` with `Policy`, so any type passed must have a `.process(int)`.
* `if consteval` (a new C++23 feature) says: *if this function call is being evaluated in a constant expression*, then do the `compileTimeCompute(...)` branch.  Otherwise, do the runtime branch.  This might seem subtle, but it can let the compiler optimize certain cases or enforce checks only in constexpr evaluation.

**Caveats:**  This pattern requires fairly modern compilers. `if consteval` is new as of C++23, so ensure your toolchain supports it.  Also, heavy use of `constexpr` and `consteval` can lead to very long compile times if overused.  And since we often combine templates, compilation errors on unmet concepts can be cryptic.  Finally, `consteval` functions *must* be evaluated at compile-time; misuse will cause hard errors.

**Use Cases:**  Compile-time policy selection appears in template libraries and high-performance code.  For example, in **finance or simulation**, we might have a `Policy` for math operations that is either a generic (slower) or SSE-optimized (faster) path.  We could write something like:

```cpp
struct GenericPolicy { int process(int x) { return x+1; } };
struct FastPolicy    { int process(int x) { /* some fast math */ } };

// At compile time, pick policy and compute a constant:
constexpr int result = run<FastPolicy>(FastPolicy{}, 41);
static_assert(result == 42);
```

This guarantees at compile time we hit the `if consteval` branch.  In **game engines**, one might choose different graphics shading policies (e.g. compile-time flags to enable VR or HDR code) and use `if consteval` in meta-functions to peel off path overhead.

**Related:**  This idea is a form of *static strategy/policy pattern*. C++20’s concepts are basically named constraints – e.g. from cppreference:

```cpp
template<class T, class U>
concept Derived = std::is_base_of_v<U,T>;
template<Derived<Base> T> void f(T);
```

shows how a concept is applied to a template parameter. And the new `if consteval` is a much cleaner way to do what `std::is_constant_evaluated()` did before.

## Monostate Singleton (with Inline Variables)

**Problem:**  The *Singleton* pattern ensures one instance of a class, but it has drawbacks (lazy init, thread-safety, global state).  An alternative is the **Monostate** (Borg) pattern: make all member *data* static, so every instance shares the same state.  This gives the illusion of a singleton but with simpler implementation.

**Modern C++ Solution:**  Use `inline static` members (C++17+) to define a monostate class entirely in a header.  For example, consider a simple phone book:

```cpp
#include <iostream>
#include <string>
#include <unordered_map>

class PhoneBook {
public:
    void addEntry(const std::string& name, int number) {
        teleBook[name] = number;
    }
    void printAll() const {
        for (auto& [n,num] : teleBook)
            std::cout << n << ": " << num << "\n";
    }
private:
    inline static std::unordered_map<std::string,int> teleBook;  // shared by all
};
```

All instances of `PhoneBook` use the same `teleBook` map.  Users of `PhoneBook` don’t even need to know about the static state; they just create objects normally. The key here is `inline static`; since C++17 we can define and initialize static members in-class without a separate `.cpp` definition.  This makes it easy to have header-only monostates.

In effect, every method of `PhoneBook` behaves as if it were a singleton’s method, but we didn’t have to write a private constructor or a `getInstance()`.

> Rainer Grimm notes that *“in the Monostate Pattern, all data members are `static`. Consequentially, all instances of the class use the same data.”*.

**C++23 Features:**  Actually, monostate uses **`inline` variables** (C++17) – so C++23 compilers fully support it.  The novelty in C++23 is minimal here, but `inline static` is the key enabler.  (In pre-C++17, you would define `std::unordered_map<std::string,int> PhoneBook::teleBook;` in a .cpp file; now it’s in-class.)

**Annotated Example:**  In the `PhoneBook` above, `teleBook` is `inline static`.  You can add entries through *any* `PhoneBook` object, and `printAll()` from a different object will see them too, because it’s the same `teleBook`.  For instance:

```cpp
PhoneBook p1, p2;
p1.addEntry("Alice", 42);
p2.addEntry("Bob", 99);
p1.printAll();  // Prints both Alice and Bob
```

**Caveats:**  Monostate effectively creates global state.  Initialization order of `inline static` variables follows the usual rules (static initialization order fiasco can still occur across translation units).  Also, like singletons, it introduces hidden coupling (the code reading `teleBook` depends on it existing).  You must ensure thread-safety manually (multiple threads mutating the static data will need locks, etc.).  Use monostate sparingly for true “global” services.

**Use Cases:**  Monostate is often used for logging, configuration, or other global services.  For example, a `Logger` class could hold an `inline static std::ofstream` or a settings map. In **game dev**, one might have a global `Settings` monostate for graphics options accessible everywhere.  In **finance**, maybe a global `MarketDataCache`.  Monostate is safer than a typical singleton (no explicit `getInstance()` call site), but it’s still “global” state under the hood.  Remember Dijkstra’s warning: global state is error-prone, so use dependency injection where possible; monostate is just one way to minimize boilerplate if you *do* need it.

## Observer Pattern with Type Erasure

**Problem:**  The *Observer* pattern involves objects (observers) registering to be notified by a subject when events occur.  A common implementation stores callbacks.  In old C++ you might define an abstract Observer interface and require derived classes.  This is inflexible (only one method signature) and causes coupling.

**Modern C++ Solution:**  Use **type erasure** with `std::function` (or similar) to store arbitrary callables as observers.  C++23’s improvements to lambdas (deducing `this`) also help in writing observer callbacks elegantly.  For example:

```cpp
#include <functional>
#include <vector>
#include <iostream>

class Button {
    std::vector<std::function<void(int)>> observers;
public:
    void subscribe(std::function<void(int)> obs) {
        observers.push_back(std::move(obs));
    }
    void click(int x) {
        for (auto& o : observers) o(x);
    }
};

// Some listener class
class Listener {
public:
    void onClick(int x) {
        std::cout << "Got click with value " << x << "\n";
    }
};

int main() {
    Button button;
    Listener lst;

    // Subscribe using a lambda that calls the member function
    button.subscribe([&lst](int val) { lst.onClick(val); });

    button.click(7);  // prints "Got click with value 7"
}
```

Here `Button`’s `subscribe` takes a `std::function<void(int)>`, which can wrap anything callable with that signature.  We pass a lambda capturing `&lst`; it forwards to `lst.onClick(val)`.  This is *type-erased*: the `Button` doesn’t care if the observer is a lambda, free function, function object, or bound method.

In C++23 we can even use **deducing `this`** in lambdas for interesting patterns.  For instance, a self-referential or recursive callback can name its own closure object.  As Sy Brand’s blog shows, you could write:

```cpp
auto recursiveObserver = [&](this auto& self, int val) {
    if (val > 0) {
        std::cout << "Val = " << val << "\n";
        self(val-1);  // call itself (enabled by deducing-this)
    }
};
button.subscribe(recursiveObserver);
button.click(3);
// Output:
// Val = 3
// Val = 2
// Val = 1
```

Here `(this auto& self)` (C++23 syntax) gives the lambda a name `self` for its own closure, enabling it to recurse.  This is a neat trick when observers need to re-subscribe or process in steps.

**C++23 Features:**  - **`std::function`** (C++11, but widely used) for type-erased callbacks.  - **Deducing `this`** (C++23, P0847R6) allows lambdas and member functions to treat the object as an explicit parameter.  In lambdas, writing `(this auto& self)` lets you refer to the closure as `self`.  This isn’t needed for basic observer use, but is useful in advanced cases (recursive lambda handlers, perfect-forwarding callbacks, etc.).

**Annotated Example:**  In the above code, `subscribe` uses `std::function<void(int)>`.  We attach a lambda `[&lst](int val){ lst.onClick(val); }`.  If we wanted a member function more directly, C++23 lets you even do:

```cpp
button.subscribe([&lst](auto&& self, int val) {
    // Using deducing this: 'self' is the closure object
    std::invoke(&Listener::onClick, lst, val);
});
```

(though the simple example above without deducing this suffices for most cases).

**Caveats:**  `std::function` adds some overhead (type-erasure and possible heap allocation) compared to raw function pointers.  But it’s usually negligible for observer lists of moderate size.  Also, be careful with object lifetimes: if an observer captures a raw `this`, make sure the object lives as long as the subscription (or use `std::weak_ptr`).  Deducing-this feature is C++23, so if using it ensure compiler support; otherwise stick to normal lambdas.

**Use Cases:**  Observer/type-erasure is everywhere: GUI event handlers (buttons, sliders), game event systems, or event buses in server applications.  For example, a **game engine** might have an `EventDispatcher` where any game object can subscribe a lambda to respond to “collision” or “input” events.  In **finance**, you might have market data feeds where listener objects subscribe to price updates via callbacks.  In **systems**, OS signals or hardware interrupts could be handled by an observer-like callback system.  Type erasure means the subject code doesn’t need to know about observer classes or interfaces – just a callable signature.

## Concurrency Barrier (Thread Coordination with `<barrier>`)

**Problem:**  In multithreaded programs, a common need is to synchronize a *group* of threads at certain points (barriers).  For example, in a simulation we may want all worker threads to finish one phase before any proceed to the next.  Before C++20, you had to build such synchronization manually (using atomics, condition variables, or third-party libraries).

**Modern C++ Solution:**  C++20 introduced `std::barrier` (in `<barrier>`, reused in C++23) for exactly this purpose.  A `std::barrier` is initialized with the number of threads (or participants). Each thread calls `arrive_and_wait()` when it reaches the sync point. The barrier blocks them all until the last arrives, then optionally runs a completion function exactly once, and finally releases all threads to continue (and the barrier resets for reuse).

```cpp
#include <barrier>
#include <thread>
#include <iostream>

void worker(std::barrier<> &bar, int id) {
    std::cout << "Thread " << id << " before barrier\n";
    bar.arrive_and_wait();  // block until all threads reach here
    std::cout << "Thread " << id << " after barrier\n";
}

int main() {
    constexpr int N = 3;
    std::barrier barrier(N);  // barrier for 3 threads

    std::thread t1(worker, std::ref(barrier), 1);
    std::thread t2(worker, std::ref(barrier), 2);
    std::thread t3(worker, std::ref(barrier), 3);

    t1.join(); t2.join(); t3.join();
}
```

All three threads will print “before barrier”, then the barrier lets them all go, then each prints “after barrier”.  We could also pass a lambda to `barrier`’s constructor to do some action once per phase (like update a shared counter or print a status) before the threads continue.

**C++23 Features:**  - **`std::barrier`** (since C++20, in `<barrier>`) provides a reusable barrier with a phase completion callback.  - `std::latch` is similar but one-shot.  (Strictly speaking, barrier is a C++20 feature; it’s available in C++23 as part of the standard concurrency library.)  No new C++23-specific changes here beyond library availability.

**Caveats:**  You must know the number of participants upfront.  Spawning or dropping threads dynamically requires careful use of `arrive_and_drop()`.  Also, barriers don’t by themselves handle thread termination – make sure all expected threads call `arrive`.  Old compilers (pre-C++20) lack `std::barrier`; you would then use `std::condition_variable` or platform-specific barriers.

**Use Cases:**  Barriers are vital in parallel algorithms.  In **high-performance computing (HPC)**, they synchronize steps in parallel loops or stages of an algorithm.  In **game development**, a barrier might sync physics threads at the end of each simulation tick before rendering.  In **video encoding** or **signal processing**, you often have pipeline stages where each thread must finish its part before the next stage starts – a barrier fits perfectly.

**Summary:**  `std::barrier` gives a clear, deadlock-free way to coordinate threads.  As cppreference describes, *“barriers are reusable: once a group of arriving threads are unblocked, the barrier can be reused. Unlike std::latch, barriers execute a possibly empty callable before unblocking threads.”*. This greatly simplifies multithreaded stage synchronization.

---

Each of these patterns leverages modern C++. They can also be **combined**. For example, a multithreaded pipeline might use a range-based sequence processed by worker threads, with a barrier at each pipeline stage. Or a coroutine generator could be an observer of an async event. The key is: when you recognize a classic pattern need, ask **“What C++23 features can simplify this?”**. Often the answer is: *significantly* cleaner and more performant code.

**Sources:** Above explanations draw on expert blogs and the standard library. For more details, see cppreference and WG21 proposals (e.g. [P2502](https://wg21.link/p2502r2) for coroutines, [P0847](https://wg21.link/p0847r6) for deducing-this). And of course, experiment with real code on the latest compilers to see these patterns in action. Happy coding!
