# Interop, layout, and low-level code

Sources: [0.17.0 reference](https://ziglang.org/documentation/0.17.0/), sections
`C`, `C-Type-Primitives`, `C-Pointers`, `extern-struct`, `packed-struct`, `volatile`,
`Alignment`, `Assembly`, `Targets`, `Freestanding`; inspect actual section ids before
constructing deep links. Relevant [std](https://ziglang.org/documentation/0.17.0/std/)
source includes `mem.zig`, `Io.zig`, and target-specific OS bindings.

## ABI boundaries

Use the documented C calling convention and ABI-compatible types. C `long`, pointer
width, alignment, enum layout, and signedness can vary by target; map from the header's
contract, not a single machine's sizes. Keep translated declarations at a narrow boundary
and expose checked Zig types internally. Inspect 0.17.0 translation/build support before
choosing `@cImport`, translation commands, or generated bindings from memory.

Write down who allocates/frees each pointer, which allocator family applies, whether
null is permitted, and whether callbacks outlive the call. Translate error codes before
entering core logic. A C pointer's permissive type does not make it safe to dereference.
Do not pass a nonterminated slice to an API expecting a C string.

## Bytes and representation

Ordinary structs are not a portable wire format. `extern` follows the target C ABI;
`packed` specifies a bit-oriented representation with its own alignment restrictions.
Neither automatically supplies protocol endianness, validation, or stable cross-platform
layout. Encode/decode fields explicitly and verify length before every access.

Validate enum tags and length/count arithmetic before constructing domain values.
Initialize reserved bytes and transmit only initialized ranges. Do not hash/compare raw
struct padding as a shortcut for logical equality. Add compile-time layout checks only
for a layout actually guaranteed by the chosen representation and target.

## Hardware and freestanding targets

Use volatile access for the documented MMIO need; it does not provide atomicity or an
inter-thread ordering guarantee. Consider device ordering, access width, alignment, and
target barriers separately. Prefer verified builtins over handwritten assembly where
possible. Keep unavoidable assembly small, with correct constraints and clobbers.

Validate without assuming an OS, general allocator, threading backend, or libc exists.
Cross-compile supported targets and execute tests on the actual target or a suitable
emulator when behavior matters. State clearly when verification was compile-only.
