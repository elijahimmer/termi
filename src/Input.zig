//! A Input event, with everything you should need
//!
//! Input forms:
//!     Text    <- Just normal text input
//!     Special <- Special input (arrow keys, escape, etc.) and non-unicode keys (function keys, media keys, etc.)
//!     Unknown <- When the input cannot be parsed, so it's, well, unknown
//!
//! Every Form has a modifiers (shift, alt, ctrl, etc),
//!     event type (press, repeat, release),
//!     and the chord (actual input string) that produced it.
//!
//! TODO: support bracketed paste input
//!

pub const Input = @This();

/// All the different input types
code: Code,
/// the modifiers applied to the key
modifier: Modifiers = .{},
/// what type of input event was it
event: Event = .press,
/// the chord that makes up the event
chord: Chord,

/// All the different input types
pub const Code = union(CodeTag) {
    text: Text,
    special: Special,
    unknown: void,
};

/// The type of input code it is
pub const CodeTag = enum {
    text,
    special,
    unknown,
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

/// The type of key event (.press for default)
pub const Event = enum(u2) {
    /// default
    press = 1,
    repeat = 2,
    release = 3,
};

/// The Chord of text that made up the key press.
/// This may need to be increased in size.
pub const Chord = std.BoundedArray(u8, 16);

/// Represents a Unicode character.
/// That character can be up to 3 bytes long
/// (maybe 4, but that's not used)
pub const TextCharacter = std.BoundedArray(u8, 3);

/// Represents a normal character input, like normal printable ASCII
/// and that such.
pub const Text = struct {
    /// the unicode key code
    key_code: TextCharacter,
    ///// a alternate key code
    //alternate: ?TextCharacter = null,
    /// the unicode code points (what to actually display)
    code_points: ?TextCharacter = null,
};

/// Prints out the input in termi character format (I didn't just make that up)
pub fn print(self: Input, writer: anytype) @TypeOf(writer).Error!void {
    if (self.event_type != .release) {
        const has_modifiers = self.modifier.any();
        if (has_modifiers) {
            try writer.print("<", .{});
            try self.modifier.print(writer);
            try writer.print("-", .{});
        }

        switch (self.code) {
            .unicode => |*u| try writer.print("{s}", (if (u.code_points) |cp| cp else u.key_code).constSlice()),
            .special => |*s| if (self.event == .press) try writer.print("{s}", .{@tagName(s)}),
            .unknown => try writer.print("unknown({s})", .{self.chord.constSlice()}),
        }

        if (has_modifiers) try writer.print(">", .{});
    }
}

pub const Special = @import("Input/special.zig").Special;

const std = @import("std");
