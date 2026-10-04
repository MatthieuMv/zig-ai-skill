const std = @import("std");
const assert = std.debug.assert;

/// Owns its inline storage. Copying duplicates queued values; no pointers escape.
/// A single owner must serialize operations. Capacity failure leaves state unchanged.
pub const BoundedQueue = struct {
    values: [capacity]u64 = undefined,
    read_index: u32 = 0,
    count: u32 = 0,

    // Eight entries demonstrate a fixed admission budget without heap allocation.
    pub const capacity: u32 = 8;

    pub fn push(queue: *BoundedQueue, value: u64) error{Full}!void {
        queue.assert_valid();
        if (queue.count == capacity) return error.Full;

        const write_index = (queue.read_index + queue.count) % capacity;
        assert(write_index < capacity);
        assert(queue.count < capacity);
        queue.values[write_index] = value;
        queue.count += 1;
        queue.assert_valid();
    }

    pub fn pop(queue: *BoundedQueue) ?u64 {
        queue.assert_valid();
        if (queue.count == 0) return null;

        assert(queue.count > 0);
        assert(queue.read_index < capacity);
        const value = queue.values[queue.read_index];
        queue.read_index = (queue.read_index + 1) % capacity;
        queue.count -= 1;
        queue.assert_valid();
        return value;
    }

    fn assert_valid(queue: *const BoundedQueue) void {
        assert(queue.read_index < capacity);
        assert(queue.count <= capacity);
    }
};

test "empty, full, and rejected push preserve FIFO state" {
    // Reject one extra item, then verify every accepted value remains in order.
    var queue: BoundedQueue = .{};
    try std.testing.expectEqual(@as(?u64, null), queue.pop());
    for (0..BoundedQueue.capacity) |index| try queue.push(@intCast(index));

    const previous_read_index = queue.read_index;
    try std.testing.expectError(error.Full, queue.push(999));
    try std.testing.expectEqual(previous_read_index, queue.read_index);
    try std.testing.expectEqual(BoundedQueue.capacity, queue.count);

    for (0..BoundedQueue.capacity) |index| {
        try std.testing.expectEqual(@as(?u64, @intCast(index)), queue.pop());
    }
    try std.testing.expectEqual(@as(?u64, null), queue.pop());
}

test "wraparound reuses consumed slots without reordering" {
    // Retain half the queue while the producer wraps around the end of storage.
    var queue: BoundedQueue = .{};
    for (0..BoundedQueue.capacity) |index| try queue.push(@intCast(index));
    for (0..4) |index| {
        try std.testing.expectEqual(@as(?u64, @intCast(index)), queue.pop());
    }
    for (8..12) |index| try queue.push(@intCast(index));
    for (4..12) |index| {
        try std.testing.expectEqual(@as(?u64, @intCast(index)), queue.pop());
    }
    try std.testing.expectEqual(@as(u32, 0), queue.count);
}

test "bounded operation sequences match a shifting-array model" {
    // Enumerate all 12-operation push/pop sequences, including repeated full/empty cases.
    for (0..4096) |sequence| {
        var queue: BoundedQueue = .{};
        var model: [BoundedQueue.capacity]u64 = undefined;
        var model_count: usize = 0;
        for (0..12) |operation| {
            const push_requested = sequence & (@as(usize, 1) << @intCast(operation)) != 0;
            if (push_requested) {
                if (model_count < model.len) {
                    const value: u64 = @intCast(operation);
                    try queue.push(value);
                    model[model_count] = value;
                    model_count += 1;
                } else {
                    try std.testing.expectError(error.Full, queue.push(@intCast(operation)));
                }
            } else {
                if (model_count > 0) {
                    try std.testing.expectEqual(@as(?u64, model[0]), queue.pop());
                    for (1..model_count) |index| model[index - 1] = model[index];
                    model_count -= 1;
                } else {
                    try std.testing.expectEqual(@as(?u64, null), queue.pop());
                }
            }
            try std.testing.expectEqual(model_count, queue.count);
        }
        for (model[0..model_count]) |value| {
            try std.testing.expectEqual(@as(?u64, value), queue.pop());
        }
        try std.testing.expectEqual(@as(?u64, null), queue.pop());
    }
}
