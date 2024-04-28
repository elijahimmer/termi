pub fn main() !void {
    const stdout_file = std.io.getStdOut();
    var bw = std.io.bufferedWriter(stdout_file.writer());
    const stdout = bw.writer();

    const stdin_file = std.io.getStdIn();
    //var br = std.io.bufferedReader(stdin_file.reader());
    //const stdin = br.reader();

    const pro = ProgressiveEnhancement{
        .disambiguate = true,
        .event_types = true,
        //.alternate_keys = true,
        .keys_as_escape_codes = true,
        .associated_text = true,
    };

    const term_start = try posix.tcgetattr(stdout_file.handle);
    var term_raw = term_start;

    term_raw.iflag = .{
        .ICRNL = true,
        .IUTF8 = true,
    };
    term_raw.oflag = .{};
    term_raw.cflag = .{};
    term_raw.lflag = .{};

    try posix.tcsetattr(stdout_file.handle, .NOW, term_raw);

    defer posix.tcsetattr(stdout_file.handle, .NOW, term_start) catch {};

    try pro.push(stdout_file.writer());
    defer ProgressiveEnhancement.pop(stdout_file.writer()) catch {};

    try stdout_file.writer().print(CSI ++ "?2004h", .{});
    defer stdout_file.writer().print(CSI ++ "?2004l", .{}) catch {};

    while (true) {
        const input = try termi.Input.parse.readOneInput(stdin_file.reader());
        switch (input.key_code) {
            .unknown => try stdout.print("unknown", .{}),
            .text => |t| try print_ascii(stdout, t),
            .special => |s| try stdout.print("{s}", .{@tagName(s)}),
        }

        try stdout.print("\t; modifiers: {b}", .{@as(u8, @bitCast(input.modifiers))});
        try stdout.print("\t; type: {s}", .{@tagName(input.input_type)});
        try stdout.print("\t; chord: '", .{});

        for (input.chord.constSlice()) |c| {
            try print_ascii(stdout, c);
        }

        try stdout.print("'{c}\n", .{chars.CR});
        try bw.flush();
    }
}

pub fn print_ascii(writer: anytype, char: u8) @TypeOf(writer).Error!void {
    switch (char) {
        // 1 => "^A", 2 => "^B", 3 => "^C", etc
        0...31 => try writer.print("^{c}", .{'A' - 1 + char}),
        127 => try writer.print("Backspace", .{}),
        else => try writer.print("{c}", .{char}),
    }
}

const termi = @import("termi.zig");
const chars = termi.chars;
const CSI = chars.CSI;
const ProgressiveEnhancement = termi.ProgressiveEnhancement;

const std = @import("std");
const posix = std.posix;
