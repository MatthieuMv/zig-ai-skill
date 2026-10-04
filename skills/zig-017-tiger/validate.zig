const std = @import("std");
const testing = std.testing;
const entry = @embedFile("SKILL.md");
const tiger = @embedFile("references/tiger-style.md");

// Explicit registration makes new local links fail until their resource is included.
const Document = struct { path: []const u8, text: []const u8 };
const documents = [_]Document{
    .{ .path = "SKILL.md", .text = entry },
    .{ .path = "references/tiger-style.md", .text = tiger },
    .{ .path = "references/language.md", .text = @embedFile("references/language.md") },
    .{ .path = "references/interop.md", .text = @embedFile("references/interop.md") },
    .{ .path = "references/performance.md", .text = @embedFile("references/performance.md") },
    .{ .path = "references/build-testing.md", .text = @embedFile("references/build-testing.md") },
    .{
        .path = "references/memory-containers.md",
        .text = @embedFile("references/memory-containers.md"),
    },
    .{
        .path = "references/io-concurrency.md",
        .text = @embedFile("references/io-concurrency.md"),
    },
    .{
        .path = "references/version-and-sources.md",
        .text = @embedFile("references/version-and-sources.md"),
    },
    .{
        .path = "references/skill-maintenance.md",
        .text = @embedFile("references/skill-maintenance.md"),
    },
    .{ .path = "assets/bounded_queue.zig", .text = @embedFile("assets/bounded_queue.zig") },
    .{ .path = "assets/std_patterns.zig", .text = @embedFile("assets/std_patterns.zig") },
    .{ .path = "assets/buffered_output.zig", .text = @embedFile("assets/buffered_output.zig") },
    .{ .path = "build.zig", .text = @embedFile("build.zig") },
    .{ .path = "validate.zig", .text = @embedFile("validate.zig") },
};

test "entrypoint metadata and directly discoverable references" {
    // Check this package's simple scalar metadata, not arbitrary YAML syntax.
    try testing.expect(std.mem.startsWith(u8, entry, "---\nname: zig-017-tiger\ndescription: "));
    const field_start = std.mem.indexOf(u8, entry, "description: ") orelse
        return error.InvalidMetadata;
    const description_start = field_start + 13;
    const description_end = std.mem.indexOfPos(u8, entry, description_start, "\n") orelse
        return error.InvalidMetadata;
    try testing.expect(description_end > description_start);
    try testing.expect(description_end - description_start <= 1024);
    try testing.expect(std.mem.startsWith(u8, entry[description_end..], "\n---\n"));
    try testing.expect(std.mem.count(u8, entry, "\n") < 500);
    for (&documents) |*document| {
        if (!std.mem.startsWith(u8, document.path, "references/")) continue;
        var buffer: [256]u8 = undefined;
        const link = try std.fmt.bufPrint(&buffer, "]({s})", .{document.path});
        try testing.expect(std.mem.indexOf(u8, entry, link) != null);
    }
}

test "local inline Markdown links resolve within registered resources" {
    // URLs are intentionally not fetched: offline validation must be deterministic.
    for (&documents) |*document| {
        if (!std.mem.endsWith(u8, document.path, ".md")) continue;
        var position: usize = 0;
        while (std.mem.indexOfPos(u8, document.text, position, "](")) |start| {
            const end = std.mem.indexOfPos(u8, document.text, start + 2, ")") orelse
                return error.UnclosedMarkdownLink;
            const target = document.text[start + 2 .. end];
            position = end + 1;
            if (std.mem.startsWith(u8, target, "https://")) continue;
            if (!try link_exists(document, target)) {
                std.debug.print("Unresolved link: {s}: {s}\n", .{ document.path, target });
                return error.UnresolvedMarkdownLink;
            }
        }
    }
}

test "link validation rejects missing files and escaping paths" {
    try testing.expect(try link_exists(&documents[0], "references/language.md"));
    try testing.expect(try link_exists(&documents[1], "../SKILL.md"));
    try testing.expect(!try link_exists(&documents[0], "references/missing.md"));
    try testing.expect(!try link_exists(&documents[0], "../SKILL.md"));
    try testing.expect(!try link_exists(&documents[1], "../../SKILL.md"));
}

test "context budgets use labeled UTF-8 byte estimates" {
    // Four bytes/token is an estimate; these bounds are project targets, not model limits.
    try testing.expect(entry.len < 800 * 4);
    const mandatory = entry.len + tiger.len;
    for (&documents) |*document| {
        if (!std.mem.startsWith(u8, document.path, "references/")) continue;
        if (std.mem.eql(u8, document.path, "references/tiger-style.md")) continue;
        if (std.mem.eql(u8, document.path, "references/skill-maintenance.md")) continue;
        try testing.expect(document.text.len < 1200 * 4);
        try testing.expect(mandatory + document.text.len < 2500 * 4);
    }
}

test "Zig examples and build script meet structural style limits" {
    // Parse real syntax; braces inside strings/comments must not alter function lengths.
    for (&documents) |*document| {
        if (!std.mem.endsWith(u8, document.path, ".zig")) continue;
        var lines = std.mem.splitScalar(u8, document.text, '\n');
        while (lines.next()) |line| {
            if (line.len > 100) {
                std.debug.print("Line exceeds 100 columns: {s}\n", .{document.path});
                return error.LineTooLong;
            }
        }
        const source = try testing.allocator.dupeSentinel(u8, document.text, 0);
        defer testing.allocator.free(source);
        var tree = try std.zig.Ast.parse(testing.allocator, source, .{
            .recover = true,
            .mode = .zig,
        });
        defer tree.deinit(testing.allocator);
        try testing.expectEqual(@as(usize, 0), tree.errors.len);
        for (0..tree.nodes.len) |index| {
            const node: std.zig.Ast.Node.Index = @fromBackingInt(@as(u32, @intCast(index)));
            if (tree.nodeTag(node) != .fn_decl) continue;
            const start = tree.tokenStart(tree.firstToken(node));
            const end = tree.tokenStart(tree.lastToken(node));
            if (std.mem.count(u8, source[start..end], "\n") + 1 > 70) {
                std.debug.print("Function exceeds 70 lines: {s}\n", .{document.path});
                return error.FunctionTooLong;
            }
        }
    }
}

fn link_exists(document: *const Document, target: []const u8) !bool {
    std.debug.assert(document.path.len > 0);
    std.debug.assert(!std.mem.startsWith(u8, document.path, "/"));
    if (target.len == 0) return false;
    // Markdown paths are POSIX regardless of the host operating system.
    const resolved = try std.fs.path.resolveAllocPosix(testing.allocator, &.{
        "/skill",
        std.fs.path.dirname(document.path) orelse "",
        target,
    });
    defer testing.allocator.free(resolved);
    if (!std.mem.startsWith(u8, resolved, "/skill/")) return false;
    for (&documents) |*candidate| {
        if (std.mem.eql(u8, resolved[7..], candidate.path)) return true;
    }
    return false;
}
