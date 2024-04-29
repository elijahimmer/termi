pub fn char_to_int(char: u8) u4 {
    assert('0' <= char and char <= '9'); // it has to be a number character
    return @as(u4, @truncate(char));
}

test {
    @import("std").testing.refAllDecls(@This());
}

const std = @import("std");
const assert = std.debug.assert;
