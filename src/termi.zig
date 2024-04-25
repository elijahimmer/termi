const termi = @This();
test termi {
    std.testing.refAllDeclsRecursive(termi);
}

pub const escape_codes = @import("escape_codes.zig");

const progressive_enhancement = @import("progressive_enhancement.zig");
pub const ProgressiveEnhancement = progressive_enhancement.ProgressiveEnhancement;
pub const enhancementManager = progressive_enhancement.enhancementManager;
pub const enhancementManagerWithSet = progressive_enhancement.enhancementManagerWithSet;
pub const EnhancementManager = progressive_enhancement.EnhancementManager;

pub const read_loop = @import("read_loop.zig");
pub const term_mode = @import("term_mode.zig");

pub const key = @import("key.zig");
pub const Key = key.Key;

pub const chars = @import("chars.zig");

const std = @import("std");
const log = std.log.scoped(.libtermi);
