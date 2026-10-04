# Version and source lookup

## Authority and evidence

Use [Zig 0.17.0 language documentation](https://ziglang.org/documentation/0.17.0/)
for semantics and [0.17.0 standard-library documentation](https://ziglang.org/documentation/0.17.0/std/)
for library contracts. Do not substitute `/master/` or another release.

The library reference is a JavaScript application. A page containing only “Loading” or
search controls provides no evidence about an API. Use its source view or the source
shipped with the verified compiler. For unavailable language pages, use that compiler's
`doc/langref.html`. Report this fallback honestly.

Do not hardcode the author's installation path. Read `zig env` for the active `lib_dir`
and `std_dir`; its output need not be JSON. Locate `doc/langref.html` relative to the
compiler distribution. Package-manager layouts may differ.

Record the selected executable as well as its version: wrappers and `ZIG_LIB_DIR` can
select different installations. Project commands must use the same compiler/source pair.

## Efficient lookup

1. Resolve the public name in `lib/std/std.zig`.
2. Search the mapped file for the declaration, its documentation, and relevant fields
   of the containing type. Identical method names can differ in ownership/allocator
   contracts; reading an entire multi-thousand-line container is unnecessary.
3. Read relevant tests for usage, then compile a minimal probe if ambiguity remains.
4. For language questions, search the HTML's section id and inspect only that section
   in a browser or HTML-aware text reader. Avoid printing the whole reference.

For example, after setting `zig_std_dir` to the verified `std_dir`:

```sh
rg -n 'pub fn ArrayList|pub const Io' "$zig_std_dir/std.zig"
rg -n 'pub fn (initBuffer|appendBounded|deinit)' "$zig_std_dir/array_list.zig"
```

Read a discovered region with `sed -n 'START,ENDp' FILE`, replacing the placeholders.
Search output identifies locations; it does not establish surrounding preconditions.

## High-risk stale assumptions

| Surface | Verify in 0.17.0 |
| --- | --- |
| ArrayList | Public alias, `.empty`, allocator-taking methods, `initBuffer` restrictions |
| Hash maps | Managed versus unmanaged API and capacity guarantees |
| I/O | `std.Io`, passed `Io` instance, reader/writer interfaces, flush/errors |
| Main | `std.process.Init` or `Init.Minimal`, plus valid no-argument entrypoints |
| Concurrency | `Io.async`, `Io.concurrent`, future/group cancellation contracts |
| Build | Module-based artifact construction, target and optimization propagation |
| Allocators | Actual `std.heap` exports and configuration field names |
| Sentinel strings | `Allocator.dupeSentinel`; do not assume older `dupeZ` helpers exist |
| Reflection | Current `@typeInfo` tags and fields, not remembered spellings |

A source/example conflict is a reason to inspect and compile, not to choose whichever
matches memory. Document a reproduced documentation defect separately from application
behavior. Never invent an API to make a guide appear complete.
