# Build and validation

Sources: [0.17.0 language reference](https://ziglang.org/documentation/0.17.0/), sections
`Zig-Test`, `Compilation-Model`, `Zig-Build-System`, `Illegal-Behavior`;
[std](https://ziglang.org/documentation/0.17.0/std/), `Build.zig`, `Build/Module.zig`,
`testing.zig`, `debug.zig`, and the release's `lib/init/build.zig`.

## Build integration

Read existing build steps before adding another runner. In this release, artifacts use
a `root_module`, typically created with `b.createModule`; `b.addModule` exposes a named
module to consumers. Specify or correctly inherit target and optimization for each
module. Do not paste a build script using obsolete artifact-level source options.

An `addTest` artifact needs a run step, usually via `addRunArtifact`, for a named test
step to execute it. Test separately compiled modules deliberately. Building a test
binary or cross-compiling an artifact is not the same as running it. Native execution
cannot establish another target's runtime behavior.

Check `zig build --help` before assuming a project exposes `test` or `-Doptimize`.
Honor its package pin and dependency policy. A manifest's minimum version is not an
exact compiler lock. Avoid adding package downloads or unrelated build tools to solve
a problem already supported by the toolchain.

Reproduce baseline failures before editing; distinguish them from regressions. Preserve
the supported target matrix and public behavior. A toolchain migration is a separate
scope decision, not an implicit side effect of using this skill.

## Validation by risk

For a standalone file, use `zig fmt --check PATH` and `zig test PATH`.
For a project, use its existing format/build/test commands. New executable logic needs
meaningful tests; a comment-only edit does not need an invented suite. Use compile probes
for uncertain signatures rather than changing the production design to match a guess.

Run changed runtime logic in Debug and ReleaseSafe; also test the shipping optimization
mode when different. ReleaseFast/ReleaseSmall can omit safety checks. In particular,
`std.debug.assert` is not a test assertion in those modes: use `std.testing.expect*`
for observable test failures. Do not claim a safety guarantee merely because an unchecked
build did not crash.

Exercise failure contracts: zero/full capacity, malformed and truncated input, overflow,
exact boundaries, exhausted pools, and unchanged state after rejected operations.
For owned allocations use `std.testing.allocator` and, when initialization can fail,
`std.testing.checkAllAllocationFailures`. Its callback must propagate induced OOM and
clean partial state. Do not blanket-catch failures just to make the harness succeed.

Use model/differential tests for complex state machines, and deterministic seeds or
recorded traces to reproduce failures. Fuzz parsers and operation sequences where useful;
verify the current `std.testing.fuzz`/`Smith` API rather than copying an older callback.
Test important generic instantiations because unused declarations may remain unanalyzed.

## Skill assets

When maintaining this skill, run `zig build check` from its root. It checks packaging,
context budgets, formatting, example function/line limits, all four optimization modes,
and expected stdout. This is not a consuming project's test suite or a semantic proof
of Tiger compliance. Ordinary application work uses the application's own checks.

Report the exact checks that ran, their result, any skipped target/mode, and remaining
uncertainty. Include measured benchmark conditions only when measurements were taken.
