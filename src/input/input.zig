pub const raw = @import("raw.zig");
pub const RawInputTag = raw.RawInputTag;
pub const RawInput = raw.RawInput;
pub const EscapedInput = raw.EscapedInput;
pub const CsiInput = raw.CsiInput;
pub const read_input = raw.read_input;

pub const event = @import("event.zig");
pub const InputEventTag = event.InputEventTag;
pub const InputEvent = event.InputEvent;
pub const UnicodeInput = event.UnicodeInput;
pub const KeyEventType = event.KeyEventType;
pub const KeyModifiers = event.KeyModifiers;

pub const parse = @import("parse.zig");
pub const parseCsiInput = parse.parseCsiInput;

pub const special_input_type = @import("special_input_type.zig");
pub const SpecialInputType = special_input_type.SpecialInputType;

test {
    std.testing.refAllDecls(@This());
}

const std = @import("std");
