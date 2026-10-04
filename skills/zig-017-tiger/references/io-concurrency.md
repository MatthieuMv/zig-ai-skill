# I/O and concurrency

Source: [0.17.0 std documentation](https://ziglang.org/documentation/0.17.0/std/).
Search only the relevant declaration: entrypoints in `process.zig`; tasks/cancellation
in `Io.zig`; file adapters in `Io/File.zig`; stream contracts in `Io/Reader.zig` or
`Io/Writer.zig`; networking in `Io/net.zig`; direct threads/atomics in `Thread.zig` or
`atomic.zig`. Inspect the selected backend only when its behavior affects the contract.

## Explicit I/O context

This release exposes `std.Io`. `std.process.Init` can supply `init.io`, startup allocators,
arguments, and environment. Other valid entrypoint forms exist; preserve the repository's
choice. Pass the I/O capability into functions that need it instead of assuming global
filesystem, socket, or event-loop APIs from earlier releases.

Use `Io.File.reader`/`writer` or their documented constructors, caller-owned buffers,
and the reader/writer interfaces. Keep the file adapter and its buffer alive while the
interface is used. Returning a pointer to a local adapter is a dangling reference.
The buffered-output asset is a compiled minimal example, not a complete server skeleton.

Handle short reads, EOF, partial writes, interruption/cancellation where exposed, and
flush failures. Call an error-returning flush on the success path; `defer` cannot propagate
a failure with `try`. A writer flush is not a durability guarantee: persistent storage
requires the appropriate verified synchronization protocol. Preserve framing across
buffer boundaries and define size limits before reading untrusted lengths.

Convenient whole-file or formatted-output APIs may allocate. Check implementation and
backend contracts before promising bounded resource use. Bound inbound buffering,
outstanding requests, and retries; decide admission/backpressure before accepting work.

## Scheduling and lifetime

`Io.async` may run the function immediately and does not guarantee independent progress.
Do not use it for work that must execute concurrently to avoid deadlock. `Io.concurrent`
provides stronger progress guarantees but can fail with `ConcurrencyUnavailable`.
Handle that error according to the operation's real semantics, not by choosing a
fallback that would deadlock. These are library functions, not the old language async syntax.

Own every future/group and its argument storage. Await or cancel as required before
releasing borrowed state. In this release `Future.cancel` requests cancellation and
waits for the result; it is not a fire-and-forget kill operation. Cancellation is
cooperative at documented cancellation points. A task with no such points may continue
to completion, so cancellation alone does not establish a response-time bound.

Do not swallow `error.Canceled`. The request is signaled at the next cancellation point
and is not repeatedly re-signaled automatically. Inspect `CancelProtection`/`recancel`
only when cleanup actually needs deferred cancellation. Check future/group thread-safety
and resource-allocation behavior; do not infer either from an API's name.

## Shared state

Keep state transitions separate from waiting and external interaction. An invariant
checked before an I/O call may need revalidation afterward if other tasks can mutate
the same state. A synchronous-looking call may suspend through its backend. Keep state
transitions nonsuspending and audit the I/O boundary separately. A required suspending
backend conflicts with strict Tiger Style: disclose that conflict; only an explicit user
override can accept it, and the result must not be labeled fully compliant.

Use the simplest synchronization that establishes ownership. For an atomic algorithm,
write the publication/lifetime argument and happens-before relation before choosing
memory orders. `volatile` is not synchronization. A passing stress test does not prove
an algorithm race-free. Check shutdown, cancellation, queue exhaustion, and teardown
with active producers/consumers, not just throughput under steady load.
