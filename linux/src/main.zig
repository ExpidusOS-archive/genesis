const std = @import("std");

const c = @cImport({
    @cInclude("flutter_embedder.h");
});

pub fn main() !void {
    var exe_path = [_]u8{0} ** std.fs.MAX_PATH_BYTES;
    _ = try std.fs.selfExePath(&exe_path);

    const libflutterPath = try std.fs.path.joinZ(std.heap.page_allocator, &.{
        std.fs.path.dirname(&exe_path).?,
        "lib",
        "libflutter_engine.so",
    });
    defer std.heap.page_allocator.free(libflutterPath);

    const libflutter = std.c.dlopen(libflutterPath, std.c.RTLD.NOW) orelse std.debug.panic("Failed to load the Flutter Engine: {s}", .{std.c.dlerror().?});
    defer _ = std.c.dlclose(libflutter);

    const getProcAddresses = @as(*const fn ([*c]c.FlutterEngineProcTable) c.FlutterEngineResult, @ptrCast(@alignCast(std.c.dlsym(libflutter, "FlutterEngineGetProcAddresses") orelse @panic("Missing FlutterEngineGetProcAddresses function"))));

    var procTable: c.FlutterEngineProcTable = .{
        .struct_size = @sizeOf(c.FlutterEngineProcTable),
    };

    const result = getProcAddresses(&procTable);

    std.debug.print("Hello, world ({x} {} {})", .{
        getProcAddresses,
        result,
        procTable,
    });
}
