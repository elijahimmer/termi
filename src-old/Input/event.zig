pub const MAX_CHORD_LENGTH = 16;

pub const Input = struct {
    code: Code,
    modifier: InputModifiers = .{},
    event: InputEvent = .press,
    chord: std.BoundedArray(u8, MAX_CHORD_LENGTH),

    const Self = @This();

    /// Prints out the input in termi character format (I didn't just make that up)
    pub fn print(self: *const Self, writer: anytype) @TypeOf(writer).Error!void {
        if (self.event_type != .release) {
            const has_modifiers = self.modifier.any();
            if (has_modifiers) {
                try writer.print("<", .{});
                try self.modifier.print(writer);
                try writer.print("-", .{});
            }

            switch (self.code) {
                .unicode => |*u| try u.print(writer),
                .special => |*s| if (self.event == .press) try writer.print("{s}", .{@tagName(s)}),
                .unknown => try writer.print("unknown({s})", .{self.chord.constSlice()}),
            }

            if (has_modifiers) try writer.print(">", .{});
        }
    }
};

pub const CodeTag = enum {
    unicode,
    special,
    unknown,
};

pub const Code = union(CodeTag) {
    unicode: InputUnicode,
    special: InputSpecial,
    unknown: void,
};

pub const InputUnicode = struct {
    /// the unicode key code
    code: u16,
    /// a alternate key code
    alternate: ?u16 = null,
    /// the unicode code points
    code_points: ?u24 = null,

    const Self = @This();

    pub fn print(self: *const Self, writer: anytype) @TypeOf(writer).Error!void {
        const bytes: u16 = if (self.code_point) |cp| bytes: {
            const upper = @as(u8, @intCast(cp >> 16)); // the most significant 8 bits
            if (upper > 0) writer.writeByte(upper);
            break :bytes @as(u16, @truncate(cp));
        } else if (self.alternate) |a| a else self.code;

        const lower = @as(u8, @truncate(bytes)); // the least significant 8 bits
        const middle = @as(u8, @truncate(bytes >> 8)); // the middle 8 bits.

        if (middle > 0) writer.writeByte(middle);
        writer.writeByte(lower);
    }
};

/// The type of key event (.press is default)
pub const InputEvent = enum(u2) {
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
pub const InputModifiers = packed struct(u8) {
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
    pub fn onlyActive(self: *const Self, tag: InputModifiersTag) bool {
        const num = @as(u8, @bitCast(self.*));

        const bit = (@as(u8, 1) << @intFromEnum(tag));

        return (num & bit) > 0 and (num ^ bit) == 0;
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

pub const InputModifiersTag = enum(u3) {
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
const InputSpecial = input.InputSpecial;

const std = @import("std");
