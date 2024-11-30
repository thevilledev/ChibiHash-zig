const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the library
    const lib_v1 = b.addStaticLibrary(.{
        .name = "chibihash64_v1",
        .root_source_file = .{ .cwd_relative = "src/chibihash64_v1.zig" },
        .target = target,
        .optimize = optimize,
    });

    const lib_v2 = b.addStaticLibrary(.{
        .name = "chibihash64_v2",
        .root_source_file = .{ .cwd_relative = "src/chibihash64_v2.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Create the module for use as a dependency
    const module_v1 = b.addModule("chibihash64_v1", .{
        .root_source_file = .{ .cwd_relative = "src/chibihash64_v1.zig" },
    });
    const module_v2 = b.addModule("chibihash64_v2", .{
        .root_source_file = .{ .cwd_relative = "src/chibihash64_v2.zig" },
    });
    _ = module_v1;
    _ = module_v2;

    // Install the library
    b.installArtifact(lib_v1);
    b.installArtifact(lib_v2);

    // Create tests
    const v1_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/chibihash64_v1.zig" },
        .target = target,
        .optimize = optimize,
    });
    const v2_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/chibihash64_v2.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_v1_tests = b.addRunArtifact(v1_tests);
    const run_v2_tests = b.addRunArtifact(v2_tests);

    // Create test steps
    const test_step = b.step("test", "Run all library tests");
    test_step.dependOn(&run_v1_tests.step);
    test_step.dependOn(&run_v2_tests.step);

    // Add documentation for both versions
    const lib_v1_docs = b.addInstallDirectory(.{
        .source_dir = lib_v1.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs/v1",
    });
    const lib_v2_docs = b.addInstallDirectory(.{
        .source_dir = lib_v2.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs/v2",
    });

    const docs_step = b.step("docs", "Generate library documentation");
    docs_step.dependOn(&lib_v1_docs.step);
    docs_step.dependOn(&lib_v2_docs.step);
}
