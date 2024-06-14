const std = @import("std");
const builtin = @import("builtin");
const options = @import("options");
const assert = std.debug.assert;
const fs = std.fs;
const Allocator = std.mem.Allocator;
const Self = @This();

pub const Aot = @import("Engine/Aot.zig");
pub const Dart = @import("Engine/Dart.zig");
pub const Manager = @import("Engine/Manager.zig");
pub const Renderer = @import("Engine/Renderer.zig");

pub const Impl = *opaque {};
pub const Id = u64;

pub const ProjectArgs = struct {
    pub const Extern = extern struct {
        struct_size: usize = @sizeOf(Extern),
        assets_path: [*:0]const u8,
        main_path__unused__: ?[*:0]const u8 = null,
        packages_path__unused__: ?[*:0]const u8 = null,
        icu_data_path: [*:0]const u8,
        cmd_argc: c_int = 0,
        cmd_argv: ?[*:null]?[*:0]const u8 = null,
        platform_message_callback: ?*const fn (*const PlatformMessage, ?*anyopaque) callconv(.C) void = null,
        vm_snapshot_data: ?[*]const u8 = null,
        vm_snapshot_data_size: usize = 0,
        vm_snapshot_instructions: ?[*]const u8 = null,
        vm_snapshot_instructions_size: usize = 0,
        isolate_snapshot_data: ?[*]const u8 = null,
        isolate_snapshot_data_size: usize = 0,
        isolate_snapshot_instructions: ?[*]const u8 = null,
        isolate_snapshot_instructions_size: usize = 0,
        root_isolate_create_callback: ?*const fn (?*anyopaque) callconv(.C) void = null,
        update_semantics_node_callback: ?*const fn (*const SemanticsNode, ?*anyopaque) callconv(.C) void = null,
        update_semantics_custom_action_callback: ?*const fn (*const SemanticsCustomAction, ?*anyopaque) callconv(.C) void = null,
        persistent_cache_path: ?[*:0]const u8 = null,
        is_persistent_cache_read_only: bool = false,
        vsync_callback: ?*const fn (?*anyopaque, *i64) callconv(.C) void = null,
        custom_dart_entrypoint: ?[*:0]const u8 = null,
        custom_task_runners: ?*const CustomTaskRunners = null,
        shutdown_dart_vm_when_done: bool = false,
        compositor: ?*const Compositor = null,
        dart_old_gen_heap_size: i64 = -1,
        aot_data: ?Aot.Data.Extern,
        compute_platform_resolved_locale_callback: ?*const fn ([*]const *Locale, usize) callconv(.C) *const Locale = null,
        dart_entrypoint_argc: c_int = 0,
        dart_entrypoint_argv: ?[*:null]?[*:0]const u8 = null,
        log_message_callback: ?*const fn ([*:0]const u8, [*:0]const u8, ?*anyopaque) callconv(.C) void = null,
        log_tag: ?[*:0]const u8 = null,
        on_pre_engine_restart_callback: ?*const fn (?*anyopaque) callconv(.C) void = null,
        update_semantics_callback: ?*const fn (*const SemanticsUpdate, ?*anyopaque) callconv(.C) void = null,
        update_semantics_callback2: ?*const fn (*const SemanticsUpdate2, ?*anyopaque) callconv(.C) void = null,
        channel_update_callback: ?*const fn (*const ChannelUpdate, ?*anyopaque) callconv(.C) void = null,

        pub const CustomTaskRunners = extern struct {};
        pub const Compositor = extern struct {};
    };
};

pub const SemanticsNode = extern struct {};
pub const SemanticsCustomAction = extern struct {};
pub const SemanticsUpdate = extern struct {};
pub const SemanticsUpdate2 = extern struct {};
pub const ChannelUpdate = extern struct {};

pub const Event = struct {
    pub const WindowMetrics = extern struct {};
    pub const Pointer = extern struct {};
    pub const Key = extern struct {
        pub const Callback = *const fn () callconv(.C) void;
    };
};

pub const PlatformMessage = extern struct {
    pub const ResponseHandle = opaque {};
};

pub const AccessibilityFeature = extern struct {};

pub const SemanticsAction = extern struct {};

pub const Task = extern struct {};

pub const Locale = extern struct {};

pub const Display = extern struct {
    pub const UpdateType = enum(u8) {};
};

pub const PathType = enum {
    engine,
    aot,
    assets,
    icu_data,

    pub fn filename(self: PathType) []const u8 {
        return switch (self) {
            .engine => std.fmt.comptimePrint("{s}flutter_engine{s}", .{ comptime builtin.target.libPrefix(), comptime builtin.os.tag.dynamicLibSuffix() }),
            .aot => std.fmt.comptimePrint("{s}app{s}", .{ comptime builtin.target.libPrefix(), comptime builtin.os.tag.dynamicLibSuffix() }),
            .assets => "flutter_assets",
            .icu_data => "icudtl.dat",
        };
    }
};

pub const GetProcAddressesFn = *const fn (*ProcTable) callconv(.C) Result;
pub const DataCallback = *const fn () callconv(.C) void;
pub const VoidCallback = *const fn (?*anyopaque) callconv(.C) void;
pub const NativeThreadCallback = *const fn () callconv(.C) void;

pub const Version: usize = 1;

pub const ProcTable = extern struct {
    struct_size: usize = @sizeOf(ProcTable),
    createAotData: ?*const fn (*const Aot.Data.Source.Extern, *Aot.Data.Extern) callconv(.C) Result = null,
    collectAotData: ?*const fn (Aot.Data.Extern) callconv(.C) Result = null,
    run: ?*const fn (usize, *const Renderer.Config.Extern, *const ProjectArgs.Extern, ?*anyopaque, *Impl) callconv(.C) Result = null,
    shutdown: ?*const fn (Impl) callconv(.C) Result = null,
    init: ?*const fn (usize, *const Renderer.Config.Extern, *const ProjectArgs.Extern, ?*anyopaque, *Impl) callconv(.C) Result = null,
    deinit: ?*const fn (Impl) callconv(.C) Result = null,
    runInit: ?*const fn (Impl) callconv(.C) Result = null,
    sendWindowMetricsEvent: ?*const fn (*Impl, *const Event.WindowMetrics) callconv(.C) Result = null,
    sendPointerEvent: ?*const fn (*Impl, [*]const Event.Pointer, usize) callconv(.C) Result = null,
    sendKeyEvent: ?*const fn (*Impl, *const Event.Key, Event.Key.Callback, ?*anyopaque) callconv(.C) Result = null,
    sendPlatformMessage: ?*const fn (*Impl, *const PlatformMessage) callconv(.C) Result = null,
    platformMessageCreateResponseHandle: ?*const fn (*Impl, DataCallback, ?*anyopaque, **PlatformMessage.ResponseHandle) callconv(.C) Result = null,
    platformMessageReleaseResponseHandle: ?*const fn (*Impl, *PlatformMessage.ResponseHandle) callconv(.C) Result = null,
    platformMessageSendResponse: ?*const fn (*Impl, *PlatformMessage.ResponseHandle, [*]const u8, usize) callconv(.C) Result = null,
    registerExternalTexture: ?*const fn (*Impl, i64) callconv(.C) Result = null,
    unregisterExternalTexture: ?*const fn (*Impl, i64) callconv(.C) Result = null,
    markExternalTextureFrameAvailable: ?*const fn (*Impl, i64) callconv(.C) Result = null,
    updateSemanticsEnabled: ?*const fn (*Impl, bool) callconv(.C) Result = null,
    updateAccessibilityFeatures: ?*const fn (*Impl, AccessibilityFeature) callconv(.C) Result = null,
    dispatchSemanticsAction: ?*const fn (*Impl, u64, SemanticsAction, [*]const u8, usize) callconv(.C) Result = null,
    onVSync: ?*const fn (*Impl, isize, u64, u64) callconv(.C) Result = null,
    reloadSystemFonts: ?*const fn (*Impl) callconv(.C) Result = null,
    traceEventDurationBegin: ?*const fn (*Impl, [*:0]const u8) callconv(.C) void = null,
    traceEventDurationEnd: ?*const fn (*Impl, [*:0]const u8) callconv(.C) void = null,
    traceEventDurationInstant: ?*const fn (*Impl, [*:0]const u8) callconv(.C) void = null,
    postRenderThreadTask: ?*const fn (*Impl, VoidCallback, ?*anyopaque) callconv(.C) Result = null,
    getCurrentTime: ?*const fn () callconv(.C) u64 = null,
    runTask: ?*const fn (*Impl, *const Task) callconv(.C) Result = null,
    updateLocales: ?*const fn (*Impl, [*]const Locale, usize) callconv(.C) Result = null,
    runsAotCompiledDartCode: ?*const fn () callconv(.C) bool = null,
    postDartObject: ?*const fn (*Impl, i64, *const Dart.Object.Extern) callconv(.C) Result = null,
    notifyLowMemoryWarning: ?*const fn (*Impl) callconv(.C) Result = null,
    postCallbackOnAllNativeThreads: ?*const fn (*Impl, NativeThreadCallback, ?*anyopaque) callconv(.C) Result = null,
    notifyDisplayUpdate: ?*const fn (*Impl, Display.UpdateType, [*]const Display, usize) callconv(.C) Result = null,
    scheduleFrame: ?*const fn (*Impl) callconv(.C) Result = null,
    setNextFrameCallback: ?*const fn (*Impl, VoidCallback, ?*anyopaque) callconv(.C) Result = null,
};

pub const Result = enum(u8) {
    success,
    invalid_lib_ver,
    invalid_args,
    internal_inconsistency,

    pub const Error = error{
        InvalidLibraryVersion,
        InvalidArguments,
        InternalInconsistency,
    };

    pub fn err(self: Result) Result.Error!void {
        return switch (self) {
            .success => {},
            .invalid_lib_ver => Result.Error.InvalidLibraryVersion,
            .invalid_args => Result.Error.InvalidArguments,
            .internal_inconsistency => Result.Error.InternalInconsistency,
        };
    }
};

pub const Error = Result.Error || error{InvalidFunction};

ptr: Impl,
id: Id,
manager: *Manager,

pub fn run(self: *const Self) Error!void {
    return if (self.manager.proc_table.runInit) |func| try func(self.ptr).err() else error.InvalidFunction;
}

pub fn destroy(self: *Self) void {
    assert(self.manager.proc_table.deinit != null);
    assert(self.manager.proc_table.deinit.?(self.ptr) == .success);

    for (self.manager.instances.items, 0..) |item, i| {
        if (item.id == self.id) {
            _ = self.manager.instances.orderedRemove(i);
            break;
        }
    }
}

pub fn getPath(alloc: Allocator, t: PathType) Allocator.Error![]const u8 {
    return try fs.path.join(alloc, &.{
        options.libdir,
        t.filename(),
    });
}
