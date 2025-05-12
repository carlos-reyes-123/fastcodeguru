+++
draft       = false
featured    = false
title       = "C++ Universal Constructor"
slug        = "c++-universal-constructor"
description = "Can the default-, copy-, and move-constructors be combined in C++?"
ogImage     = "./c++-universal-constructor.png"
pubDatetime = 2025-02-26T16:00:00Z
author      = "Carlos Reyes"
tags        = [
    "C++23",
    "Universal Constructor",
    "Default Constructor",
    "Copy Constructor",
    "Move Constructor",
    "Move Semantics",
    "Copy Semantics",
    "Delegating Constructors",
    "noexcept Specification",
    "Concepts and Constraints",
    "Template Metaprogramming",
    "Overload Resolution",
    "Code Readability",
    "Portability Concerns",
    "Compiler Bugs",
    "Game Development",
    "Financial Systems",
    "Systems Programming",
    "Best Practices",
    "Deep Dive",
]
+++

![C++ Universal Constructor](./c++-universal-constructor.png "C++ Universal Constructor")

## Table of Contents

---

## Introduction

I’ve been fascinated recently by the idea of combining default-, copy-, and move-construction all in one “universal constructor.” In this article I’ll walk you through:

* **What** a universal constructor is
* **How** to implement one in C++23
* **Why** you might (or might not) want to use it
* **Caveats**, portability concerns, and real-world anecdotes

Throughout, I’ll sprinkle in code samples, tables, callouts, and examples drawn partly from my own code and partly from stories I’ve picked up in game-dev, finance, and systems-programming circles.

---

## Why even think about a universal constructor?

In most C++ classes you end up writing three constructors (or relying on the compiler to generate them):

1. **Default constructor**
2. **Copy constructor**
3. **Move constructor**

Occasionally you’ll write them yourself to enforce invariants, add logging, or control exception-safety. But maintaining three overloads can feel boilerplate-y, especially when they mostly share the same logic.

> **💡 Fun fact:** On one project I worked on, our class `EntityState` grew to five constructors (default, copy, move, copy-from-JSON, move-from-JSON), and we spent more time writing tests to exercise each overload than actually implementing features!

A “universal constructor” aims to fold all three into one templated overload:

```cpp
template<typename U = T>
requires std::same_as<std::remove_cvref_t<U>, T>
explicit T(U&& other = {}) noexcept( /* … */ );
```

This single template handles:

* **No-argument calls** → default initialization
* **Lvalue arguments** → copy semantics
* **Rvalue arguments** → move semantics

The payoff? Less duplication. The trade-off? More template complexity, subtler overload resolution, and potential interactions with other special members.

---

## A step-by-step implementation

Let’s build a minimal class `Universal` that packs default, copy, and move into one constructor. I’ll show the full code, then dig into each piece.

```cpp
#include <concepts>      // for std::same_as
#include <type_traits>   // for type traits
#include <utility>       // for std::move

struct Universal {
    int data_{42};

    // 1. Default constructor
    Universal() noexcept {
        // maybe some complex setup
    }

    // 2. The universal constructor
    template<typename U = Universal>
    requires std::same_as<std::remove_cvref_t<U>, Universal>
    explicit Universal(
        U&& other = {}                      // default, lvalue, or rvalue
    ) noexcept(
        // move-case noexcept?
        (std::is_rvalue_reference_v<U&&> &&
         std::is_nothrow_move_constructible_v<Universal>)
        ||
        // copy-case noexcept?
        (!std::is_rvalue_reference_v<U&&> &&
         std::is_nothrow_copy_constructible_v<Universal>)
    )
    : Universal{}  // delegate to default ctor
    {
        if constexpr (std::is_rvalue_reference_v<U&&>) {
            // Move semantics
            data_ = std::move(other.data_);
        } else {
            // Copy semantics
            data_ = other.data_;
        }
    }
};
```

> **Tip:** Delegating to `Universal{}` in the member-initializer list ensures any complex default setup runs exactly once.

### Breaking down the pieces

1. **`template<typename U = Universal>`**

   * A defaulted template parameter allows us to call `Universal{}` (no args) and deduce `U = Universal`.
2. **`U&& other = {}`**

   * Accepts an lvalue reference (`Universal&`), rvalue reference (`Universal&&`), or default-constructed prvalue (`{}`).
3. **`requires std::same_as<std::remove_cvref_t<U>, Universal>`**

   * Constrains the overload so that only `Universal` (ignoring cv-qualifiers and refs) is accepted. No unintended conversions from other types sneak in.
4. **`noexcept(…)`**

   * Chooses at compile-time whether this constructor is `noexcept`.
   * If `other` is an rvalue → checks `is_nothrow_move_constructible_v<Universal>`.
   * Else → checks `is_nothrow_copy_constructible_v<Universal>`.
   * See [noexcept specifier](https://en.cppreference.com/w/cpp/language/noexcept) for details.
5. **`if constexpr`**

   * Distinguishes **move** vs **copy** branches using `std::is_rvalue_reference_v<U&&>`.

---

## Delegating Constructors

In C++11 and later, when one constructor invokes another constructor of the *same* class in its member-initializer list, that’s called **delegating** construction. In our “universal constructor” sample we wrote:

```cpp
explicit Universal(U&& other = {}) noexcept(/*…*/)
  : Universal{}         // ← here: delegate to the default ctor
{
    if constexpr (std::is_rvalue_reference_v<U&&>) {
        data_ = std::move(other.data_);
    } else {
        data_ = other.data_;
    }
}
```

When you write Universal{}, both constructors are viable (one takes 0 args, the other takes 1 with a default). But per the [overload resolution rules](https://en.cppreference.com/w/cpp/language/overload_resolution#Ranking_of_overload_candidates):

> **Given two viable function overloads, if one is a non-template function and the other is a function template specialization, the non-template is considered more specialized and is chosen.**

So for **direct-list-initialization** (`Universal u{};`):

1. Both `(1)` and `(2)` are viable.
2. The compiler prefers the non-template `Universal()` over the templated one.

We need the default constructor, since it is used to initialize the default argument to the copy/move constructor. Omitting it is an error, since doing so implies the copy/move constructor would have to call itself. So technically we still need two separate constructors and the move/copy constructor will never be called without an argument. But hey, this is all mostly a mental exercise anyway.

---

## Why the default argument rocks (and slightly bites)

Using `U&& other = {}` means:

* **`Universal u;`**
  \--> Calls default constructor.
* **`Universal copy(u);`**
  \--> Deduces `U = Universal&`, copy branch.
* **`Universal move(Universal{});`**
  \--> Deduces `U = Universal`, rvalue branch.

> **⚠️ Gotcha:** Some compiler bug reports (particularly older MSVC versions before Q3/2023) mis-deduce `U` in certain default-argument cases. Always test in your target toolchains.

---

## Comparing designs

| Feature             | Traditional ctors       | Universal constructor                |
| ------------------- | ----------------------- | ------------------------------------ |
| Number of overloads | 3 (default, copy, move) | 1 templated                          |
| Code duplication    | Medium                  | Low                                  |
| `noexcept` control  | Manual per ctor         | Computed via traits + `if constexpr` |
| Readability         | High                    | Moderate                             |
| Potential pitfalls  | Low                     | Template overload complexity         |
| Compiler support    | C++11+                  | C++20+                               |

---

## Caveats & shortcomings

1. **Interference with special members**
   The templated ctor can suppress the implicit generation of copy/move ctors. If you still want the defaults, you must explicitly `= default;` them.
2. **Overload resolution surprises**
   Other constructors or conversion overloads may be chosen unexpectedly.
3. **Debuggability**
   Stepping through a templated constructor with `if constexpr` can be more confusing than seeing three separate functions.
4. **Concept and `<type_traits>` heavy**
   Requires C++20 concepts (`<concepts>`) or verbose SFINAE.
5. **Portability concerns**

   * GCC 10–11 had partial concept bugs.
   * MSVC before 19.30 mishandled defaulted template parameters in `noexcept` expressions.
   * Always test on all your platforms!

> **Warning:** In a cross-platform library, introducing one universal constructor may introduce subtle, platform-specific overload ambiguities that are a nightmare to diagnose.

---

## When might you reach for it?

Despite the complexities, I’ve heard of a few niche scenarios where a universal ctor made sense:

* **Small utility types**
  A tiny wrapper like:

  ```cpp
  struct Tag { /* no resources */ };
  ```

  Folding everything into one overload saved a few lines without hurting clarity.
* **Metaprogramming toy libraries**
  When your class is entirely header-only, heavily templated, and you don’t care about human-readability.
* **Experimentation & teaching**
  As a thought experiment in C++ mastery courses, to show how far you can push the language.

On a large, production-quality codebase? I’d usually stick with explicit overloads.

---

## Real-world anecdotes

> **Game-dev friend’s tale**
> A colleague once used a universal ctor in an ECS library. On GCC 10, it compiled fine; on MSVC it silently picked the universal overload for certain custom conversions, leading to a subtle object-slice bug. They reverted to explicit `Foo(const Foo&) = default; Foo(Foo&&) = default;`.
>
> **Finance-sector story**
> A risk-analysis framework folded copy/move into one template. Later, someone tried to add a JSON-load constructor (`Foo(std::string_view json)`), and the template happily accepted that overload, resulting in weird silent failures.

I’ve toyed with it in small, self-contained contexts. Personally, I find the clarity of three separate constructors outweighs the brevity of a single template in most of my code.

---

## Portability & compiler support

| Compiler | Minimum version | Notes                                      |
| -------- | --------------- | ------------------------------------------ |
| GCC      | 10+             | Concepts working, but test `noexcept`.     |
| Clang    | 12+             | Good template support; watch `-std=c++23`. |
| MSVC     | 19.30+          | Fixed default template parameter bugs.     |

If you must support older compilers:

* Fall back to SFINAE with `std::enable_if_t` instead of `requires`.
* Avoid default arguments in the template, and provide an explicit default ctor.

---

## A lighter alternative

If you like brevity but want fewer footguns, consider:

```cpp
struct Simple {
    int data_{};

    Simple() = default;
    Simple(const Simple&) = default;
    Simple(Simple&&) noexcept = default;
};
```

This still gives you three overloads, but each is declared with minimal boilerplate, and the compiler handles all the nuances. I often favor this **Rule of Zero/Three/Five** approach over fancy one-liner templates.

---

## Conclusion

The universal constructor is a neat demonstration of how far C++23’s templates, `if constexpr`, and concepts can stretch. It can reduce boilerplate in very small utility types or as a teaching tool. But in day-to-day production code, the added template complexity, portability traps, and risk of subtle overload interactions usually outweigh the brevity. I recommend reserving it for toy libraries or code-golf challenges—and otherwise sticking with explicit default, copy, and move constructors.

Happy coding!

---

### Further reading

* [noexcept specifier (cppreference)](https://en.cppreference.com/w/cpp/language/noexcept)
* [if constexpr (cppreference)](https://en.cppreference.com/w/cpp/language/if_constexpr)
* [Template parameter defaults (cppreference)](https://en.cppreference.com/w/cpp/language/template_parameters)
