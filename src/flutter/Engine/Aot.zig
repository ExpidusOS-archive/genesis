const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Manager = @import("Manager.zig");

pub const Data = struct {
    manager: *const Manager,
    value: Extern,

    pub fn destroy(self: *const Data) void {
        assert(self.manager.proc_table.collectAotData != null);
        assert(self.manager.proc_table.collectAotData.?(self.value) == .success);
    }

    pub const Source = union(Type) {
        elf_path: []const u8,

        pub fn toExtern(self: *const Source, alloc: Allocator) Allocator.Error!Source.Extern {
            return .{
                .type = std.meta.activeTag(self.*),
                .value = switch (self.*) {
                    .elf_path => |elf_path| .{ .elf_path = try alloc.dupeZ(u8, elf_path) },
                },
            };
        }

        pub const Type = enum(u8) {
            elf_path,
        };

        pub const Extern = extern struct {
            type: Type,
            value: Value,

            pub const Value = extern union {
                elf_path: [*:0]const u8,
            };

            pub fn destroy(self: *const Source.Extern, alloc: Allocator) void {
                alloc.free(self.value.elf_path[0..(std.mem.len(self.value.elf_path) + 1)]);
            }
        };
    };

    pub const Extern = *opaque {};
};
