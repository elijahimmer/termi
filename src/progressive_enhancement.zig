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
    pub fn pop(self: @This(), writer: anytype) @TypeOf(writer).Error!void {
        self.pop_many_progressive(writer, 1);
    }

    /// pop many buffer stacks
    pub fn pop_many(writer: anytype, count: usize) @TypeOf(writer).Error!void {
        try writer.print(CSI ++ "<{}u", .{count});
    }

    /// Tries to get the current enhancement state from the terminal.
    ///
    /// Assumes the reader is empty before call.
    /// If no response is sent (i.e. it's not supported), waits until there is input.
    ///
    pub fn query_enhancement(writer: anytype, reader: anytype) (@TypeOf(writer).Error || @TypeOf(reader).Error)!void {
        try writer.print(CSI ++ "?u", .{});
        //const bytetry reader.readByte();
    }
};

const CSI = @import("escape_codes.zig").CSI;
const assert = @import("std").debug.assert;
