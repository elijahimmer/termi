pub const SetRawError = posix.TermiosSetError || posix.TermiosSetError;

/// Returns a raw configuration, setting `last_start` to the current config.
pub fn set_raw(writer: posix.fd_t) SetRawError!void {
    var term_raw = try posix.tcgetattr(writer);
    last_start = term_raw;

    term_raw.iflag = .{
        //.IGNBRK = true,
        .ICRNL = true,
        .IUTF8 = true,
    };
    term_raw.oflag = .{};
    term_raw.cflag = .{
        .CSIZE = .CS8,
        //.CLOCAL = true,
    };
    term_raw.lflag = .{
        //.NOFLSH = true,
    };

    try posix.tcsetattr(writer, .NOW, term_raw);
}

pub const ResetError = posix.TermiosSetError;

/// Sets the stdout file's file mode.
pub fn reset(writer: posix.fd_t) ResetError!void {
    if (last_start) |start| try posix.tcsetattr(writer, .NOW, start);
}

var last_start: ?posix.termios = null;

const posix = @import("std").posix;
