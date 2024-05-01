pub const Command = enum {
    home,
    goto,
    move_up,
    move_down,
    move_right,
    move_left,
    next_line,
    prev_line,
    goto_column,
    get_pos,
    save_pos,
    restore_pos,
    bracketed_paste_set,
    bracketed_paste_unset,

    // common private modes
    cursor_invisible,
    cursor_visible,
    restore_screen,
    save_screen,
    alternate_buffer_enter,
    alternate_buffer_leave,

    /// Entire screen
    erase_screen,
    /// End of Screen
    erase_after,
    /// Beginning of screen
    erase_before,
    /// Erase until end of line
    erase_line_after,
    /// Erase until beginning of line
    erase_line_before,
    /// Erase line
    erase_line,

    const Self = @This();
    pub fn print(comptime self: Self, writer: anytype, args: anytype) @TypeOf(writer).Error!void {
        switch (self) {
            // cursor commands
            .home => try writer.writeAll(CSI ++ "H"),
            .goto => try writer.print(CSI ++ "{};{}H", args),
            .move_up => try writer.print(CSI ++ "{}A", args),
            .move_down => try writer.print(CSI ++ "{}B", args),
            .move_right => try writer.print(CSI ++ "{}C", args),
            .move_left => try writer.print(CSI ++ "{}D", args),
            .next_line => try writer.print(CSI ++ "{}E", args),
            .prev_line => try writer.print(CSI ++ "{}F", args),
            .goto_column => try writer.print(CSI ++ "{}G", args),
            .get_pos => try writer.writeAll(CSI ++ "6n"),
            .save_pos => try writer.writeAll(CSI ++ "s"),
            .restore_pos => try writer.writeAll(CSI ++ "u"),
            .bracketed_paste_set => try writer.writeAll(CSI ++ "?2004h"),
            .bracketed_paste_unset => try writer.writeAll(CSI ++ "?2004l"),

            // common private modes
            .alternate_buffer_enter => try writer.writeAll(CSI ++ "?1049h"),
            .alternate_buffer_leave => try writer.writeAll(CSI ++ "?1049l"),

            else => @compileError("Command Unimplemented: " ++ @tagName(self)),
        }
    }
};

const termi = @import("termi.zig");
const CSI = termi.chars.CSI;
