---
name: zig-017-tiger
description: Writes, reviews, and optimizes Zig 0.17.0 code under Tiger Style. Use for implementation, ownership, standard-library APIs, I/O, concurrency, builds, and performance targeting this exact release.
---

# Zig 0.17.0 with Tiger Style

## Required workflow

1. Match the request: review-only tasks report findings without edits; fixes change code.
   Read repository instructions and affected code. Verify `zig version` is `0.17.0`;
   locate sources with `zig env`. Reuse evidence until the toolchain changes. If unavailable,
   continue design/review, mark compilation unverified, and never silently retarget.
2. Read [Tiger Style](references/tiger-style.md). Enforce it on authored code; preserve
   unrelated code and existing public interfaces. Record explicit user overrides and
   inherited conflicts; neither establishes full compliance.
3. Load relevant guides below. Verify uncertain/version-sensitive contracts in official
   0.17.0 docs or matching sources; reuse verified signatures, never another release's APIs.
4. Define input contracts, ownership, failure behavior, and resource bounds. Invalid
   external input needs normal error handling, never assertions or `unreachable`.
5. Validate affected paths; report checks, deviations, and limitations. In reviews, give
   locations, consequences, and fixes; separate defects from style and pre-existing issues.
   Claim speedups only with comparable measurements.

## On-demand routing

| Decision | Guide |
| --- | --- |
| Version mismatch, unavailable docs, source conflicts | [Sources](references/version-and-sources.md) |
| Types, errors, arithmetic, pointers, comptime | [Language](references/language.md) |
| Allocation, containers, lifetimes | [Memory](references/memory-containers.md) |
| Files, streams, networking, tasks, cancellation | [I/O and concurrency](references/io-concurrency.md) |
| Layout, SIMD, latency, profiling, benchmarks | [Performance](references/performance.md) |
| Build graph, tests, fuzzing, release modes | [Build and testing](references/build-testing.md) |
| C ABI, binary formats, hardware, freestanding | [Interop](references/interop.md) |
| Editing/evaluating this skill only | [Maintenance](references/skill-maintenance.md) |

Loading tiers: metadata → entrypoint and Tiger contract → topic → exact source or example.
A self-contained edit may need no topic; start with one for implementation, two for
cross-cutting work. Expand for unresolved decisions. Search before reading declarations,
their contracts, and relevant type fields. Avoid whole-file dumps. Retain compact notes
of verified sources, assumptions, and checks; do not reload unchanged guidance.

## Executable examples

Read only when adapting the relevant pattern:

- [Bounded queue](assets/bounded_queue.zig): capacity errors and model-based tests.
- [Containers](assets/std_patterns.zig): borrowed storage and startup failure cleanup.
- [Buffered output](assets/buffered_output.zig): process initialization and writer lifetime.

Examples verify APIs, not whole-program compliance. Audit backend allocation/suspension.
