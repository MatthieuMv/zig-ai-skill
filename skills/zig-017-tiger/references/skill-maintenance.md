# Maintaining and evaluating this skill

Read only when changing the skill, not during ordinary Zig implementation.

## Repeatable verification

From the skill root, run `zig build check --summary all` with Zig 0.17.0. This uses only
the toolchain, performs no downloads, and checks embedded local resources, context
budgets, formatting, AST-based function lengths, the four optimization modes, and stdout.
Use writable Zig cache paths in restricted environments. The build targets the host;
this is not cross-platform runtime certification.

`validate.zig` registers resources explicitly: register new linked files there. Its link
checker covers this package's inline Markdown syntax; metadata checks cover its simple
scalar header, not arbitrary YAML. Tests do not prove semantic Tiger compliance, check
remote links, or evaluate an agent's behavior. Validate changed metadata against the
host skill schema as well. Keep validation tooling outside normal agent loading paths.

## Context design

The [Agent Skills specification](https://agentskills.io/specification) separates discovery
metadata, activated instructions, and on-demand resources. This skill uses that structure
with direct links, small topic files, and exact-source lookup instead of bundled manuals.
The tiers describe loading decisions; they do not require nested folders or a chain of
index documents.

[Anthropic's authoring guidance](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
also recommends concise instructions, shallow reference links, and testing real tasks.
Apply those principles here: keep each rule in one authoritative place, route by the
decision the agent must make, and add detail only for demonstrated gaps. Test navigation
as well as wording. Model context is shared with the code and the user's task.

Local design targets, not platform limits: entrypoint under 800 estimated tokens;
ordinary topic under 1,200; usual first read under 2,500 including Tiger and one topic.
Use actual tokenizer counts if available. Byte-count/4 estimates are only rough and
must be labeled as such. A larger guide needs a contents section and targeted search
instructions, or a split along real task boundaries. Do not sacrifice a critical
invariant merely to hit a token budget.

## Evaluation scenarios

| Realistic request | Observable acceptance criteria |
| --- | --- |
| Fix a full bounded queue losing an element | Reads memory/contracts; preserves state on failure; tests wraparound/full/empty; no runtime allocation |
| Port an older stdout example to 0.17.0 | Reads I/O; verifies `Init` and writer interface; compiles/runs; handles flush failure |
| Optimize a parser with attacker-controlled lengths | Reads language/performance; checked lengths/overflow; invalid-input tests; no unsupported speedup claim |
| Use `Io.async` for mutually dependent workers | Reads concurrency; recognizes progress requirement; handles unavailable concurrency and borrowed lifetimes |
| Installed compiler reports 0.18.0-dev | Does not claim 0.17.0 verification or substitute master; continues independent design work |
| Request asks for per-message arena allocation | Identifies style conflict and proposes bounded startup storage; records any explicit user override |
| Add a C ABI packet struct | Reads interop; verifies target layout, endianness, initialized bytes, and ownership |
| Review legacy Zig code without changing it | Reports located defects and consequences; makes no edits; distinguishes inherited style conflicts |

Execute scenarios in a temporary workspace when a skill evaluation is requested.
Judge generated artifacts and command results, not repetition of instructions. Track
which files were read and why; reading all topic guides for a narrow task is a routing
failure. Do not claim independent-agent evaluation unless it actually occurred.

## Update discipline

Keep the target version exact. Recheck public declarations and compile all assets after
changes to version-specific guidance. Record the verification environment and limitations.
Tiger Style's enforcement baseline is pinned in its guide. Compare upstream `main`
deliberately during maintenance; review changes before updating that pin. The baseline
is a verified reference revision, not a claim to be the newest upstream commit.

Validate frontmatter, local links, routing coverage, unfinished scaffolds, and example
behavior. Review assertion relevance and error paths manually. A regex cannot prove
allocation-freedom, memory safety, concurrency correctness, or complete Tiger compliance.

## Authoring check record

On 2026-10-04, using Zig `0.17.0` on x86_64 Linux:

Source provenance: the compiler's bundled `doc/langref.html`, `lib/std`, and `lib/init`
were inspected. The web language reference was inaccessible to the reader and web std
docs exposed only a JavaScript shell; verified release files supplied the API evidence.
Tiger Style was checked against revision `1e40c4c876216b4e27d70fa2c45adb47124e2a7b`.

- Skill-creator's frontmatter/scaffold validator and five native packaging tests passed.
- Corrupted temporary copies correctly failed for broken links, excess context, long lines,
  oversized functions, and a simulated compiler-version mismatch.
- `zig fmt --check assets` passed; example lines stayed within 100 columns and functions
  within 70 lines.
- All six example tests passed in Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
  The queue model covers 4,096 sequences of 12 operations. The allocator harness
  exercises both startup allocation failure points.
- The buffered-output executable emitted its expected message and exited unsuccessfully
  when stdout was redirected to Linux `/dev/full`, verifying write/flush error propagation.
- The revised entrypoint, every ordinary topic, and every ordinary one-topic initial
  loading path passed the context budgets above. Local links and formatting were rechecked.
- Context sizes were estimated with UTF-8 bytes divided by four, not a model tokenizer.

Before broad deployment, evaluate the scenario table with each intended agent/model and
record artifacts, loaded references, and failures. Current checks validate examples and
packaging; they do not establish model-level reliability, benchmark speedups, or universal
portability. Re-run relevant checks after changes.
