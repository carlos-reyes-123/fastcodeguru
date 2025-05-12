+++
draft       = false
featured    = false
title       = "Modern CMake Best Practices: Building Better C++ Projects in 2025"
slug        = "modern-cmake-best-practices"
description = "We’ll explore modern CMake best practices that have transformed my workflow and can help you build better C++ projects."
ogImage     = "./modern-cmake-best-practices.png"
pubDatetime = 2025-03-11T16:00:00Z
author      = "Carlos Reyes"
tags        = [
    "C++",
    "Modern CMake",
    "Target-Based CMake",
    "CMake FetchContent",
    "Cross-Platform Builds",
    "Ninja Build System",
    "Parallel Compilation",
    "Unity Builds",
    "Precompiled Headers",
    "Dependency Management",
    "Conan Package Manager",
    "vcpkg Package Manager",
    "Compiler Optimizations",
    "Systems Programming",
    "Financial Systems",
    "Game Development",
    "Embedded Systems",
    "Build Performance",
    "Portable Build Scripts",
    "Deep Dive Tutorial",
]
+++

![Modern CMake Best Practices](./modern-cmake-best-practices.png "Modern CMake Best Practices")

## Table of Contents

---

## Introduction

As someone who has battled with build systems for decades, I've witnessed the evolution of CMake from a confusing maze of commands to the sophisticated build system generator it is today. In this deep dive, we'll explore modern CMake best practices that have transformed my workflow and can help you build better C++ projects (and TypeScript or Python projects with C++ extensions).

## The Evolution of CMake: From Humble Beginnings to Modern Powerhouse

When I first encountered CMake around 2008, it was already gaining traction, but the documentation was sparse, examples were inconsistent, and the learning curve was steep. Back then, we wrote CMake scripts that directly manipulated variables like `CMAKE_CXX_FLAGS` and used commands like `INCLUDE_DIRECTORIES()` that affected the entire build.

> 💡 **Historical Note**: CMake was originally developed by Kitware in 2000 as part of the Insight Segmentation and Registration Toolkit (ITK) project funded by the National Library of Medicine.

Fast forward to today, and modern CMake (version 3.15+) has embraced a target-based approach with clear scoping rules, improved syntax, and powerful built-in features. The shift began around CMake 3.0, with the introduction of target-based properties, and has continued with each release adding more developer-friendly features.

### Key Evolutionary Milestones

| CMake Version | Year | Notable Changes |
|---------------|------|-----------------|
| 2.8.12        | 2013 | Introduced `target_include_directories()` |
| 3.0           | 2014 | Target-based approach began in earnest |
| 3.11          | 2018 | Added FetchContent module |
| 3.12          | 2018 | Added CONFIGURE_DEPENDS for file globs |
| 3.14          | 2019 | Added file(REAL_PATH) function |
| 3.20+         | 2021+ | Presets, improved generator expressions, better IDE integration |

I still remember the epiphany I had when I finally understood the difference between `include_directories()` and `target_include_directories()`. That single conceptual shift dramatically improved the organization of my build scripts.

## Why CMake Remains the Gold Standard

Despite newer entrants to the build system arena (Meson, Bazel, etc.), CMake has maintained its position as the de facto standard for C++ projects. Here's why I continue to use it:

1. **Ubiquitous Industry Adoption**: Major projects from LLVM and Qt to TensorFlow and OpenCV use CMake.
2. **Mature Ecosystem**: Extensive documentation, books, and community support.
3. **IDE Integration**: First-class support in Visual Studio, CLion, VS Code, and other popular IDEs.
4. **Cross-Platform**: Works consistently across Windows, macOS, Linux, and even mobile platforms.
5. **Flexibility**: Can generate for numerous build systems (Make, Ninja, Visual Studio, Xcode).

A colleague in game development recently told me that switching from a custom build system to CMake cut their build configuration maintenance time by 70%. That's not surprising when you consider the broad support and extensive tooling CMake offers.

## Ninja: The Speed Demon That Supercharges Your Builds

While CMake isn't a build system itself but a generator, pairing it with Ninja has revolutionized my build times.

```bash
# Generate build files using CMake with Ninja
cmake -G Ninja -B build -S .

# Build the project using Ninja
cmake --build build
```

Ninja was originally developed for the Chromium project by Evan Martin and is designed for speed. Unlike traditional build systems like Make, Ninja focuses on doing one thing exceptionally well: building your code as fast as possible.

### Why Ninja Outperforms Traditional Makefiles

- **Minimal Rebuilds**: Ninja is aggressive about rebuilding only what's necessary.
- **Efficient Dependency Checking**: Avoids redundant file stat operations.
- **Low-Level Optimization**: Written in C++ with performance as the primary goal.
- **Smart Parallelization**: Better job scheduling than Make.

> ⚠️ **Gotcha Alert**: When switching to Ninja, watch out for build scripts that assume a specific generator. I once lost hours debugging because a custom script was hard-coded to expect Visual Studio-generated file paths.

In a financial trading application I consulted on, switching from Visual Studio's MSBuild to Ninja cut the full rebuild time from 15 minutes to just under 5 minutes on the same hardware. The difference was even more dramatic for incremental builds.

## Harnessing Multiple CPU Cores for Lightning-Fast Builds

Modern processors have plenty of cores, and CMake makes it easy to use them all.

```bash
# Use all available cores
cmake --build build -j

# Specify number of cores
cmake --build build -j 8
```

For large codebases, I've found that setting jobs to `N+1` or `N+2` (where N is the number of physical cores) can sometimes yield better results due to I/O waiting. However, this can vary based on your specific hardware and project.

### Tips for Optimizing Parallel Builds

1. **Use Unity Builds**[^unity] for heavily templated code:

[^unity]: [https://cmake.org/cmake/help/latest/prop_tgt/UNITY_BUILD.html](https://cmake.org/cmake/help/latest/prop_tgt/UNITY_BUILD.html)

```cmake
# Enable unity builds (combining multiple source files)
set_target_properties(MyTarget PROPERTIES UNITY_BUILD ON)
```

2. **Precompiled Headers** for large projects:

```cmake
target_precompile_headers(MyTarget PRIVATE
  <vector>
  <string>
  <unordered_map>
  "my_project_pch.h"
)
```

3. **Organize targets** to maximize parallelism by breaking monolithic libraries into smaller, focused components.

I once worked on a systems development project where we rewrote a monolithic CMake build into properly separated targets with clear dependencies. Build times dropped from 45 minutes to 12 minutes partly because more components could be built in parallel.

## Keeping Your CMakeLists.txt Files Clean and Organized

As projects grow, maintaining clean, readable CMake files becomes essential. Here are my time-tested strategies:

### Directory Structure

```
project_root/
├── CMakeLists.txt
├── cmake/                  # CMake modules and helpers
│   ├── FindSomePackage.cmake
│   └── ProjectConfig.cmake.in
├── src/                    # Main project sources
│   ├── CMakeLists.txt
│   ├── component1/
│   │   └── CMakeLists.txt
│   └── component2/
│       └── CMakeLists.txt
├── include/                # Public headers
│   └── project/
├── tests/                  # Tests
│   └── CMakeLists.txt
└── third_party/            # Third-party dependencies
    └── CMakeLists.txt
```

### Use Functions and Macros for Repetitive Tasks

```cmake
# Define a function for creating library targets with consistent settings
function(add_project_library name)
    set(options STATIC SHARED)
    set(oneValueArgs VERSION)
    set(multiValueArgs SOURCES HEADERS DEPENDENCIES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}"
                              "${multiValueArgs}" ${ARGN})

    # Determine library type (default to STATIC)
    if(ARG_SHARED)
        set(LIB_TYPE SHARED)
    else()
        set(LIB_TYPE STATIC)
    endif()

    # Add the library with source files
    add_library(${name} ${LIB_TYPE} ${ARG_SOURCES} ${ARG_HEADERS})

    # Set up include directories
    target_include_directories(${name}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:include>
        PRIVATE
            ${CMAKE_CURRENT_SOURCE_DIR}/src
    )

    # Add dependencies
    if(ARG_DEPENDENCIES)
        target_link_libraries(${name} PUBLIC ${ARG_DEPENDENCIES})
    endif()

    # Set up installation rules
    install(TARGETS ${name}
        EXPORT ${PROJECT_NAME}Targets
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION bin
        INCLUDES DESTINATION include
    )
endfunction()

# Usage example
add_project_library(geometry
    SOURCES
        src/shape.cpp
        src/circle.cpp
        src/rectangle.cpp
    HEADERS
        include/geometry/shape.h
        include/geometry/circle.h
        include/geometry/rectangle.h
    DEPENDENCIES
        math_utils
)
```

### More Organization Tips

1. **Use target properties** extensively
2. **Group related settings** together
3. **Comment complex sections**
4. **Use consistent naming conventions**
5. **Avoid hardcoded paths**

> 🔍 **Pro Tip**: Use `cmake_format` to automatically format your CMake files consistently. It works similarly to clang-format but for CMake.

## Modern Dependency Management

Gone are the days of manually downloading and integrating third-party libraries. Modern CMake offers several elegant solutions.

### FetchContent - The Built-in Solution

For simple cases, CMake's built-in FetchContent module is excellent:

```cmake
include(FetchContent)

FetchContent_Declare(
    fmt
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG 9.1.0
)

FetchContent_MakeAvailable(fmt)

# Later, simply link against the target
target_link_libraries(MyApp PRIVATE fmt::fmt)
```

### Package Managers - For Production-Grade Management

For more complex projects, package managers like Conan or vcpkg provide robust dependency management:

#### Conan Example

```cmake
# CMakeLists.txt
find_package(Conan REQUIRED)
conan_cmake_run(
    REQUIRES
        boost/1.78.0
        nlohmann_json/3.11.2
    BASIC_SETUP CMAKE_TARGETS
    BUILD missing
)

find_package(Boost 1.78.0 REQUIRED)
find_package(nlohmann_json 3.11.2 REQUIRED)

target_link_libraries(MyApp PRIVATE
    Boost::boost
    nlohmann_json::nlohmann_json
)
```

#### vcpkg Example

```cmake
# CMakeLists.txt
find_package(unofficial-sqlite3 CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)

target_link_libraries(MyApp PRIVATE
    unofficial::sqlite3::sqlite3
    OpenSSL::SSL
    OpenSSL::Crypto
)
```

> ⚠️ **Warning**: When switching between package managers or from a manual approach to a package manager, ensure you don't accidentally mix multiple versions of the same library, which can lead to subtle linking issues or runtime crashes.

I once wasted an entire day debugging a mysterious crash that occurred only in release builds. The culprit? Two different versions of Boost were being linked because our build system was finding both a system-installed version and a package-managed version.

## Real-World Examples

### Game Development

A game development studio I consulted for uses CMake to build their engine that targets Windows, macOS, Linux, iOS, and Android. Their modular structure allows for quick iteration:

```cmake
# Core engine components
add_subdirectory(engine/core)
add_subdirectory(engine/graphics)
add_subdirectory(engine/audio)
add_subdirectory(engine/physics)

# Platform-specific implementations
if(ANDROID)
    add_subdirectory(engine/platform/android)
elseif(IOS)
    add_subdirectory(engine/platform/ios)
# ... other platforms
endif()

# Game-specific code
add_subdirectory(game)
```

Their key optimization was creating "interface targets" for platform abstractions, allowing platform-specific implementations to be swapped without changing the core engine code.

### Finance Industry

A trading platform I worked on used CMake to build a low-latency system:

```cmake
# Define the main library with appropriate compiler flags
add_library(trading_engine STATIC ${SOURCES})

# Apply platform-specific optimizations
if(MSVC)
    target_compile_options(trading_engine PRIVATE
        /O2 /Ob3 /GL /Qpar /fp:fast
    )
elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(trading_engine PRIVATE
        -O3 -march=native -ffast-math -ftree-vectorize
    )
endif()

# Special handling for hot path code
set_source_files_properties(
    src/order_matching.cpp
    src/price_calculation.cpp
    PROPERTIES COMPILE_FLAGS "${ADDITIONAL_OPTIMIZATION_FLAGS}"
)
```

They also created a custom CMake module to detect and use the Intel C++ Compiler when available, which gave them an additional 5-15% performance improvement for numerical calculations.

### Systems Development

A colleague working on an embedded systems project shared how they handle cross-compilation with CMake:

```cmake
# Toolchain file for ARM cross-compilation
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)

# Firmware-specific flags
add_compile_options(
    -mcpu=cortex-m4
    -mthumb
    -mfpu=fpv4-sp-d16
    -mfloat-abi=hard
)

# Later in the main CMakeLists.txt
add_executable(firmware ${SOURCES})
set_target_properties(firmware PROPERTIES SUFFIX ".elf")

# Create binary firmware image
add_custom_command(
    TARGET firmware POST_BUILD
    COMMAND arm-none-eabi-objcopy -O binary
            $<TARGET_FILE:firmware> firmware.bin
    VERBATIM
)
```

They ingeniously used CMake's generator expressions to adapt the build for different target boards without duplicating configuration.

## Portability and Compiler Considerations

Ensuring your CMake scripts work across platforms and compilers requires attention to detail.

### Cross-Platform Pitfalls

- **Path Separators**: Use `CMAKE_CURRENT_SOURCE_DIR` and related variables instead of hardcoded paths.
- **File Globbing**: Be cautious with `GLOB`; prefer explicit file lists or use `CONFIGURE_DEPENDS`.
- **Compiler Detection**: Use `CMAKE_CXX_COMPILER_ID` and version checks for compiler-specific settings.

```cmake
# Right way to check for compiler features
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS 9.0)
        message(WARNING "GCC version < 9.0 has incomplete C++17 support")
    endif()
    target_compile_options(MyTarget PRIVATE -Wall -Wextra)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(MyTarget PRIVATE -Wall -Wextra -Wno-missing-braces)
elseif(MSVC)
    target_compile_options(MyTarget PRIVATE /W4 /permissive-)
endif()
```

### Portable Feature Testing

Modern CMake provides `try_compile` and `CheckCXXSourceCompiles` to test for features rather than making assumptions based on compiler version:

```cmake
include(CheckCXXSourceCompiles)

check_cxx_source_compiles("
    #include <span>
    int main() { std::span<int> s; return 0; }
" HAVE_STD_SPAN)

if(HAVE_STD_SPAN)
    target_compile_definitions(MyTarget PRIVATE HAVE_STD_SPAN)
else()
    message(STATUS "std::span not available, using fallback implementation")
    target_include_directories(MyTarget PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/compat)
endif()
```

I still remember a particularly frustrating experience with a project that worked perfectly on Linux but failed mysteriously on Windows. After hours of debugging, we discovered that a developer had used case-insensitive file references that worked on Windows but failed on Linux's case-sensitive filesystem.

## Conclusion: Embracing Modern CMake for Better Builds

Modern CMake has evolved into a robust, expressive build system generator that can dramatically improve your development workflow. By embracing target-based approaches, leveraging Ninja for speed, organizing your CMakeLists.txt files thoughtfully, and using modern dependency management, you can create build systems that are maintainable, portable, and efficient.

Here are the key takeaways:

1. Use target-based commands (`target_*`) instead of global ones
2. Leverage Ninja for faster builds
3. Organize your CMake files with clear structure and modularity
4. Use modern dependency management tools
5. Think about cross-platform compatibility from the start

### Further Resources

- [Professional CMake: A Practical Guide](https://crascit.com/professional-cmake/) by Craig Scott
- [Modern CMake](https://cliutils.gitlab.io/modern-cmake/) - An online book
- [CMake Cookbook](https://www.packtpub.com/product/cmake-cookbook/9781788470711) by Radovan Bast and Roberto Di Remigio
- [Effective Modern CMake](https://gist.github.com/mbinna/c61dbb39bca0e4fb7d1f73b0d66a4fd1) - A collection of best practices
- [Official CMake Documentation](https://cmake.org/documentation/) - Much improved in recent years
- [CMake Tutorial](https://cmake.org/cmake/help/latest/guide/tutorial/index.html) - Step-by-step guide from the CMake team

As build systems continue to evolve, CMake shows no signs of losing its dominant position in the C++ ecosystem. By keeping up with modern CMake best practices, you'll be well-equipped to tackle the build challenges of today's complex software projects.

*What build system challenges are you facing in your projects? Let me know in the comments below!*
