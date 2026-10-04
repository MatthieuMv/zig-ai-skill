# Tiger Style contract

Enforcement baseline: [Tiger Style at 1e40c4c](https://github.com/tigerbeetle/tigerbeetle/blob/1e40c4c876216b4e27d70fa2c45adb47124e2a7b/docs/TIGER_STYLE.md).
Verified 2026-10-04. Apply the full pinned rules; consult the relevant section when this
summary leaves a question unresolved. Reconcile newer upstream changes during maintenance.

- Prioritize safety, performance, then developer experience. Explain decisions.
- No recursion; bound loops, queues, work, and memory. Assert intended nontermination.
- Allocate at startup; no subsequent allocation/reallocation. No added dependencies beyond Zig.
- Prefer fixed-width integers; keep scopes small; handle every error; specify library options.
- Assert contracts and both valid/invalid spaces; average at least two assertions/function;
  pair checks; separate compound assertions; check compile-time relationships.
- Functions ≤70 lines; lines ≤100 columns; four-space indentation; run `zig fmt`.
- Centralize branching/state changes; prefer pure helpers, positive conditions, simple branches.
- Use snake_case functions/variables/files; preserve acronyms; descriptive names, units/qualifiers
  last; callbacks last; named options for same-type/nullable arguments.
- Order fields/types/methods; place main first. Explain rationale and test methodology in prose.
- Avoid duplicate state; use in-place initialization and stable addresses; pass unintended
  >16-byte copies by const pointer; initialize exposed padding; functions must not suspend.
- Estimate resource costs; batch external work; isolate hot loops. Distinguish indexes/counts/sizes
  and specify rounding. Prefer Zig tooling.

Review every changed function against this contract and the applicable upstream sections.
Report unresolved deviations; do not label the result compliant while any remain.

For unresolved decisions, read the upstream subsection: Safety (lifecycle), Naming Things
(API), Cache Invalidation (state/lifetime), Performance (architecture). Reuse consulted
text; if unavailable, report upstream review unverified.

Tiger naming overrides Zig conventions for new application code, never imported APIs.
Keep assertions meaningful; count thresholds do not justify padding. Review semantic
rules manually: formatting and compiled API examples do not certify compliance.
