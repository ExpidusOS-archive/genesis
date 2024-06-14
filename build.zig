const std = @import("std");

const FlutterAssembleOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    engineSrc: []const u8,
    engineOut: []const u8,
    engineOutHost: []const u8,
};

fn flutterAssemble(b: *std.Build, options: FlutterAssembleOptions) std.Build.LazyPath {
    const flutterExe = b.findProgram(&.{"flutter"}, &.{}) catch |e| @panic(@errorName(e));

    const platform = b.fmt("{s}-{s}", .{
        @tagName(options.target.result.os.tag),
        switch (options.target.result.cpu.arch) {
            .aarch64 => "arm64",
            .x86_64 => "x64",
            else => @panic("Unsupported CPU"),
        },
    });

    const buildMode = switch (options.optimize) {
        .Debug => "debug",
        .ReleaseSafe => "jit_release",
        .ReleaseFast => "profile",
        .ReleaseSmall => "release",
    };

    const target = b.fmt("{s}_bundle_{s}_assets", .{ buildMode, platform });

    const assemble = std.Build.Step.Run.create(b, "flutter assemble");
    assemble.addArgs(&.{
        flutterExe,
        "assemble",
        "--output",
    });

    const out = assemble.addOutputFileArg(target);

    assemble.addArgs(&.{
        b.fmt("--local-engine-src-path={s}", .{options.engineSrc}),
        b.fmt("--local-engine={s}", .{options.engineOut}),
        b.fmt("--local-engine-host={s}", .{options.engineOutHost}),
        b.fmt("-dTargetPlatform={s}", .{platform}),
        b.fmt("-dBuildMode={s}", .{buildMode}),
        target,
    });
    return out;
}

fn readFile(b: *std.Build, path: []const u8) []const u8 {
    var file = std.fs.openFileAbsolute(path, .{}) catch |e| @panic(@errorName(e));
    defer file.close();

    const metadata = file.metadata() catch |e| @panic(@errorName(e));
    return file.readToEndAlloc(b.allocator, metadata.size()) catch |e| @panic(@errorName(e));
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const engineOut = if (b.option([]const u8, "engine-out", "Name of the engine build to use on host")) |v| v else return;
    const engineOutHost = if (b.option([]const u8, "engine-out-host", "Name of the engine build to use")) |v| v else engineOut;
    const engineSrc = if (b.option([]const u8, "engine-src", "Path to the Flutter Engine source")) |v| v else return;

    const libengineName = b.fmt("{s}flutter_engine{s}", .{ target.result.libPrefix(), target.result.os.tag.dynamicLibSuffix() });

    const options = b.addOptions();
    options.addOption([]const u8, "libdir", b.getInstallPath(.lib, "genesis-shell"));

    const exe = b.addExecutable(.{
        .name = "genesis-shell",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
        .linkage = .dynamic,
        .link_libc = true,
    });

    exe.root_module.addOptions("options", options);
    b.installArtifact(exe);

    const wf = b.addWriteFiles();

    const icudtl = wf.add("icudtl.dat", readFile(b, b.pathJoin(&.{ engineSrc, "out", engineOut, "icudtl.dat" })));
    b.getInstallStep().dependOn(&b.addInstallLibFile(icudtl, b.pathJoin(&.{ "genesis-shell", "icudtl.dat" })).step);

    const libengine = wf.add(libengineName, readFile(b, b.pathJoin(&.{ engineSrc, "out", engineOut, libengineName })));
    b.getInstallStep().dependOn(&b.addInstallLibFile(libengine, b.pathJoin(&.{ "genesis-shell", libengineName })).step);

    const assembleOut = flutterAssemble(b, .{
        .target = target,
        .optimize = optimize,
        .engineSrc = engineSrc,
        .engineOut = engineOut,
        .engineOutHost = engineOutHost,
    });

    b.installDirectory(.{
        .source_dir = .{ .generated = .{
            .file = assembleOut.generated.file,
            .sub_path = "flutter_assets",
        } },
        .install_dir = .lib,
        .install_subdir = b.pathJoin(&.{ "genesis-shell", "flutter_assets" }),
    });

    if (optimize == .ReleaseSmall) {
        b.installDirectory(.{
            .source_dir = .{ .generated = .{
                .file = assembleOut.generated.file,
                .sub_path = "lib",
            } },
            .install_dir = .lib,
            .install_subdir = "genesis-shell",
        });
    }
}
