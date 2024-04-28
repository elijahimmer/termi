/// CSI A : B ; C : D ; E mod
/// any part is optional
pub const RawInputCsi = struct {
    A: ?u16 = null,
    B: ?u16 = null,
    C: ?u16 = null,
    D: ?u16 = null,
    E: ?u24 = null,
    mod: u8,
    /// the chord that makes up the input
    chord: Chord = Chord{},
};

const ReadState = enum {
    normal,
    escaped,
    A,
    B,
    C,
    D,
    E,
};

pub fn readOneInput(reader: anytype) @TypeOf(reader).NoEofError!Input {
    var unknown: Input = .{ .key_code = .{ .unknown = undefined }, .chord = .{} };

    var read_state = ReadState.normal;
    var input: RawInputCsi = .{ .mod = undefined };

    read_loop: while (true) {
        const char = try reader.readByte();
        unknown.chord.append(char) catch {
            log.warn("input chord too long", .{});
            return unknown;
        };

        switch (read_state) {
            .normal => switch (char) {
                chars.ESC => read_state = .escaped,
                else => {
                    log.warn("unimplemented input", .{});
                    return unknown;
                },
            },
            .escaped => switch (char) {
                '[' => read_state = .A,
                else => {
                    log.warn("unimplemented input", .{});
                    return unknown;
                },
            },
            .A => switch (char) {
                '0'...'9' => input.A = (input.A orelse 0) * 10 + char_to_int(char),
                ':' => read_state = .B,
                ';' => read_state = .C,
                else => {
                    input.mod = char;
                    break :read_loop;
                },
            },
            .B => switch (char) {
                '0'...'9' => input.B = (input.B orelse 0) * 10 + char_to_int(char),
                ';' => read_state = .C,
                else => {
                    input.mod = char;
                    break :read_loop;
                },
            },
            .C => switch (char) {
                '0'...'9' => input.C = (input.C orelse 0) * 10 + char_to_int(char),
                ':' => read_state = .D,
                ';' => read_state = .E,
                else => {
                    input.mod = char;
                    break :read_loop;
                },
            },
            .D => switch (char) {
                '0'...'9' => input.D = (input.D orelse 0) * 10 + char_to_int(char),
                ';' => read_state = .E,
                else => {
                    input.mod = char;
                    break :read_loop;
                },
            },
            .E => switch (char) {
                '0'...'9' => input.E = (input.E orelse 0) * 10 + char_to_int(char),
                else => {
                    input.mod = char;
                    break :read_loop;
                },
            },
        }
    }

    if (input.mod != 'u') {
        log.warn("unknown input", .{});
        return unknown;
    }
    const key_code = input.B orelse input.A orelse {
        log.warn("no character in input", .{});
        return unknown;
    };

    if (key_code > std.math.maxInt(u8)) {
        log.warn("no character in input", .{});
        return unknown;
    }

    return .{
        .key_code = .{ .text = @as(u8, @truncate(key_code)) },
        .modifiers = @bitCast(@as(u8, @truncate((input.C orelse 1) - 1))),
        .input_type = @enumFromInt(@as(u2, @intCast(input.D orelse 1))),
        .chord = unknown.chord,
    };
}

const termi = @import("../termi.zig");
const log = termi.log;
const Input = termi.Input;
const Chord = Input.Chord;
const chars = termi.chars;
const CSI = chars.CSI;
const char_to_int = termi.utils.char_to_int;

const std = @import("std");
const expectEqual = std.testing.expectEqual;
