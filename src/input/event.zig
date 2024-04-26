pub const InputEventTag = enum {
    unicode,
    special,
    unknown,
};

/// unicode represents a single key press, and
/// special is for non-unicode events (not ending in u)
pub const InputEvent = union(InputEventTag) {
    unicode: UnicodeInput,
    special: SpecialInput,
    unknown: void,

    const Self = @This();

    /// Prints out the input in termi character format (I didn't just make that up)
    pub fn print(self: *const Self, writer: anytype) @TypeOf(writer).Error!void {
        switch (self.*) {
            .unicode => |u| try u.print(writer),
            .special => |*s| if (s.event_type == .press) try s.print(writer), // should disable later
            .unknown => try writer.print("unknown", .{}),
        }
    }
};

/// Represents a single key press.
/// CSI unicode-key-code:alternate-key-codes ; modifiers:event-type ; text-as-codepoints u
pub const UnicodeInput = struct {
    /// the unicode key code
    code: u16,
    /// a alternate key code
    alternate: ?u16 = null,
    /// the key modifiers (shift, ctrl, etc.)
    modifier: KeyModifiers = .{},
    /// the event type
    event_type: KeyEventType = .press,
    /// the unicode code points
    code_points: ?u24 = null,

    const Self = @This();

    /// Prints out the input in termi character format (I didn't just make that up)
    pub fn print(self: *const Self, writer: anytype) @TypeOf(writer).Error!void {
        if (self.event_type == .press) {
            if (self.modifier.any()) {
                try writer.print("<", .{});
                try self.modifier.print(writer);
                try writer.print("-", .{});
            }

            if (self.code <= std.math.maxInt(u8)) {
                try writer.print("{c}", .{@as(u8, @intCast(self.code))});
            } else {
                try writer.print("{}", .{self.code});
            }

            if (self.modifier.any()) try writer.print(">", .{});
        }
    }
};

pub const SpecialInput = struct {
    /// the special key pressed
    code: SpecialInputType,
    /// the modifiers applied to the key
    modifier: KeyModifiers = .{},
    /// the type of key event
    event_type: KeyEventType = .press,

    const Self = @This();

    /// Prints out the input code
    pub fn print(self: *const Self, writer: anytype) @TypeOf(writer).Error!void {
        try writer.print("{s}", .{@tagName(self.code)});
    }
};

/// The type of key event (.press is default)
pub const KeyEventType = enum(u2) {
    press = 1,
    repeat = 2,
    release = 3,
};

/// Modifiers https://sw.kovidgoyal.net/kitty/keyboard-protocol/#modifiers
/// shift     0b1         (1)
/// alt       0b10        (2)
/// ctrl      0b100       (4)
/// super     0b1000      (8)
/// hyper     0b10000     (16)
/// meta      0b100000    (32)
/// caps_lock 0b1000000   (64)
/// num_lock  0b10000000  (128)
pub const KeyModifiers = packed struct(u8) {
    shift: bool = false,
    alt: bool = false,
    ctrl: bool = false,
    super: bool = false,
    hyper: bool = false,
    meta: bool = false,
    caps_lock: bool = false,
    num_lock: bool = false,

    const Self = @This();

    /// returns true if that tag is active, and is the only one.
    pub fn onlyActive(self: *const Self, tag: KeyModifiersTag) bool {
        const num = @as(u8, @bitCast(self.*));

        const bit = (1 << @intFromEnum(tag));

        return (num & bit) > 0 and !(num ^ bit) > 0;
    }

    /// returns true if any mods are true
    pub fn any(self: *const Self) bool {
        return @as(u8, @bitCast(self.*)) > 0;
    }

    /// prints out the modifiers names, in order, in skewer-case
    pub fn print(self: *const Self, writer: anytype) @TypeOf(writer).Error!void {
        const names = [_][*:0]const u8{ "S", "A", "C", "Su", "H", "M", "CL", "NL" };
        const mods = [_]bool{ self.shift, self.alt, self.ctrl, self.super, self.hyper, self.meta, self.caps_lock, self.num_lock };

        var printed_before = false;
        for (names, mods) |name, mod| {
            if (mod)
                if (printed_before) {
                    try writer.print("-{s}", .{name});
                } else {
                    try writer.print("{s}", .{name});
                    printed_before = true;
                };
        }
    }
};

pub const KeyModifiersTag = enum(u8) {
    shift = 0,
    alt,
    ctrl,
    super,
    hyper,
    meta,
    caps_lock,
    num_lock,
};

const input = @import("input.zig");
const CsiInput = input.CsiInput;
const SpecialInputType = input.SpecialInputType;

const std = @import("std");
