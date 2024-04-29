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
        return try queryState(writer, reader) != null;
    }

    /// Query the current state from the terminal.
    /// The reader should be empty before, all input before this test will be discarded.
    /// The reader should be the stdin to the writer's stdout, so it actually connects without a infinite loop.
    pub fn queryState(writer: anytype, reader: anytype) (@TypeOf(writer).Error || @TypeOf(reader).NoEofError)!?ProgressiveEnhancement {
        const ReadState = enum {
            normal,
            escaped,
            csi,
            query,
        };

        var read_state = ReadState.normal;
        var read_result: u8 = 0;
        var result: ?ProgressiveEnhancement = null;

        try writer.print(CSI ++ "?u" ++ CSI ++ "c", .{});

        while (true) {
            const char = try reader.readByte();

            // this should be enough of a loop to get it all.
            switch (read_state) {
                .normal => {
                    if (char == chars.ESC) read_state = .escaped;
                },
                .escaped => read_state = if (char == '[') .csi else .normal,
                .csi => read_state = if (char == '?') .query else .normal,
                .query => switch (char) {
                    '0'...'9' => read_result = read_result * 10 + char_to_int(char),
                    'u' => {
                        result = @bitCast(@as(u5, @intCast(read_result -| 1)));
                        read_state = .normal;
                    },
                    'c' => return result,
                    else => read_state = .normal,
                },
            }
        }
    }
};

test {
    @import("std").testing.refAllDecls(@This());
}

const termi = @import("termi.zig");
const char_to_int = termi.utils.char_to_int;
const chars = termi.chars;
const CSI = chars.CSI;

const std = @import("std");
const assert = std.debug.assert;
