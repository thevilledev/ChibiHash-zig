const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create modules for the libraries
    const module_v1 = b.createModule(.{
        .root_source_file = b.path("src/chibihash64_v1.zig"),
        .target = target,
        .optimize = optimize,
    });
    const module_v2 = b.createModule(.{
        .root_source_file = b.path("src/chibihash64_v2.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create the libraries
    const lib_v1 = b.addLibrary(.{
        .name = "chibihash64_v1",
        .root_module = module_v1,
        .linkage = .static,
    });
    const lib_v2 = b.addLibrary(.{
        .name = "chibihash64_v2",
        .root_module = module_v2,
        .linkage = .static,
    });

    // Install the libraries
    b.installArtifact(lib_v1);
    b.installArtifact(lib_v2);

    // Create test modules
    const test_module_v1 = b.createModule(.{
        .root_source_file = b.path("src/chibihash64_v1.zig"),
        .target = target,
        .optimize = optimize,
    });
    const test_module_v2 = b.createModule(.{
        .root_source_file = b.path("src/chibihash64_v2.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Create tests
    const v1_tests = b.addTest(.{
        .root_module = test_module_v1,
    });
    const v2_tests = b.addTest(.{
        .root_module = test_module_v2,
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

    // Export modules for use as dependencies
    _ = b.addModule("chibihash64_v1", .{
        .root_source_file = b.path("src/chibihash64_v1.zig"),
    });
    _ = b.addModule("chibihash64_v2", .{
        .root_source_file = b.path("src/chibihash64_v2.zig"),
    });

    // Create example module
    const example_module = b.createModule(.{
        .root_source_file = b.path("example/example.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add module dependencies to example
    example_module.addImport("chibihash64_v1", module_v1);
    example_module.addImport("chibihash64_v2", module_v2);

    // Create example executable
    const example = b.addExecutable(.{
        .name = "example",
        .root_module = example_module,
    });

    // Install the example
    b.installArtifact(example);

    // Create a run step for the example
    const run_example = b.addRunArtifact(example);
    const run_step = b.step("run-example", "Run the example program");
    run_step.dependOn(&run_example.step);
}
