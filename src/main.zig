pub fn main() !void {
    const stdout_file = std.io.getStdOut();
    var bw = std.io.bufferedWriter(stdout_file.writer());
    defer bw.flush() catch {};
    const stdout = bw.writer();

    const stdin_file = std.io.getStdIn();
    //var br = std.io.bufferedReader(stdin_file.reader());
    //const stdin = br.reader();

    var term_manager = TermManager.init(stdout_file.writer(), stdin_file.reader());
    defer term_manager.deinit() catch {};

    try term_manager.modeSetRaw();
    try term_manager.bracketedPasteSet();
    try term_manager.progressiveSet(.{
        .disambiguate = true,
        .event_types = true,
        .alternate_keys = true,
        .keys_as_escape_codes = true,
        .associated_text = true,
    });

    while (true) {
        const input = try Input.parse.readOneInput(stdin_file.reader());

        try input.print(stdout);

        try stdout.print("\t{s}   \tchord: '", .{@tagName(input.input_type)});

        for (input.chord.constSlice()) |c| {
            try print_ascii(stdout, c);
        }

        try stdout.print("'{s}", .{chars.NL});
        try bw.flush();

        if (@as(Input.KeyCodeTag, input.key_code) == .text and input.key_code.text == 'c' and input.modifiers.onlyActive(.ctrl)) {
            break;
        }
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
const Input = termi.Input;
const chars = termi.chars;
const CSI = chars.CSI;
const ProgressiveEnhancement = termi.ProgressiveEnhancement;
const TermManager = termi.TermManager;

const std = @import("std");
const posix = std.posix;
const meta = std.meta;
