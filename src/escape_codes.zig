pub const CSI = "\u{1B}[";

pub const Commands = enum {
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

    // common private modes
    cursor_invisible,
    cursor_visible,
    restore_screen,
    save_screen,
    enter_alternate_screen,
    leave_alternate_screen,

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

    /// Kitty's Progressive Enhancement:
    /// https://sw.kovidgoyal.net/kitty/keyboard-protocol/
    progressive_enable,
    progressive_pop,
    progressive_disable,
};

pub fn print_command(writer: anytype, comptime command: Commands, args: anytype) @TypeOf(writer).Error!void {
    switch (command) {
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

        // common private modes
        .enter_alternate_screen => try writer.writeAll(CSI ++ "?1049h"),
        .leave_alternate_screen => try writer.writeAll(CSI ++ "?1049l"),

        // progressive enhancement
        .progressive_enable => try writer.print(CSI ++ ">{}u", args),
        .progressive_pop => try writer.writeAll(CSI ++ "<u"),
        .progressive_disable => try writer.print(CSI ++ "<{}u", args),

        else => @compileError("Command Unimplemented: " ++ @tagName(command)),
    }
}

const std = @import("std");
const testing = std.testing;
