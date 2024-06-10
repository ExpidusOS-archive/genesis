const std = @import("std");
const Allocator = std.mem.Allocator;
const Engine = @import("../Engine.zig");

pub const Object = union(Type) {
    null: void,
    bool: bool,
    i32: i32,
    i64: i64,
    f64: f64,
    string: *String,
    buffer: Buffer,

    pub fn create(alloc: Allocator, value: anytype) Allocator.Error!Object {
        const T = @TypeOf(value);

        return switch (@typeInfo(T)) {
            .Null => .null,
            .Bool => .{ .bool = value },
            .Int => |i| if (i.bits > 32) .{ .i64 = value } else .{ .i32 = value },
            .Float => .{ .f64 = value },
            .Pointer => switch (T) {
                []const u8 => .{ .string = try String.create(alloc, value) },
                else => .{ .buffer = try Buffer.create(alloc, value) },
            },
            else => @compileError("Unsupported type " ++ @typeName(T)),
        };
    }

    pub fn toExtern(self: *const Object) Extern {
        return .{
            .type = std.meta.activeTag(self),
            .value = switch (self) {
                .string => |s| .{ .string = s.valueZ },
                .buffer => |b| .{ .buffer = &b.value },
                .null => .{},
                inline else => |v| @unionInit(Extern.Value, std.meta.activeTag(self), v),
            },
        };
    }

    pub fn destroy(self: *Object) void {
        switch (self) {
            .string => |s| s.destroy(),
            .buffer => |b| b.destroy(),
            else => {},
        }
    }

    pub const String = struct {
        allocator: Allocator,
        value: []const u8,
        valueZ: [*:0]const u8,

        pub fn create(alloc: Allocator, value: []const u8) Allocator.Error!*String {
            const self = try alloc.create(String);
            errdefer alloc.destroy(self);

            const v = try alloc.dupe(value);
            errdefer alloc.free(v);

            const vz = try alloc.dupeZ(value);
            errdefer alloc.free(vz);

            self.* = .{
                .allocator = alloc,
                .value = v,
                .valueZ = vz,
            };
            return self;
        }

        pub fn destroy(self: *String) void {
            self.allocator.free(self.value);
            self.allocator.free(self.valueZ);
            self.allocator.destroy(self);
        }
    };

    pub const Buffer = struct {
        allocator: Allocator,
        value: Extern.Buffer,

        fn collect(data: ?*anyopaque) void {
            const self: *Buffer = @ptrCast(@alignCast(data.?));
            self.destroy();
        }

        pub fn create(alloc: Allocator, ptr: anyopaque) Allocator.Error!*Buffer {
            const bytes = try alloc.dupe(std.mem.asBytes(ptr));
            errdefer alloc.free(bytes);

            const self = try alloc.create(Buffer);
            errdefer alloc.destroy(self);

            self.* = .{
                .allocator = alloc,
                .value = .{
                    .user_data = self,
                    .collect = collect,
                    .buffer = bytes.ptr,
                    .size = bytes.len,
                },
            };
        }

        pub fn destroy(self: *Buffer) void {
            self.allocator.free(self.value.buffer[0..self.value.size]);
            self.allocator.destroy(self);
        }
    };

    pub const Type = enum(u8) {
        null,
        bool,
        i32,
        i64,
        f64,
        string,
        buffer,

        pub fn fromZig(comptime T: type) Type {
            return switch (@typeInfo(T)) {
                .Null => .null,
                .Bool => .bool,
                .Int => |i| if (i.bits > 32) .i64 else .i32,
                .Float => .f64,
                .Pointer => switch (T) {
                    []const u8 => .string,
                    else => .buffer,
                },
                else => @compileError("Unsupported type " ++ @typeName(T)),
            };
        }
    };

    pub const Extern = extern struct {
        type: Type,
        value: Value,

        pub const Buffer = extern struct {
            struct_size: usize = @sizeOf(Extern.Buffer),
            user_data: ?*anyopaque = null,
            collect: ?Engine.VoidCallback = null,
            buffer: [*]const u8,
            size: usize = 0,
        };

        pub const Value = extern union {
            bool: bool,
            i32: i32,
            i64: i64,
            f64: f64,
            string: [*:0]const u8,
            buffer: Extern.Buffer,
            null: void,
        };
    };
};
