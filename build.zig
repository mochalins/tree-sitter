const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var lib = b.addStaticLibrary(.{
        .name = "tree-sitter",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    lib.addCSourceFile(
        .{ .file = b.path("lib/src/lib.c"), .flags = &.{"-std=c11"} },
    );
    lib.addIncludePath(b.path("lib/include"));
    lib.addIncludePath(b.path("lib/src"));

    var tree_sitter = b.addModule("tree-sitter", .{
        .root_source_file = b.path("lib/binding_zig/"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    tree_sitter.linkLibrary(lib);
    var bindings_test = b.addTest(.{
        .root_source_file = b.path("lib/binding_zig/tree-sitter.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    bindings_test.linkLibrary(lib);

    const test_step = b.step("test", "Runs the Zig bindings test suite.");
    var run = b.addRunArtifact(bindings_test);
    test_step.dependOn(&run.step);

    lib.installHeadersDirectory(b.path("lib/include"), ".", .{});

    b.installArtifact(lib);
}
