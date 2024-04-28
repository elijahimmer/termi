pub fn char_to_int(char: u8) u4 {
    return @as(u4, @truncate(char));
}
