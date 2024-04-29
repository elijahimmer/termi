pub const Input = @import("Input.zig");
pub const TermManager = @import("TermManager.zig");
pub const ProgressiveEnhancement = @import("progressive_enhancement.zig").ProgressiveEnhancement;

pub const chars = @import("chars.zig");
pub const utils = @import("utils.zig");

pub const log = std.log.scoped(.libtermi);

const std = @import("std");

test {
    std.testing.refAllDecls(@This());
}
