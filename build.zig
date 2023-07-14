const std = @import("std");
const zigcv = @import("libs.zig");
pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const examples = [_]Program{
        .{
            .name = "hello",
            .path = "examples/hello/main.zig",
            .desc = "Show Webcam",
        },
        .{
            .name = "version",
            .path = "examples/version/main.zig",
            .desc = "Print OpenCV Version",
        },
        .{
            .name = "show_image",
            .path = "examples/showimage/main.zig",
            .desc = "Show Image Demo",
        },
        .{
            .name = "face_detection",
            .path = "examples/facedetect/main.zig",
            .desc = "Face Detection Demo",
        },
        .{
            .name = "face_blur",
            .path = "examples/faceblur/main.zig",
            .desc = "Face Detection and Blur Demo",
        },
        .{
            .name = "dnn_detection",
            .path = "examples/dnndetection/main.zig",
            .desc = "DNN Detection Demo",
        },
        .{
            .name = "saveimage",
            .path = "examples/saveimage/main.zig",
            .desc = "Save Image Demo",
        },
        .{
            .name = "detail_enhance",
            .path = "examples/detail_enhance/main.zig",
            .desc = "Detail Enhanced Image Demo",
        },
    };

    const examples_step = b.step("examples", "Builds all the examples");

    for (examples) |ex| {
        const exe = b.addExecutable(.{
            .name = ex.name,
            .root_source_file = std.Build.FileSource.relative(ex.path),
            .target = target,
            .optimize = mode,
        });
        const exe_step = &exe.step;

        b.installArtifact(exe);

        zigcv.link(exe);
        zigcv.addAsPackage(exe);

        const run_cmd = b.addRunArtifact(exe);
        const run_step = b.step(ex.name, ex.desc);
        const artifact_step = &b.addInstallArtifact(exe).step;
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        run_step.dependOn(artifact_step);
        run_step.dependOn(&run_cmd.step);
        examples_step.dependOn(exe_step);
        examples_step.dependOn(artifact_step);
    }

    var tmp_dir = std.testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    const exe_tests = b.addTest(.{
        .name = "exe_tests",
        .root_source_file = std.build.FileSource.relative("src/main.zig"),
        .target = target,
        .optimize = mode,
    });
    zigcv.link(exe_tests);
    zigcv.addAsPackage(exe_tests);

    const test_filter = b.option([]const u8, "test-filter", "Skip tests that do not match filter");
    if (test_filter) |filter| exe_tests.filter = filter;

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);

    const emit_docs = b.option(bool, "docs", "Generate Docs");
    if (emit_docs) |d| {
        if (d) exe_tests.emit_docs = .emit;
    }
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}

const Program = struct {
    name: []const u8,
    path: []const u8,
    desc: []const u8,
    fstage1: bool = false,
};
