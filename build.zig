const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ----------------------------
    // Library
    // ----------------------------
    const lib = b.addSharedLibrary(.{
        .name = "quack",
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    // Allow Zig to find and parse the bridge C ABI
    lib.addIncludePath(.{ .path = "src/include" });
    // Allow Zig to compile the C++ bridge
    lib.addCSourceFiles(.{
        .files = &.{
            "src/bridge.cpp",
        },
    });
    // We can link against libc & libc++ provided in the  Nix build environment
    lib.linkLibC();
    // Footguns for Zig linking against libcxx
    // https://github.com/ziglang/zig/blob/e1ca6946bee3acf9cbdf6e5ea30fa2d55304365d/build.zig#L369
    lib.linkSystemLibrary("c++");
    // Link against the version of libduckdb built by the Nix derivation
    lib.linkSystemLibrary("duckdb");

    // Use the DuckDB filename convention `myextension.duckdb_extension`
    const install_lib = b.addInstallArtifact(
        lib,
        .{ .dest_sub_path = "quack.duckdb_extension" },
    );
    b.getInstallStep().dependOn(&install_lib.step);

    // ----------------------------
    // Tests
    // ----------------------------
    const lib_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.addIncludePath(.{ .path = "src/include" });
    lib_unit_tests.addCSourceFiles(.{
        .files = &.{
            "src/bridge.cpp",
        },
    });
    lib_unit_tests.linkLibC();
    // We can link to libc++ within a Nix build environment
    // https://github.com/ziglang/zig/blob/e1ca6946bee3acf9cbdf6e5ea30fa2d55304365d/build.zig#L369
    lib_unit_tests.linkSystemLibrary("c++");
    lib_unit_tests.linkSystemLibrary("duckdb");
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
