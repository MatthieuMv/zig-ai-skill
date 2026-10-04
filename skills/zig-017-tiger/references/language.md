# Language and contracts

Source: [0.17.0 language reference](https://ziglang.org/documentation/0.17.0/).
Search section ids: `Pointers`, `Slices`, `Optionals`, `Errors`, `defer`, `errdefer`,
`Integer-Overflow`, `Illegal-Behavior`, `comptime`, `Result-Location-Semantics`, `Vectors`.
Use the matching bundled `doc/langref.html` when necessary.

## Types and ownership boundaries

Choose representations that exclude invalid states: an enum for alternatives, a tagged
union for payload alternatives, an optional for absence, and an error union for failure.
Do not encode all four concepts as integers with undocumented sentinel values. Use
concrete parameter types unless generic variation is part of the actual contract.

Differentiate `*T`, `*[N]T`, `[]T`, `[*]T`, and sentinel-terminated forms. A slice carries
length, not ownership. `const slice` prevents rebinding; `[]const T` restricts element
mutation through that view. Neither extends lifetime. A sentinel is an additional
contract, not something supplied by casting arbitrary bytes.

Use `usize` where Zig's indexing/allocation APIs require it, with checked conversion
at a boundary to fixed-width domain fields. Keep the external/wire width independent
of pointer size. Check a value before narrowing with `@intCast`; do not truncate to
silence the compiler unless discarded bits are explicitly part of the algorithm.

## Error paths

Choose a documented error set for a public boundary; inferred sets are useful internally.
Propagate with `try` when the caller owns recovery. Use `catch` to implement an actual
policy, preserving actionable information. Avoid broad `anyerror` unless required by
a genuine abstraction boundary. Never use `catch unreachable` for resource exhaustion,
bad input, failed I/O, or cancellation.

Register `defer` immediately after acquisition. Use `errdefer` for partially constructed
objects whose successful return transfers ownership. Check cleanup scope carefully:
an `errdefer` inside a block only covers error exits from that block. Release exactly
once after all aliases and asynchronous users have stopped.

Keep expected invalid input as a checked branch returning an error. Assertions can be
optimized into assumptions: they are not a reliable release-mode validation mechanism.
For an internal invariant that must terminate in every build, use an explicitly chosen,
verified crash path or safety policy. Never put required side effects in an assertion.

## Arithmetic and memory safety

Check size calculations before allocating or slicing. For an offset and length bounded
by a buffer, first validate `offset <= buffer.len`, then compare `length` with
`buffer.len - offset`; an unchecked `offset + length` may already overflow.

Choose ordinary, wrapping, saturating, or overflow-reporting arithmetic intentionally.
For protocol lengths and capacities, reject overflow instead of accepting wraparound.
Specify signed division and rounding deliberately. Test narrowing, zero divisors, and
boundary values. SIMD arithmetic follows its own element/type rules: read before assuming.

`undefined` is uninitialized storage, not a value or zero-fill shortcut. Every byte read
must have been written, including bytes later sent to another process. Pointer casts
do not prove alignment, lifetime, provenance, or legal aliasing. `@alignCast` checks an
alignment claim; it does not align the underlying allocation. `@memcpy` requires its
documented nonoverlap contract; use an overlap-safe operation where appropriate.

## Compile time and abstraction

Use `comptime` to establish type/size constraints or specialize a measured hot path.
Bound specialization count and generated code size. Ordinary loops are preferable
unless `inline for` is needed for compile-time semantics or supported by measurement.
Do not add `anytype`, reflection, or inline expansion merely to avoid naming a type.

Zig analyzes declarations lazily. Exercise the generic types, branches, and exported
entrypoints that matter; a passing test of unrelated code proves little about them.
Check result-location semantics before assuming a large value avoids copies or that a
self-referential value remains at its original address after return/assignment.
