const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the library
    const lib = b.addStaticLibrary(.{
        .name = "chibihash64",
        .root_source_file = .{ .cwd_relative = "src/chibihash64.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Create the module for use as a dependency
    const module = b.addModule("chibihash64", .{
        .root_source_file = .{ .cwd_relative = "src/chibihash64.zig" },
    });
    _ = module;

    // Install the library
    b.installArtifact(lib);

    // Create tests
    const main_tests = b.addTest(.{
        .root_source_file = .{ .cwd_relative = "src/chibihash64_test.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    // Create a test step
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    // Add documentation
    const lib_docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const docs_step = b.step("docs", "Generate library documentation");
    docs_step.dependOn(&lib_docs.step);
}
