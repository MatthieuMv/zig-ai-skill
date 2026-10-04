const std = @import("std");
const assert = std.debug.assert;

pub fn main(init: std.process.Init) !void {
    const message = "Zig 0.17.0 buffered output\n";
    var stdout_buffer: [256]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);

    // This message fits in one buffer; the adapter stays alive until flushing completes.
    assert(message.len <= stdout_buffer.len);
    try stdout_file_writer.interface.writeAll(message);
    try stdout_file_writer.interface.flush();
    assert(stdout_file_writer.interface.end == 0);
}
