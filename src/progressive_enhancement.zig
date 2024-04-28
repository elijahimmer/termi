/// Kitty's Progressive Enhancement:
/// https://sw.kovidgoyal.net/kitty/keyboard-protocol/
pub const ProgressiveEnhancement = packed struct(u5) {
    /// Disambiguate escape codes
    disambiguate: bool = false,
    /// Report event types
    event_types: bool = false,
    /// Report alternate keys
    alternate_keys: bool = false,
    /// Report all keys as escape codes
    keys_as_escape_codes: bool = false,
    /// Report associated text
    associated_text: bool = false,

    /// Sets the terminal's current progressive mode.
    /// Should only be used after you have pushed
    pub fn set(self: @This(), writer: anytype) @TypeOf(writer).Error!void {
        try writer.print(CSI ++ "={}u", .{@as(u5, @bitCast(self))});
    }

    /// Pushes a progressive onto the stack.
    /// Should only really be used once, and it should be poped whenever you are done using it.
    pub fn push(self: @This(), writer: anytype) @TypeOf(writer).Error!void {
        try writer.print(CSI ++ ">{}u", .{@as(u5, @bitCast(self))});
    }

    /// disables select progressive enhancements
    pub fn pop(writer: anytype) @TypeOf(writer).Error!void {
        try ProgressiveEnhancement.popMany(writer, 1);
    }

    /// pop many buffer stacks
    pub fn popMany(writer: anytype, count: usize) @TypeOf(writer).Error!void {
        try writer.print(CSI ++ "<{}u", .{count});
    }

    /// query the current progression state.
    /// this will empty the reader until the correct response, so you should to this immediately on program start.
    /// This should be fine in most cases.
    pub fn supported(writer: anytype, reader: anytype) (@TypeOf(writer).Error || @TypeOf(reader).NoEofError)!bool {
        const ReadState = enum {
            normal,
            escaped,
            csi,
            query,
        };

        var read_state = ReadState.normal;
        var result = false;

        try writer.print(CSI ++ "?u", .{});
        try writer.print(CSI ++ "c", .{});

        while (true) {
            const char = try reader.readByte();

            switch (read_state) {
                .normal => {
                    if (char == chars.ESC) read_state = .escaped;
                },
                .escaped => {
                    if (char == '[') read_state = .csi;
                },
                .csi => {
                    if (char == '?') read_state = .query;
                },
                .query => switch (char) {
                    'u' => result = true,
                    'c' => return result,
                    else => {},
                },
            }
        }
    }
};

const termi = @import("termi.zig");
const char_to_int = termi.utils.char_to_int;
const chars = termi.chars;
const CSI = chars.CSI;

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
