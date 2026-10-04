const std = @import("std");
const builtin = @import("builtin");

comptime {
    if (!std.mem.eql(u8, builtin.zig_version_string, "0.17.0")) {
        @compileError("Skill verification requires exactly Zig 0.17.0.");
    }
}

pub fn build(builder: *std.Build) void {
    const check = builder.step("check", "Verify skill packaging and native examples");
    builder.default_step = check;

    const formatting = builder.addFmt(.{
        .paths = &.{
            builder.path("assets"),
            builder.path("build.zig"),
            builder.path("validate.zig"),
        },
        .exclude_paths = &.{},
        .check = true,
    });
    check.dependOn(&formatting.step);

    const validation = builder.addTest(.{
        .root_module = builder.createModule(.{
            .root_source_file = builder.path("validate.zig"),
            .target = builder.graph.host,
            .optimize = .Debug,
        }),
    });
    check.dependOn(&builder.addRunArtifact(validation).step);

    // Every example test runs with and without runtime safety checks.
    const modes = [_]std.builtin.OptimizeMode{ .Debug, .ReleaseSafe, .ReleaseFast, .ReleaseSmall };
    for (modes) |mode| {
        for ([_][]const u8{ "assets/bounded_queue.zig", "assets/std_patterns.zig" }) |source| {
            const tests = builder.addTest(.{
                .root_module = builder.createModule(.{
                    .root_source_file = builder.path(source),
                    .target = builder.graph.host,
                    .optimize = mode,
                }),
            });
            check.dependOn(&builder.addRunArtifact(tests).step);
        }
    }

    const output = builder.addExecutable(.{
        .name = "buffered-output-check",
        .root_module = builder.createModule(.{
            .root_source_file = builder.path("assets/buffered_output.zig"),
            .target = builder.graph.host,
            .optimize = .Debug,
        }),
    });
    const run = builder.addRunArtifact(output);
    run.expectStdOutEqual("Zig 0.17.0 buffered output\n");
    check.dependOn(&run.step);
}
