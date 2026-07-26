const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zbuffer_module = b.addModule("zbuffer", .{
        .root_source_file = b.path("src/zbuffer.zig"),
    });

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
