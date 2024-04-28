pub fn main() !void {
    const stdout_file = std.io.getStdOut();
    var bw = std.io.bufferedWriter(stdout_file.writer());
    const stdout = bw.writer();

    const stdin_file = std.io.getStdIn();
    var br = std.io.bufferedReader(stdin_file.reader());
    const stdin = br.reader();

    var term_manager = termManager(stdout_file.writer(), stdin_file.reader());
    defer term_manager.deinit() catch {};

    global_term_manager = &term_manager;

    try term_manager.enterAlternateScreen();
    try term_manager.setRawMode();
    try term_manager.setProgressive(.{
        .disambiguate = true,
        //.event_types = true,
        //.alternate_keys = true,
        //.keys_as_escape_codes = true,
        .associated_text = true,
    });

    try ec.print_command(stdout, .home, .{});

    while (true) {
        try print_ascii(stdout, try stdin.readByte());
        try bw.flush();

        //const input = termi.Input{
        //    .code = .{.unknown = undefined},
        //};

        //switch (input.code) {
        //    .text => |text| {
        //        switch (text.key_code) {
        //
        //        }
        //    },
        //    .special => |special| {},
        //    .unknown => log.warn("unknown input: {s}", input.chord),
        //}

        //const in = try termi.input.readOneEventRaw(stdin);

        //switch (in) {
        //    .normal => |char| {
        //        try print_ascii(stdout, char);
        //        if (char == 3) break;
        //    },
        //    .escaped => |escaped| {
        //        try escaped.print(stdout);
        //    },
        //    .csi => |csi| {
        //        const parsed = termi.input.parseRawInputCsi(csi);

        //        switch (parsed.code) {
        //            .unicode => |c| if (c.code == 'c' and parsed.modifier.onlyActive(.ctrl)) break,
        //            else => {},
        //        }

        //        try parsed.print(stdout);
        //    },
        //}

        //try bw.flush();
    }
}

//pub fn output_char(key: Key, chord: []const u8, args: anytype) !read_loop.ReturnCode {
//    const stdout, var bw = args;
//
//    if (key.code == 3 or (key.code == 'c' and key.modifier.ctrl)) return .stop;
//
//    if (key.code <= std.math.maxInt(u8)) try print_ascii(stdout, @intCast(key.code));
//
//    try stdout.print("\t'", .{});
//    for (chord) |char| try print_ascii(stdout, char);
//    try stdout.print("'\t{}\x0d\n", .{key});
//
//    try bw.flush();
//
//    return .success;
//}

pub fn print_ascii(writer: anytype, char: u8) @TypeOf(writer).Error!void {
    switch (char) {
        // 1 => "^A", 2 => "^B", 3 => "^C", etc
        0...31 => try writer.print("^{c}", .{'A' - 1 + char}),
        127 => try writer.print("Backspace", .{}),
        else => try writer.print("{c}", .{char}),
    }
}

var global_term_manager: ?*TermManager(std.fs.File.Writer, std.fs.File.Reader) = null;

/// Overrides the default panic to reset terminal mode
pub fn panic(message: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    if (global_term_manager) |tm| tm.deinit() catch {};

    std.builtin.default_panic(message, error_return_trace, ret_addr);
}

pub const std_options: std.Options = .{
    .keep_sigpipe = true,
};

const termi = @import("termi.zig");
const ec = termi.escape_codes;
const CSI = ec.CSI;
const chars = termi.chars;

const termManager = termi.termManager;
const TermManager = termi.TermManager;

const std = @import("std");
const io = std.io;
const mem = std.mem;
const meta = std.meta;

const assert = std.debug.assert;

const log = std.log.scoped(.@"termi-main");
