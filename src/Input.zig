pub const Input = @This();

pub const Special = @import("Input/special.zig").Special;
pub const parse = @import("Input/parse.zig");

key_code: KeyCode,
modifiers: Modifiers = .{},
input_type: InputType = .press,
chord: Chord = .{},

pub const KeyCodeTag = enum {
    text,
    special,
    unknown,
};

pub const KeyCode = union(KeyCodeTag) {
    text: u8,
    special: Special,
    unknown: void,
};

/// What modifiers are applied to the key,
/// in the form specified by
/// Modifiers https://sw.kovidgoyal.net/kitty/keyboard-protocol/#modifiers
pub const Modifiers = packed struct(u8) {
    shift: bool = false,
    alt: bool = false,
    ctrl: bool = false,
    super: bool = false,
    hyper: bool = false,
    meta: bool = false,
    caps_lock: bool = false,
    num_lock: bool = false,
};

pub const InputType = enum(u2) {
    press = 1,
    repeat = 2,
    release = 3,
};

pub const Chord = std.BoundedArray(u8, 16);

const std = @import("std");
