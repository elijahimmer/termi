/// just keeps the 4 least significant bits
/// In ASCII that turns the digit into it's number value
pub fn char_to_int(char: u8) u4 {
    return @as(u4, @truncate(char));
}
