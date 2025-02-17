//! fmtlib for Zig Package Manager (MVP)
//! Download [Zig v0.11 or higher](https://ziglang.org/download)

const std = @import("std");
const Path = std.Build.LazyPath;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Options
    const shared = b.option(bool, "Shared", "Build the Shared Library [default: false]") orelse false;
    const tests = b.option(bool, "Tests", "Build tests [default: false]") orelse false;

    const lib = if (shared) b.addSharedLibrary(.{
        .name = "fmt",
        .target = target,
        .optimize = optimize,
        .version = .{
            .major = 11,
            .minor = 0,
            .patch = 0,
        },
    }) else b.addStaticLibrary(.{
        .name = "fmt",
        .target = target,
        .optimize = optimize,
    });
    lib.addCSourceFiles(.{
        .files = src,
        .flags = &.{
            "-Wall",
            "-Wextra",
        },
    });
    lib.addIncludePath(b.path("include"));
    if (optimize == .Debug or optimize == .ReleaseSafe)
        lib.bundle_compiler_rt = true
    else
        lib.root_module.strip = true;
    if (lib.linkage == .static)
        lib.pie = true;
    if (lib.rootModuleTarget().abi != .msvc)
        lib.linkLibCpp() // static-linking LLVM-libcxx (all platforms)
    else
        lib.linkLibC();
    lib.installHeadersDirectory(b.path("include"), "", .{});
    b.installArtifact(lib);

    if (tests) {
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/args-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/base-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/unicode-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/assert-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/std-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/xchar-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/ostream-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/printf-test.cc",
        });
        // buildTest(b, .{
        //     .optimize = optimize,
        //     .target = target,
        //     .lib = lib,
        //     .path = "test/scan-test.cc",
        // });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/ranges-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/color-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/chrono-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/compile-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/compile-fp-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/format-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/os-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/noexception-test.cc",
        });
        buildTest(b, .{
            .optimize = optimize,
            .target = target,
            .lib = lib,
            .path = "test/posix-mock-test.cc",
        });
        // don't work
        // buildTest(b, .{
        //     .optimize = optimize,
        //     .target = target,
        //     .lib = lib,
        //     .path = "test/module-test.cc",
        // });
    }
}

fn buildTest(b: *std.Build, info: BuildInfo) void {
    const test_exe = b.addExecutable(.{
        .name = info.filename(),
        .optimize = info.optimize,
        .target = info.target,
    });
    test_exe.addIncludePath(b.path("include"));
    test_exe.addIncludePath(b.path("test"));
    test_exe.addIncludePath(b.path("test/gtest"));
    test_exe.addCSourceFile(.{
        .file = b.path(info.path),
        .flags = &.{},
    });
    test_exe.addCSourceFiles(.{
        .files = test_src,
        .flags = &.{
            "-Wall",
            "-Wextra",
            "-Wno-deprecated-declarations",
        },
    });
    test_exe.defineCMacro("_SILENCE_TR1_NAMESPACE_DEPRECATION_WARNING", "1");
    test_exe.defineCMacro("GTEST_HAS_PTHREAD", "0");
    test_exe.linkLibrary(info.lib);
    if (test_exe.rootModuleTarget().abi != .msvc)
        test_exe.linkLibCpp()
    else
        test_exe.linkLibC();
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

const src: []const []const u8 = &.{
    "src/format.cc",
    "src/os.cc",
};
const test_src: []const []const u8 = &.{
    "test/gtest/gmock-gtest-all.cc",
    "test/gtest-extra.cc",
    "test/enforce-checks-test.cc",
    "test/util.cc",
};

const BuildInfo = struct {
    lib: *std.Build.Step.Compile,
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
    path: []const u8,

    fn filename(self: BuildInfo) []const u8 {
        var split = std.mem.splitSequence(u8, std.fs.path.basename(self.path), ".");
        return split.first();
    }
};
