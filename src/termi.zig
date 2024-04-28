pub const Input = @import("Input.zig");
pub const chars = @import("chars.zig");
pub const utils = @import("utils.zig");

pub const log = std.log.scoped(.libtermi);

pub const ProgressiveEnhancement = @import("progressive_enhancement.zig").ProgressiveEnhancement;

const std = @import("std");

test "Reference All" {
    std.testing.refAllDeclsRecursive(@This());
}
