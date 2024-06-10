const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const engineOut = if (b.option([]const u8, "engine-out", "Name of the engine build to use on host")) |v| v else return;
    const engineOutHost = if (b.option([]const u8, "engine-out-host", "Name of the engine build to use")) |v| v else engineOut;
    const engineSrc = if (b.option([]const u8, "engine-src", "Path to the Flutter Engine source")) |v| v else return;

    const libengine = b.fmt("{s}flutter_engine{s}", .{ target.result.libPrefix(), target.result.os.tag.dynamicLibSuffix() });

    const flutterExe = try b.findProgram(&.{"flutter"}, &.{});

    const platform = b.fmt("{s}-{s}", .{
        @tagName(target.result.os.tag),
        switch (target.result.cpu.arch) {
            .aarch64 => "arm64",
            .x86_64 => "x64",
            else => @panic("Unsupported CPU"),
        },
    });

    const buildMode = switch (optimize) {
        .Debug => "debug",
        .ReleaseSafe => "jit_release",
        .ReleaseFast => "profile",
        .ReleaseSmall => "release",
    };

    const exe = b.addExecutable(.{
        .name = "genesis-shell",
        .root_source_file = .{
            .path = b.pathFromRoot("src/main.zig"),
        },
        .optimize = optimize,
        .target = target,
        .linkage = .dynamic,
        .link_libc = true,
    });

    b.installArtifact(exe);

    const wf = b.addWriteFiles();

    const libenginePath = wf.addCopyFile(.{
        .path = b.pathJoin(&.{ engineSrc, "out", engineOut, libengine }),
    }, libengine);
    b.getInstallStep().dependOn(&b.addInstallLibFile(libenginePath, libengine).step);

    const assemble = std.Build.Step.Run.create(b, "flutter assemble");
    assemble.addArgs(&.{
        flutterExe,
        "assemble",
        "--output",
    });

    const assembleOut = assemble.addOutputFileArg("");

    assemble.addArgs(&.{
        b.fmt("--local-engine-src-path={s}", .{engineSrc}),
        b.fmt("--local-engine={s}", .{engineOut}),
        b.fmt("--local-engine-host={s}", .{engineOutHost}),
        b.fmt("-dTargetPlatform={s}", .{platform}),
        b.fmt("-dBuildMode={s}", .{buildMode}),
        b.fmt("{s}_bundle_{s}_assets", .{ buildMode, platform }),
    });

    b.installDirectory(.{
        .source_dir = .{
            .generated = assembleOut.generated,
        },
        .install_dir = .prefix,
        .install_subdir = "",
        .include_extensions = &.{target.result.os.tag.dynamicLibSuffix()},
    });

    b.installDirectory(.{
        .source_dir = .{
            .generated = assembleOut.generated,
        },
        .install_dir = .lib,
        .install_subdir = b.pathJoin(&.{"data"}),
        .exclude_extensions = &.{ ".last_build_id", target.result.os.tag.dynamicLibSuffix() },
    });
}
