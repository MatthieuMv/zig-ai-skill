# Memory and containers

Sources: language sections [Memory](https://ziglang.org/documentation/0.17.0/#Memory)
and [Lifetime and Ownership](https://ziglang.org/documentation/0.17.0/#Lifetime-and-Ownership);
[standard library](https://ziglang.org/documentation/0.17.0/std/), source files
`mem/Allocator.zig`, `heap.zig`, `array_list.zig`, `hash_map.zig`.

## Design the storage lifecycle

For each buffer, state owner, capacity, initialized range, permitted mutations, and the
event ending its lifetime. Distinguish borrowed input, borrowed output, and transferred
ownership in public documentation. Include failure-path behavior: does a failed operation
leave the previous state intact or require explicit recovery?

Apply the startup-only allocation contract from the mandatory style guide to the whole
call graph. Audit convenience APIs: formatting, parsing, container growth, logging,
task submission, and lazy backend initialization can allocate indirectly. Reserving
application storage alone is insufficient evidence of allocation-free operation.

Choose a fixed array, caller-owned buffer, or initialized pool for runtime work. An
arena is a lifetime strategy, not proof of bounded memory or absence of backing allocations.
A fixed-buffer allocator can bound bytes but still performs allocations; it does not
automatically satisfy a prohibition on runtime allocation. Do not silently introduce
per-request arenas as a style exception.

For startup allocation, accept `std.mem.Allocator` from the caller, report failure, and
make cleanup explicit. Select `DebugAllocator`, `FixedBufferAllocator`, or other exported
implementations by their actual release contracts. Do not recreate a remembered
`GeneralPurposeAllocator` example. Test allocation failures during initialization.

## ArrayList in this release

`std.ArrayList(T)` aliases the allocator-explicit implementation. Start with `.empty`,
reserve with an allocator-taking method during initialization, and call `deinit(allocator)`
when the owned storage's lifetime ends. Ordinary append may grow; capacity must be proven
before an assume-capacity operation. The `Managed` implementation is deprecated.

For borrowed storage, `initBuffer(buffer)` creates an empty list with that capacity.
Its contract forbids calls accepting an allocator, including `deinit(allocator)`.
Use `appendBounded` for a recoverable capacity failure. The backing storage must outlive
the list. See the executable std-patterns asset for these two distinct lifecycles.

Never retain element pointers or slices across a mutating operation without reading its
invalidation contract. Copying a container header does not duplicate its allocation;
it can create two apparent owners. `toOwnedSlice` transfers ownership and may allocate
or move memory; it is not automatically appropriate in a runtime hot path.

## Other data structures

Hash-map managed/unmanaged types are separate choices; do not generalize ArrayList's API
to every container. Verify `put`, capacity reservation, assume-capacity operations,
iterator invalidation, and key ownership in `hash_map.zig`. String keys need stable bytes;
storing a slice does not clone its contents. Account for adversarial collision behavior.

For pools, define exhausted/full behavior and invalid-handle detection. Generation
counters can reject stale references but need a wraparound policy. Separate published
elements from reserved but uninitialized slots. Use a simple reference model to test
insert/remove/reuse sequences and capacity boundaries.

Retain stable storage while tasks or callbacks borrow it. Allocator thread-safety does
not make containers or their payloads thread-safe. Review reset, reuse, teardown, and
partial initialization as carefully as the successful path.
