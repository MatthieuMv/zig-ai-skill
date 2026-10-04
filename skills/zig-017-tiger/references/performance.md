# Performance engineering

Use this guide for optimization work or architecture with meaningful resource limits.
Language evidence: [0.17.0 reference](https://ziglang.org/documentation/0.17.0/), especially
`Vectors`, `Result-Location-Semantics`, `setRuntimeSafety`, `setFloatMode`, and overflow
sections. Inspect actual implementation in [std](https://ziglang.org/documentation/0.17.0/std/)
for container growth, buffering, synchronization, and allocator behavior.

## Before implementation

Write the workload and limits: input sizes/distribution, concurrency, throughput,
latency percentile, memory ceiling, and deployment target. Express estimates in units:
bytes moved per request, operations per element, outstanding bytes, and waits per batch.
Separate worst-case bounds from average/amortized complexity. An occasional resize,
rehash, page fault, or cleanup pause can dominate tail latency.

Select an algorithm whose resource use remains acceptable at the admitted maximum.
Avoid optimizing instructions inside an algorithm with unsuitable growth. If batching
is useful, bound both batch size and time spent waiting to fill it; throughput alone
does not justify violating the latency budget.

## Representation and hot paths

Compare dense arrays with pointer-heavy structures against the actual access pattern.
Separate frequently accessed fields from cold metadata. Consider structure-of-arrays
when operations touch the same field across many elements, but measure conversion and
maintenance cost. Minimize bytes read/written, repeated decoding, and unnecessary copies.

Check `@sizeOf`/`@alignOf` and target layout. Do not serialize native structs to save a
copy. Avoid false sharing in independently updated concurrent counters. Do not assume
packed layout is faster: extraction and unaligned access may cost more than saved bytes.

Let ordinary loops provide a baseline. Introduce `@Vector`, unrolling, prefetch, explicit
inlining, or branch hints only with a plausible bottleneck and measurement. Cover tails,
alignment, short inputs, aliasing, and integer/floating-point semantics. A vector type
does not guarantee one particular machine instruction on every target.

## Measurement protocol

1. Preserve a correctness-equivalent baseline and a representative dataset, including
   empty, typical, maximum, and adversarial cases where applicable.
2. Record exact compiler, target, CPU features, optimization mode, input distribution,
   and machine conditions. Build both candidates with the same settings.
3. Keep unrelated setup outside the timed interval; include it when it is part of the
   real operation. Consume results so the compiler cannot remove the work. Use a
   monotonic clock or established harness whose 0.17.0 API has been verified.
4. Repeat runs, account for variance, and report absolute values as well as ratios.
   Measure latency distribution, memory, and throughput appropriate to the objective.
5. Profile or inspect generated code to explain a surprising result. Keep a change
   only when its benefit survives the relevant workload and correctness checks.

Never present a Debug-versus-Release comparison as an algorithmic speedup. Disabling
safety or relaxing floating-point semantics changes the contract; it needs an explicit
decision and evidence. Record unmeasured hypotheses as hypotheses, not performance facts.
