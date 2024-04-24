pub fn main() !void {
    const stdout_file = std.io.getStdOut();
    const stdout = stdout_file.writer();

    try term_mode.set_raw(stdout_file.handle);
    defer term_mode.reset(stdout_file.handle) catch {};

    try ec.print_command(stdout, .enter_alternate_buffer, .{});
    defer ec.print_command(stdout, .leave_alternate_buffer, .{}) catch {};

    try ec.set_progressive(stdout, .{
        .disambiguate = true,
        .event_types = true,
        .alternate_keys = true,
        .keys_as_escape_codes = true,
        .associated_text = true,
    });
    defer ec.reset_progressive(stdout) catch {};

    try ec.print_command(stdout, .home, .{});

    const stdin_file = std.io.getStdIn();
    var br = std.io.bufferedReader(stdin_file.reader());
    const stdin = br.reader();

    var bw = std.io.bufferedWriter(stdout);
    const stdout_buffered = bw.writer();

    try read_loop.read_loop(stdin, &output_char, .{ stdout_buffered, &bw });
}

pub fn output_char(key: Key, chord: []const u8, args: anytype) !read_loop.ReturnCode {
    const stdout, var bw = args;

    if (key.code == 'c' and key.modifier.ctrl) return .stop;

    if (key.code <= std.math.maxInt(u8)) {
        try print_ascii(stdout, @intCast(key.code));
    }

    try stdout.print("\t'", .{});
    for (chord) |char| try print_ascii(stdout, char);
    try stdout.print("'\t{}\x0d\n", .{key});

    try bw.flush();

    return .success;
}

pub fn print_ascii(writer: anytype, char: u8) @TypeOf(writer).Error!void {
    switch (char) {
        0...31 => try writer.print("^{c}", .{'A' - 1 + char}),
        127 => try writer.print("DEL", .{}),
        else => try writer.print("{c}", .{char}),
    }
}

/// Overrides the default panic to reset terminal mode
pub fn panic(message: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    const stdout = std.io.getStdOut().writer();

    ec.reset_progressive(stdout) catch {};
    ec.print_command(stdout, .leave_alternate_buffer, .{}) catch {};

    std.builtin.default_panic(message, error_return_trace, ret_addr);
}

pub const std_options: std.Options = .{
    .keep_sigpipe = true,
};

const ec = @import("escape_codes.zig");
const read_loop = @import("read_loop.zig");
const term_mode = @import("term_mode.zig");

const Key = @import("key.zig").Key;

const log = std.log.scoped(.libtermi);

const std = @import("std");
const io = std.io;
const mem = std.mem;
const meta = std.meta;

const assert = std.debug.assert;
