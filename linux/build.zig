const std = @import("std");

fn addArchOption(b: *std.Build) std.Target.Cpu.Arch {
    if (b.option(enum { x64, arm64 }, "arch", "Target architecture as defined by Flutter")) |value| {
        return switch (value) {
            .x64 => .x86_64,
            .arm64 => .aarch64,
        };
    }
    return b.host.result.cpu.arch;
}

fn addBuildType(b: *std.Build) std.builtin.OptimizeMode {
    if (b.option(enum {
        Debug,
        Release,
        RelWithDebInfo,
        MinSizeRel,
    }, "build-type", "Build optimization as defined by CMake")) |value| {
        return switch (value) {
            .Debug => .Debug,
            .Release => .ReleaseSmall,
            .RelWithDebInfo => .ReleaseFast,
            .MinSizeRel => .ReleaseSafe,
        };
    }
    return .Debug;
}

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = addArchOption(b),
        .os_tag = .linux,
        .abi = .gnu,
    });

    const optimize = addBuildType(b);

    const exe = b.addExecutable(.{
        .name = "genesis_shell",
        .root_source_file = .{
            .path = b.pathFromRoot("src/main.zig"),
        },
        .optimize = optimize,
        .target = target,
    });
    b.installArtifact(exe);
}
