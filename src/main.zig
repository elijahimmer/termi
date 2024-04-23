pub fn main() !void {
    const stdout_file = std.io.getStdOut();
    var bw = std.io.bufferedWriter(stdout_file.writer());
    const stdout = bw.writer();

    defer bw.flush() catch {};

    try term_mode.set_raw(stdout_file.handle);
    defer term_mode.reset(stdout_file.handle) catch {};

    try ec.print_command(stdout, .enter_alternate_buffer, .{});
    defer ec.print_command(stdout, .leave_alternate_buffer, .{}) catch {};

    try ec.set_progressive(stdout, .{
        .disambiguate = true,
        .event_types = true,
        .alternate_keys = true,
        .keys_as_escape_codes = true,
    });
    defer ec.reset_progressive(stdout) catch {};

    try ec.print_command(stdout, .home, .{});
    try bw.flush();

    const stdin_raw = std.io.getStdIn().reader();
    var br = std.io.bufferedReader(stdin_raw);
    const stdin = br.reader();

    var read_state: ReadState = .{ .normal = undefined };

    while (true) {
        const char = try stdin.readByte();

        switch (read_state) {
            .normal => switch (char) {
                Char.ESC => read_state = .{ .escaped = undefined },
                else => {},
            },
            .escaped => switch (char) {
                '[' => read_state = .{ .csi = 0 },
                else => read_state = .{ .normal = undefined },
            },
            .csi => |state| switch (char) {
                '0'...'9' => read_state = .{ .csi = (state * 10) + @as(u4, @truncate(char)) },
                ';' => read_state = .{ .csi_double = .{ .one = read_state.csi, .two = 0 } },
                'u' => { // character input
                    try stdout.print("{c}\noutput char: '", .{Char.CR});
                    try print_ascii(stdout, @truncate(state));
                    try stdout.writeByte('\'');
                    read_state = .{ .normal = undefined };
                },
                else => read_state = .{ .normal = undefined },
            },
            .csi_double => |*state| switch (char) {
                '0'...'9' => {
                    state.*.two = (state.two * 10) + @as(u4, @truncate(char)); // truncate to get integer section of char
                },
                ':' => {
                    read_state = .{ .char_input = .{ .key_code = state.one, .modifier = state.two } };
                },
                ';' => {
                    const current = read_state.csi_double;

                    read_state = .{ .csi_triple = .{ .one = current.one, .two = current.two } };
                },
                'u' => { // char input
                    try stdout.print("{c}\noutput char: {}", .{ Char.CR, read_state.csi_double });
                    read_state = .{ .normal = undefined };
                },
                else => read_state = .{ .normal = undefined },
            },
            .csi_triple => read_state = .{ .normal = undefined },
            .char_input => switch (char) {
                '1'...'3' => {
                    var current = read_state.char_input;
                    current.event_type = @enumFromInt(@as(u2, @truncate(char)));
                    read_state.char_input = current;
                },
                'u' => { // character input
                    read_state = .{ .normal = undefined };
                },
                else => read_state = .{ .normal = undefined },
            },
        }

        try print_ascii(stdout, char);
        try stdout.print("\t{}{c}\n", .{ read_state, Char.CR });
        try bw.flush();
    }
}

pub fn print_ascii(writer: anytype, char: u8) @TypeOf(writer).Error!void {
    switch (char) {
        0...31 => try writer.print("^{c}", .{'A' - 1 + char}),
        127 => try writer.print("DEL", .{}),
        else => try writer.print("{c}", .{char}),
    }
}

pub const ReadStateTag = enum {
    normal,
    escaped,
    csi,
    csi_double,
    csi_triple,
    char_input,
};

pub const CSIDouble = struct {
    one: u16 = 0,
    two: u16 = 0,
};

pub const CSITriple = struct {
    one: u16 = 0,
    two: u16 = 0,
    three: u16 = 0,
};

/// CSI unicode-key-code:alternate-key-codes ; modifiers:event-type ; text-as-codepoints u
pub const CharInputEventType = enum(u2) {
    press = 1,
    repeat = 2,
    release = 3,
};

pub const CharInput = struct {
    key_code: u16 = 0,
    modifier: u16 = 0,
    /// the event type
    event_type: CharInputEventType = .press,
};

pub const ReadState = union(ReadStateTag) {
    normal: void,
    escaped: void,
    csi: u16,
    csi_double: CSIDouble,
    csi_triple: CSITriple,
    char_input: CharInput,
};

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
const Char = ec.Char;
const csi = ec.csi;
const term_mode = @import("term_mode.zig");

const log = std.log.scoped(.libtermi);

const std = @import("std");
const io = std.io;
const mem = std.mem;
const meta = std.meta;

const assert = std.debug.assert;
