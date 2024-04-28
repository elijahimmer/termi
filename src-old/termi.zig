pub const escape_codes = @import("escape_codes.zig");

const term_manager = @import("term_manager.zig");
pub const termManager = term_manager.termManager;
pub const TermManager = term_manager.TermManager;

const progressive_enhancement = @import("progressive_enhancement.zig");
pub const ProgressiveEnhancement = progressive_enhancement.ProgressiveEnhancement;
pub const enhancementStack = progressive_enhancement.enhancementStack;
pub const enhancementStackWithSet = progressive_enhancement.enhancementStackWithSet;
pub const EnhancementStack = progressive_enhancement.EnhancementStack;

pub const Input = @import("Input.zig");

pub const chars = @import("chars.zig");

pub const utils = @import("utils.zig");

test {
    std.testing.refAllDecls(@This());
}

const std = @import("std");
const log = std.log.scoped(.libtermi);
