# Zig 0.17.0 · Tiger Style

An AI coding skill for writing, reviewing, and optimizing **high-performance Zig 0.17.0**
with **Tiger Style** and explicit ownership, resource bounds, and failure contracts.

The skill guides an agent from design through validation: verify the compiler, consult
the correct APIs, make a focused change, and substantiate correctness and performance.
Its tiered structure keeps detailed guidance out of context until the task needs it.

## Install

Install with the [skills CLI](https://github.com/vercel-labs/skills):

```sh
npx skills add MatthieuMv/zig-ai-skill --skill zig-017-tiger
```

The CLI supports selecting your agent and installation scope. Add `--global` to make
the skill available across projects. Installation requires Node.js and `npx`; compiling
or running the included checks requires **exactly Zig 0.17.0**.

To inspect the repository's available skills before installing:

```sh
npx skills add MatthieuMv/zig-ai-skill --list
```

The skill lives at [`skills/zig-017-tiger`](skills/zig-017-tiger/SKILL.md). For manual
installation, copy that entire directory into your agent's supported skill location.
Keep its references and examples alongside `SKILL.md`.

## Use

Ask your agent to use `zig-017-tiger` and describe the task, constraints, and target.
For example:

> Use zig-017-tiger to implement a bounded queue in Zig 0.17.0. Runtime operations must
> not allocate. Test full capacity, wraparound, and rejected writes.

> Use zig-017-tiger to review this parser for overflow, ownership, and malformed-input
> handling. Report findings without editing files.

> Use zig-017-tiger to optimize this hot loop. Preserve its behavior and compare the
> baseline and candidate under the same workload and build settings.

## What it covers

| Area                | Guidance                                                                                      |
| ------------------- | --------------------------------------------------------------------------------------------- |
| Language            | Types, error unions, arithmetic, pointer safety, comptime, and lazy analysis                  |
| Memory              | Startup allocation, borrowed storage, ownership transfer, cleanup, and container invalidation |
| I/O and concurrency | Explicit `std.Io`, buffered streams, task progress, cancellation, and shared-state lifetimes  |
| Performance         | Resource estimates, data layout, batching, SIMD, profiling, and comparable benchmarks         |
| Build and testing   | Module-based builds, failure injection, release modes, fuzzing, and target validation         |
| Interop             | C ABI boundaries, binary layouts, endianness, MMIO, and freestanding targets                  |

The workflow preserves existing public interfaces, separates inherited problems from
regressions, and keeps review-only requests read-only. Compiler mismatches and unverified
checks are reported explicitly rather than silently changing the target version.

## Tiger Style, enforced

The [mandatory style contract](skills/zig-017-tiger/references/tiger-style.md) uses a
pinned [TigerBeetle reference](https://github.com/tigerbeetle/tigerbeetle/blob/1e40c4c876216b4e27d70fa2c45adb47124e2a7b/docs/TIGER_STYLE.md).
It requires bounded work and memory, startup-only allocation, meaningful assertions,
explicit error handling, and measured performance decisions. It also sets naming and
formatting rules, including 70-line functions and 100-column lines.

These are engineering constraints, not just formatting preferences. Conflicts and explicit
user overrides must be documented; a compiling example is not proof of full compliance.

## Built for efficient context use

The agent loads information in four tiers:

1. **Discovery metadata** identifies when the skill applies.
2. **Entrypoint and Tiger contract** establish the mandatory workflow.
3. **Topic guides** supply only the relevant domain guidance.
4. **Exact sources and examples** resolve specific implementation questions.

The validation suite enforces an entrypoint budget below **800 estimated tokens** and
an ordinary initial load—entrypoint, Tiger contract, and one topic—below **2,500**.
Estimates use UTF-8 bytes divided by four; actual token counts vary by model.

## Verify the skill

From a clone of this repository:

```sh
cd skills/zig-017-tiger
zig build check --summary all
```

The Zig-native suite requires no third-party packages or downloads. It checks metadata,
local links, context budgets, formatting, and function lengths using Zig's AST. Six
example tests run in Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall, alongside five
packaging tests and a buffered-output check.

The examples include a bounded queue checked against a reference model, allocator failure
injection, borrowed container storage, and buffered output. These checks validate the
package and examples; production changes still need project-specific tests and review.
Agent behavior should be evaluated on the models used by your team.

## Sources and maintenance

Language and library guidance is grounded in the official
[Zig 0.17.0 language reference](https://ziglang.org/documentation/0.17.0/) and
[standard-library documentation](https://ziglang.org/documentation/0.17.0/std/), with
the matching toolchain's bundled documentation and source as a fallback.

See the [source-verification guide](skills/zig-017-tiger/references/version-and-sources.md)
for provenance and the [maintenance guide](skills/zig-017-tiger/references/skill-maintenance.md)
for evaluation scenarios and update requirements.

For distribution, skills.sh uses GitHub-hosted skills and discovers installations through
CLI telemetry. See the [skills.sh publication FAQ](https://skills.sh/docs/faq) for its
listing process.
