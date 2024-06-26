/// the CSI modifier
pub const CSI = [_]u8{ ESC, '[' };
/// the SS3 Modifier
pub const SS3 = [_]u8{ ESC, 'O' };

pub const NULL = 0;
pub const SOH = 1;
pub const STX = 2;
pub const ETX = 3;
pub const EOT = 4;
pub const ENQ = 5;
pub const ACK = 6;
pub const BEL = 7;
pub const BS = 8;
pub const TAB = 9;
pub const LF = 10;
pub const VT = 11;
pub const FF = 12;
pub const CR = 13;
pub const SO = 14;
pub const SI = 15;
pub const DLE = 16;
pub const DC1 = 17;
pub const DC2 = 18;
pub const DC3 = 19;
pub const DC4 = 20;
pub const NAK = 21;
pub const SYN = 22;
pub const ETB = 23;
pub const CAN = 24;
pub const EM = 25;
pub const SUB = 26;
pub const ESC = 27;
pub const FD = 28;
pub const GS = 29;
pub const RS = 30;
pub const US = 31;
pub const DEL = 127;

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

    const Self = @This();
    pub fn print(self: Self, writer: anytype, args: anytype) @TypeOf(writer).Error!void {
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

            // common private modes
            .enter_alternate_screen => try writer.writeAll(CSI ++ "?1049h"),
            .leave_alternate_screen => try writer.writeAll(CSI ++ "?1049l"),

            // progressive enhancement
            .progressive_enable => try writer.print(CSI ++ ">{}u", args),
            .progressive_pop => try writer.writeAll(CSI ++ "<u"),
            .progressive_disable => try writer.print(CSI ++ "<{}u", args),

            else => @compileError("Command Unimplemented: " ++ @tagName(self)),
        }
    }
};

const std = @import("std");
const testing = std.testing;
