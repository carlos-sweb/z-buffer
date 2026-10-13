const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zbuffer_module = b.addModule("zbuffer", .{
        .root_source_file = b.path("src/zbuffer.zig"),
    });

    const docs_library = b.addLibrary(.{
        .name = "zbuffer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/zbuffer.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const install_docs = b.addInstallDirectory(.{
        .source_dir = docs_library.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const install_docs_index = b.addInstallFile(b.path("docs/index.html"), "index.html");
    const docs_step = b.step("docs", "Generate API documentation and the documentation site");
    docs_step.dependOn(&install_docs.step);
    docs_step.dependOn(&install_docs_index.step);

    const test_step = b.step("test", "Run all tests");

    const test_files = [_][]const u8{
        "tests/array_buffer_test.zig",
        "tests/data_view_test.zig",
        "tests/typed_array_test.zig",
    };

    inline for (test_files) |test_file| {
        const unit_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(test_file),
                .target = target,
                .optimize = optimize,
            }),
        });
        unit_tests.root_module.addImport("zbuffer", zbuffer_module);
        const run_unit_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_unit_tests.step);
    }

    const src_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/zbuffer.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const run_src_tests = b.addRunArtifact(src_tests);
    test_step.dependOn(&run_src_tests.step);

    b.default_step = test_step;
}
