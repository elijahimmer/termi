pub fn charToInt(char: u8) u4 {
    assert('0' <= char and char <= '9'); // it has to be a number character
    return @as(u4, @truncate(char));
}

pub fn printAscii(writer: anytype, char: u8) @TypeOf(writer).Error!void {
    switch (char) {
        // 1 => "^A", 2 => "^B", 3 => "^C", etc
        0...31 => try writer.print("^{c}", .{'A' - 1 + char}),
        127 => try writer.writeAll("Backspace"),
        else => try writer.print("{c}", .{char}),
    }
}

const std = @import("std");
const assert = std.debug.assert;
