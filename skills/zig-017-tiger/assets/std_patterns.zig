const std = @import("std");
const assert = std.debug.assert;

test "borrowed ArrayList storage rejects growth without an allocator" {
    // initBuffer borrows these bytes; no allocator-taking method may touch the list.
    var storage: [2]u32 = undefined;
    var values = std.ArrayList(u32).initBuffer(&storage);
    try values.appendBounded(10);
    try values.appendBounded(20);
    try std.testing.expectError(error.OutOfMemory, values.appendBounded(30));
    try std.testing.expectEqualSlices(u32, &.{ 10, 20 }, values.items);
}

test "owned ArrayList reserves during startup and retains capacity during work" {
    const allocator = std.testing.allocator;

    var values: std.ArrayList(u32) = .empty;
    defer values.deinit(allocator);

    try values.ensureTotalCapacityPrecise(allocator, 2);
    const capacity_initial = values.capacity;
    const pointer_initial = values.items.ptr;
    // Admission is capped at two elements, independent of allocator rounding.
    for (0..2) |index| values.appendAssumeCapacity(@intCast(index));
    try std.testing.expectEqual(capacity_initial, values.capacity);
    try std.testing.expectEqual(pointer_initial, values.items.ptr);
    try std.testing.expectEqualSlices(u32, &.{ 0, 1 }, values.items);
}

test "startup rollback releases the first allocation if the second fails" {
    // Each allocation is failed in turn; the harness checks propagation and leak freedom.
    try std.testing.checkAllAllocationFailures(std.testing.allocator, startup_probe, .{});
}

fn startup_probe(allocator: std.mem.Allocator) !void {
    // The block transfers both buffers together, so errdefer cannot double-free on later errors.
    const buffers = initialized: {
        const source = try allocator.alloc(u8, 32);
        errdefer allocator.free(source);

        const target = try allocator.alloc(u8, 32);
        break :initialized .{ .source = source, .target = target };
    };
    defer allocator.free(buffers.source);
    defer allocator.free(buffers.target);

    // Equal, disjoint allocations establish the copy contract.
    assert(buffers.source.len == buffers.target.len);
    assert(buffers.source.ptr != buffers.target.ptr);
    @memset(buffers.source, 0x5a);
    @memcpy(buffers.target, buffers.source);
    try std.testing.expectEqualSlices(u8, buffers.source, buffers.target);
}
