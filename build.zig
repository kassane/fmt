const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Options
    // const shared = b.option(bool, "Shared", "Build the Shared Library [default: false]") orelse false;
    const tests = b.option(bool, "Tests", "Build tests [default: false]") orelse false;

    const lib = b.addStaticLibrary(.{
        .name = "fmt",
        .target = target,
        .optimize = optimize,
    });
    lib.addCSourceFiles(src, &.{
        "-Wall",
        "-Wextra",
    });
    lib.addIncludePath("include");
    if (optimize == .Debug or optimize == .ReleaseSafe)
        lib.bundle_compiler_rt = true
    else
        lib.strip = true;
    lib.linkLibCpp(); // static-linking LLVM-libcxx

    b.installArtifact(lib);
    b.installDirectory(.{
        .source_dir = "include",
        .install_dir = .header,
        .install_subdir = "",
    });

    if (tests) {
        buildTest(b, .{
            .lib = lib,
            .path = "test/core-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/unicode-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/assert-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/std-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/xchar-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/ostream-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/printf-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/scan-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/ranges-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/color-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/chrono-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/compile-test.cc",
        });
        buildTest(b, .{
            .lib = lib,
            .path = "test/format-test.cc",
        });
    }
}

fn buildTest(b: *std.Build, info: BuildInfo) void {
    const test_exe = b.addExecutable(.{
        .name = info.filename(),
        .optimize = info.lib.optimize,
        .target = info.lib.target,
    });
    test_exe.addIncludePath("include");
    test_exe.addIncludePath("test");
    test_exe.addIncludePath("test/gtest");
    test_exe.addCSourceFile(info.path, &.{
        "-Wall",
        "-Wextra",
        "-Wno-deprecated-declarations",
    });
    test_exe.defineCMacro("_SILENCE_TR1_NAMESPACE_DEPRECATION_WARNING", "1");
    test_exe.defineCMacro("GTEST_HAS_PTHREAD", "0");
    test_exe.addCSourceFiles(&.{
        "test/gtest/gmock-gtest-all.cc",
        "test/gtest-extra.cc",
        "test/test-main.cc",
        "test/util.cc",
    }, &.{});
    test_exe.linkLibrary(info.lib);
    test_exe.linkLibCpp();
    b.installArtifact(test_exe);

    const run_cmd = b.addRunArtifact(test_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(
        b.fmt("{s}", .{info.filename()}),
        b.fmt("Run the {s} test", .{info.filename()}),
    );
    run_step.dependOn(&run_cmd.step);
}

const src = &.{
    "src/format.cc",
    "src/os.cc",
};

const BuildInfo = struct {
    lib: *std.Build.CompileStep,
    path: []const u8,

    fn filename(self: BuildInfo) []const u8 {
        var split = std.mem.split(u8, std.fs.path.basename(self.path), ".");
        return split.first();
    }
};
