const std = @import("std");

pub fn build(b: *std.Build) !void {
    const build_all = b.option(bool, "build-all-targets", "Build all targets in ReleaseSafe mode.") orelse false;
    const strip = b.option(bool, "strip", "Strip debug symbols") orelse false;
    if (build_all) {
        try build_targets(b);
        return;
    }

    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "safepass",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = mode,
            .strip = strip,
            .link_libc = true,
        }),
    });
    exe.addIncludePath(.{.src_path = .{.owner = b, .sub_path = "src"}});
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn build_targets(b: *std.Build) !void {
    const targets: []const std.Target.Query = &.{
        .{ .cpu_arch = .x86_64, .os_tag = .linux },
        .{ .cpu_arch = .aarch64, .os_tag = .linux },
        .{ .cpu_arch = .arm, .os_tag = .linux },
        .{ .cpu_arch = .aarch64, .os_tag = .macos },
        .{ .cpu_arch = .x86_64, .os_tag = .windows },
    };

    for (targets) |t| {
        const target = b.resolveTargetQuery(t);

        // Generate the target name
        const target_name = try t.zigTriple(b.allocator);
        const base = "safepass-";
        
        // Concatenate the base and target name
        const exe_name = try std.mem.concat(std.heap.page_allocator, u8, &.{base, target_name});

        // Create the executable
        const exe = b.addExecutable(.{ 
            .name = exe_name, 
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = .ReleaseFast,
                .strip = true,
                .link_libc = true,
            }) 
        });

        // Ensure the executable is installed
        const target_output = b.addInstallArtifact(exe, .{});

        // Set dependencies
        b.getInstallStep().dependOn(&target_output.step);

        // Free the allocated memory for exe_name
        std.heap.page_allocator.free(exe_name);
    }
}
