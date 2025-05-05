+++
draft       = false
title       = "Practical Profiling with perf on Linux"
slug        = "practical-profiling-perf-linux"
description = "`perf` is the user-space front-end to the Linux **perf_event** subsystem (the `perf_event_open(2)` syscall). It offers a uniform command-line interface to **hardware Performance-Monitoring Units (PMU), kernel trace-points, software counters, kprobes/uprobes, and eBPF** events, hiding the architectural quirks of each CPU family."
ogImage     = "./linux-perf.png"
author      = "Carlos Reyes"
pubDatetime = 2025-01-15T16:00:00Z
featured    = false
tags        = [
    "beginner",
    "counters",
    "linux",
    "perf",
    "performance",
    "pmc",
    "profiling",
]
+++

## What **perf** is
`perf` is the user-space front-end to the Linux **perf_event** subsystem (the `perf_event_open(2)` syscall).
It offers a uniform command-line interface to **hardware Performance-Monitoring Units (PMU), kernel trace-points, software counters, kprobes/uprobes, and eBPF** events, hiding the architectural quirks of each CPU family. It ships in the kernel tree (tools/perf) and is packaged by most distributions as *linux-tools-$(uname -r)*.[^perf]

[^perf]: [Introduction - perf: Linux profiling with performance counters](https://perfwiki.github.io/main/tutorial/)

## Why you might care
*   **Pinpoint hot spots** — attribute CPU cycles, stalled slots, cache-misses or branch mis-predictions to lines of code without recompiling.
*   **Measure whole-system behaviour** — sample across all tasks (`-a`) or within cgroups, profile kernels, containers and virtual machines (`perf kvm`).
*   **Low overhead, production-safe** — sampling incurs < 1–5 % overhead at typical frequencies.
*   **Rich ecosystem** — outputs feed directly into FlameGraph, speedscope, or BPF-based visualizers.
*   **Always up-to-date** — because perf ships with each kernel release, new CPU features (Hybrid/Big-LITTLE core distinctions, Intel LBR call-stacks, AMD IBS, Arm SPE, etc.) appear as soon as your distro updates its kernel.[^gregg]

[^gregg]: [Linux perf Examples - Brendan Gregg](https://www.brendangregg.com/perf.html)

## Mental model
| Concept | What it means | Example flags |
|---------|---------------|---------------|
| **Event** | Thing you count or sample | `-e cycles`, `-e mem-loads,mem-stores` |
| **Counting vs. Sampling** | Simple aggregate counters (`perf stat`) vs. periodic PC/IP snapshots (`perf record -F99`) | `perf stat`, `perf record` |
| **Call-graph mode** | Capture stack traces with frame-pointer unwind, DWARF, Last-Branch-Records or BPF | `-g fp`, `-g dwarf`, `--call-graph lbr` |
| **perf.data** | Binary file holding raw samples; post-processed by sub-commands | `perf report`, `perf script` |

## Quick-start workflow

```bash
# 1. Get a high-level performance baseline
perf stat -e cycles,instructions,cache-misses ./my_app

# 2. Sample 99 Hz, record user-space call-graphs, system-wide (-a)
sudo perf record -F 99 -g -a -- ./my_loadgen.sh

# 3. Inspect the profile (TUI or stdio)
perf report            # interactive
perf report --stdio    # pipe to less

# 4. Zoom into specific functions/lines
perf annotate -p <PID>
```
`perf top` gives a live, *htop*-like view, continuously refreshing hottest symbols.[^redhat]&nbsp;[^nap]

[^redhat]: [Chapter 21. Recording and analyzing performance profiles with perf](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/recording-and-analyzing-performance-profiles-with-perf_monitoring-and-managing-system-status-and-performance)

[^nap]: [Linux perf: How to Use the Command and Profiler | phoenixNAP KB](https://phoenixnap.com/kb/linux-perf)

## Most-used sub-commands

* **perf stat** aggregate counters for one run, multiple events in parallel.
* **perf record / report / annotate** sampling → analysis cycle; supports user stacks, kernel stacks, mixed mode.
* **perf top** real-time sampling (hit **a** to toggle kernel/user).
* **perf trace** lightweight syscall/ftrace tracer (a faster `strace`).
* **perf sched** detect run-queue latency and involuntary context-switch delays.
* **perf mem –stat / –live** NUMA and memory-access profiling.
* **perf c2c** cache-to-cache false-sharing detector on multi-socket systems.
* **perf bench** micro-benchmarks for cpuhog, syscall, numa, memset, etc.

## Choosing and grouping events

```bash
# Sample multiple hardware events as a group so they are counted together
sudo perf record -e '{cycles,cache-misses,branch-misses}:u' -c 100000 -g ./app

# Use raw event codes if the alias is missing on your CPU
# Intel “frontend stalled” & “cycle activity:stalls_l2_miss”
sudo perf stat -e r003c,r0041 ./app
```

Individual events can be limited to **user (`:u`)**, **kernel (`:k`)**, or **hypervisor (`:h`)** privilege levels. Event selection varies by micro-architecture, but `perf list` prints everything supported on the running kernel.

## Scope and filtering

* **Per-PID / thread** `-p PID`, `-t TID`
* **CPU mask** `-C 0-3,6` (profile big cores only)
* **Duration / delay** `--timeout 10s`, `--delay 5`
* **cgroup** `--cgroup=/sys/fs/cgroup/my_ctn` (container-only profiling)

## Call-graph collection nuances

| Mode | Pros | Cons | Kernel ≥ 6.8 notes |
|------|------|------|--------------------|
| `-g fp` (frame-pointer) | zero config, low overhead | needs FP-enabled build | default on many distros |
| `-g dwarf` | works with FP-omitted builds | higher unwind cost | faster thanks to ORC |
| `--call-graph lbr` (Intel/AMD) | near-zero overhead, deep stacks | requires hardware LBR | hybrid-core aware |
| `--call-graph lbr,bpf` | uses BPF helper to unwind userspace | best for mixed languages | new in kernel 6.9 |

Stacks from JIT runtimes (JVM, V8, .NET) need `perf map` support or BPF CO-RE unwinders.

## Post-processing and visualisation

```bash
# Convert to folded stacks for FlameGraph
perf script | stackcollapse-perf.pl > out.folded
flamegraph.pl out.folded > flame.svg

# Generate speedscope JSON
perf script -F +pid,comm,ip,sym | perf_script_speedscope > profile.speedscope.json
```

`perf inject` can post-process LBR data to enrich samples, and `perf archive` bundles symbol files for offline analysis.

## Practical tips & caveats

*   **Privileges:** events marked “Precise” or raw PMU codes usually require `sudo` or `perf_event_paranoid = 1`.
*   **Match versions:** userspace `perf` must match (or be newer than) the running kernel; `perf version` prints both hashes.
*   **Build-ID cache:** `perf buildid-cache --add /path/to/lib.so` ensures symbols for stripped binaries.
*   **Minimise distortion:** prefer *period-based* sampling (`-c`) for very short-lived functions; throttle frequency on production (e.g. `-F 400`).
*   **Containerised kernels:** under Kubernetes use `--cgroup` or `--uid` filters; ensure /proc/sys/kernel/perf_event_paranoid inside the host allows sampling.
*   **Hybrid (P-/E-core) systems:** pin to core type with `--cpu-type=performance` (kernel 6.8+) to avoid mixed counters.

## Conclusion
`perf` combines a profiler, tracer, and benchmark suite into a single **first-party, always-available** tool. By counting or sampling nearly every performance-relevant event the kernel exposes, it lets you move from “the code feels slow” to a quantified, line-level diagnosis in minutes—without invasive instrumentation or proprietary SDKs. Armed with the commands above you can start **measuring before guessing** and make data-driven optimisation a routine part of your Linux workflow.
