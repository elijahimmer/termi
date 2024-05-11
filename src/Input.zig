//! This Represents a single input event.

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

/// A single key code, either a text input.
/// Text is a normal character like 'a',
/// Special anything that isn't a normal character,
///     like backspace, delete, function and modifier keys, etc.
/// Unknown is, well, anything that couldn't be parsed into one
///     of the others.
pub const KeyCode = union(KeyCodeTag) {
    text: u8,
    special: Special,
    unknown: void,
};

/// What modifiers are applied to the key, in the form specified by
/// https://sw.kovidgoyal.net/kitty/keyboard-protocol/#modifiers
pub const Modifiers = packed struct(u8) {
    shift: bool = false,
    alt: bool = false,
    ctrl: bool = false,
    super: bool = false,
    hyper: bool = false,
    meta: bool = false,
    caps_lock: bool = false,
    num_lock: bool = false,

    const Self = @This();

    pub fn anyActive(self: Self) bool {
        return @as(u8, @bitCast(self)) > 0;
    }

    /// checks if only `mod` is active
    pub fn onlyActive(self: Self, mod: ModifiersTag) bool {
        return @as(u8, @bitCast(self)) == @as(u8, @intFromEnum(mod));
    }

    /// prints out all the modifiers active.
    pub fn print(self: Self, writer: anytype) @TypeOf(writer).Error!void {
        const strs = [_][]const u8{ "S", "A", "C", "Su", "H", "M", "Cl", "Nl" };
        const vals = [_]bool{ self.shift, self.alt, self.ctrl, self.super, self.hyper, self.meta, self.caps_lock, self.num_lock };

        for (strs, vals) |str, val| {
            if (val) try writer.print("{s}-", .{str});
        }
    }
};

/// A enum with each element acting as the bit mask for that
/// element of Modifiers
pub const ModifiersTag = enum(u8) {
    shift = 1 << 0,
    alt = 1 << 1,
    ctrl = 1 << 2,
    super = 1 << 3,
    hyper = 1 << 4,
    meta = 1 << 5,
    caps_lock = 1 << 6,
    num_lock = 1 << 7,
};

/// The input event type, whether it was pressed or released.
/// .press is the default
pub const InputType = enum(u2) {
    /// default option.
    press = 1,
    repeat = 2,
    release = 3,
};

/// the chord of characters that made the input
/// 32 bytes should be enough
pub const Chord = BoundedArray(u8, 32);

/// print out a string representing the input in the termi style (similar to vim)
/// This shows any modifiers that were pressed down.
pub fn print(self: Input, writer: anytype) @TypeOf(writer).Error!void {
    switch (self.key_code) {
        .text => |text| {
            const anyMods = self.modifiers.anyActive();
            if (anyMods) {
                try writer.print("<", .{});
                try self.modifiers.print(writer);
            }
            try writer.print("{c}", .{text});
            if (anyMods) try writer.print(">", .{});
        },
        .special => |s| try writer.print("{s}", .{@tagName(s)}),
        .unknown => |_| try writer.print("unknown", .{}),
    }
}

const BoundedArray = @import("std").BoundedArray;
