const std = @import("std");
const Self = @This();

pub const Manager = @import("Engine/Manager.zig");

pub const Impl = opaque {};
pub const Id = u64;

pub const Aot = struct {
    pub const Data = extern struct {
        pub const Source = extern struct {};
    };
};

pub const Render = struct {
    pub const Config = extern struct {};
};

pub const ProjectArgs = extern struct {};

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

pub const DartObject = extern struct {};

pub const Display = extern struct {
    pub const UpdateType = enum(u8) {};
};

pub const GetProcAddressesFn = *const fn (*ProcTable) callconv(.C) Result;
pub const DataCallback = *const fn () callconv(.C) void;
pub const VoidCallback = *const fn (?*anyopaque) callconv(.C) void;
pub const NativeThreadCallback = *const fn () callconv(.C) void;

pub const ProcTable = extern struct {
    struct_size: usize = @sizeOf(ProcTable),
    createAotData: ?*const fn (*const Aot.Data.Source, *Aot.Data) callconv(.C) Result = null,
    collectAotData: ?*const fn (Aot.Data) callconv(.C) Result = null,
    run: ?*const fn (usize, *const Render.Config, *const ProjectArgs, ?*anyopaque, *Impl) callconv(.C) Result = null,
    shutdown: ?*const fn (*Impl) callconv(.C) Result = null,
    init: ?*const fn (usize, *const Render.Config, *const ProjectArgs, ?*anyopaque, *Impl) callconv(.C) Result = null,
    deinit: ?*const fn (*Impl) callconv(.C) Result = null,
    runInit: ?*const fn (*Impl) callconv(.C) Result = null,
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
    postDartObject: ?*const fn (*Impl, i64, *const DartObject) callconv(.C) Result = null,
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

ptr: *Impl,
id: Id,
manager: *const Manager,
