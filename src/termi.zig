pub const Input = @import("Input.zig");
pub const TermManager = @import("TermManager.zig");
pub const ProgressiveEnhancement = @import("progressive_enhancement.zig").ProgressiveEnhancement;
pub const Command = @import("command.zig").Command;

pub const chars = @import("chars.zig");
pub const utils = @import("utils.zig");

pub const log = std.log.scoped(.libtermi);

const std = @import("std");

test {
    refAllDeclsRecursive(@This());
}

/// Given a type, recursively references all the declarations inside, so that the semantic analyzer sees them.
/// For deep types, you may use `@setEvalBranchQuota`.
pub fn refAllDeclsRecursive(comptime T: type) void {
    if (!builtin.is_test) return;
    comptime refAllDeclsRecursiveInterior(T, &[0]type{});
}

/// helper function to do the actual recursion for refAllDeclsRecursive
fn refAllDeclsRecursiveInterior(comptime T: type, comptime typeRecord: []const type) void {
    inline for (comptime typeRecord) |r| if (T == r) return;
    inline for (comptime std.meta.declarations(T)) |decl| {
        if (@TypeOf(@field(T, decl.name)) == type) {
            switch (@typeInfo(@field(T, decl.name))) {
                .Struct, .Enum, .Union, .Opaque => {
                    refAllDeclsRecursiveInterior(@field(T, decl.name), typeRecord ++ .{T});
                },
                else => {},
            }
        }
        _ = &@field(T, decl.name);
    }
}

const builtin = @import("builtin");
const allocator = std.testing.allocator;
const math = std.math;
