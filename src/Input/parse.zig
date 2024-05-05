/// CSI A : B ; C : D ; E mod
/// any part is optional
pub const RawInputCsi = struct {
    A: ?u16 = null,
    B: ?u16 = null,
    C: ?u16 = null,
    D: ?u16 = null,
    E: ?u16 = null,
    mod: u8,
    /// the chord that makes up the input
    chord: Chord = Chord{},
};

const ReadState = enum {
    normal,
    escaped,
    SS3,
    A,
    B,
    C,
    D,
    E,
};

pub fn readOneInput(reader: anytype) @TypeOf(reader).NoEofError!Input {
    var unknown: Input = .{ .key_code = .{ .unknown = undefined }, .chord = .{} };

    var ss3_number: ?u16 = null;
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
                    var normal = parseNormalToInput(char);
                    normal.chord = unknown.chord;
                    return normal;
                },
            },
            .escaped => switch (char) {
                '[' => read_state = .A,
                'O' => read_state = .SS3,
                else => {
                    log.warn("escaped input unimplemented", .{});
                    return unknown;
                },
            },
            .SS3 => switch (char) {
                '0'...'9' => ss3_number = (ss3_number orelse 0) * 10 + char_to_int(char),
                else => return parseSS3ToInput(char, ss3_number orelse 1, unknown.chord),
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

    input.chord = unknown.chord;

    return parseCsiToInput(input);
}

/// parse a single letter input, usually legacy input
pub fn parseNormalToInput(char: u8) Input {
    return switch (char) {
        0, 27...31 => .{
            .key_code = .{ .text = char + '@' },
            .modifiers = .{ .ctrl = true },
        },
        1...26 => .{ // ^C should be the letter `c` with ctrl enabled
            .key_code = .{ .text = char + '`' },
            .modifiers = .{ .ctrl = true },
        },
        127 => .{
            .key_code = .{ .special = .backspace },
            .modifiers = .{ .ctrl = true },
        },
        else => .{
            .key_code = .{ .text = char },
        },
    };
}

/// parse a SS3 Chord to a input.
pub fn parseSS3ToInput(mod: u8, ss3_number: u16, chord: Chord) Input {
    _ = ss3_number; // I don't think we need this
    return .{
        .chord = chord,
        .key_code = .{
            .special = switch (mod) {
                'A' => .up,
                'B' => .down,
                'C' => .right,
                'D' => .left,
                //'E' should be here, but I cannot find what it does...
                'F' => .end,
                'H' => .home,
                'P' => .F1,
                'Q' => .F2,
                'R' => .F3,
                'S' => .F4,
                else => {
                    log.warn("unknown SS3 escape code", .{});
                    return .{ .chord = chord, .key_code = .{ .unknown = undefined } };
                },
            },
        },
    };
}

// CSI unicode-key-code:alternate-key-codes ; modifiers:event-type ; text-as-codepoints u
pub fn parseCsiToInput(in: RawInputCsi) Input {
    const modifiers: Modifier = @bitCast(@as(u8, @truncate((in.C orelse 1) - 1)));
    const input_type: InputType = @enumFromInt(@as(u2, @intCast(in.D orelse 1)));

    const unknown = .{ .chord = in.chord, .input_type = input_type, .modifiers = modifiers, .key_code = .{ .unknown = undefined } };

    return .{ .chord = in.chord, .input_type = input_type, .modifiers = modifiers, .key_code = .{ .special = switch (in.mod) {
        'u' => switch (in.E orelse in.B orelse in.A orelse return unknown) {
            else => {
                const key_code = in.B orelse in.A orelse {
                    log.warn("no character in input", .{});
                    return unknown;
                };

                if (key_code > std.math.maxInt(u8)) {
                    log.warn("unimplemented character", .{});
                    return unknown;
                }

                return .{
                    .key_code = .{ .text = @as(u8, @truncate(key_code)) },
                    .modifiers = modifiers,
                    .input_type = input_type,
                    .chord = in.chord,
                };
            },
            2 => .insert,
            9 => .tab,
            13 => .enter,
            27 => .escape,
            127 => .backspace,
            57358 => .caps_lock,
            57359 => .scroll_lock,
            57360 => .num_lock,
            57361 => .print_screen,
            57362 => .pause,
            57363 => .menu,
            57376 => .F13,
            57377 => .F14,
            57378 => .F15,
            57379 => .F16,
            57380 => .F17,
            57381 => .F18,
            57382 => .F19,
            57383 => .F20,
            57384 => .F21,
            57385 => .F22,
            57386 => .F23,
            57387 => .F24,
            57388 => .F25,
            57389 => .F26,
            57390 => .F27,
            57391 => .F28,
            57392 => .F29,
            57393 => .F30,
            57394 => .F31,
            57395 => .F32,
            57396 => .F33,
            57397 => .F34,
            57398 => .F35,
            57399 => .kp_0,
            57400 => .kp_1,
            57401 => .kp_2,
            57402 => .kp_3,
            57403 => .kp_4,
            57404 => .kp_5,
            57405 => .kp_6,
            57406 => .kp_7,
            57407 => .kp_8,
            57408 => .kp_9,
            57409 => .kp_decimal,
            57410 => .kp_divide,
            57411 => .kp_multiply,
            57412 => .kp_subtract,
            57413 => .kp_add,
            57414 => .kp_enter,
            57415 => .kp_equal,
            57416 => .kp_separator,
            57417 => .kp_left,
            57418 => .kp_right,
            57419 => .kp_up,
            57420 => .kp_down,
            57421 => .kp_page_up,
            57422 => .kp_page_down,
            57423 => .kp_home,
            57424 => .kp_end,
            57425 => .kp_insert,
            57426 => .kp_delete,
            57427 => .kp_begin,
            57428 => .media_play,
            57429 => .media_pause,
            57430 => .media_play_pause,
            57431 => .media_reverse,
            57432 => .media_stop,
            57433 => .media_fast_forward,
            57434 => .media_rewind,
            57435 => .media_track_next,
            57436 => .media_track_previous,
            57437 => .media_record,
            57438 => .lower_volume,
            57439 => .raise_volume,
            57440 => .mute_volume,
            57441 => .left_shift,
            57442 => .left_control,
            57443 => .left_alt,
            57444 => .left_super,
            57445 => .left_hyper,
            57446 => .left_meta,
            57447 => .right_shift,
            57448 => .right_control,
            57449 => .right_alt,
            57450 => .right_super,
            57451 => .right_hyper,
            57452 => .right_meta,
            57453 => .iso_level3_shift,
            57454 => .iso_level5_shift,
        },
        'A' => .up,
        'B' => .down,
        'C' => .right,
        'D' => .left,
        'E' => .kp_begin,
        'F' => .end,
        'H' => .home,
        'P' => .F1,
        'Q' => .F2,
        'R' => .F3,
        'S' => .F4,
        '~' => switch (in.A orelse {
            log.warn("unknown input", .{});
            return unknown;
        }) {
            2 => .insert,
            3 => .delete,
            5 => .page_up,
            6 => .page_down,
            7 => .home,
            8 => .end,
            11 => .F1,
            12 => .F2,
            13 => .F3,
            14 => .F4,
            15 => .F5,
            17 => .F6,
            18 => .F7,
            19 => .F8,
            20 => .F9,
            21 => .F10,
            23 => .F11,
            24 => .F12,
            29 => .menu,
            200 => .bracketed_paste_start,
            201 => .bracketed_paste_end,
            57427 => .kp_begin,
            else => {
                log.warn("unknown input", .{});
                return unknown;
            },
        },
        else => {
            log.warn("unknown input", .{});
            return unknown;
        },
    } } };
}

const termi = @import("../termi.zig");
const log = termi.log;
const Input = termi.Input;
const Modifier = Input.Modifiers;
const InputType = Input.InputType;
const Chord = Input.Chord;
const chars = termi.chars;
const CSI = chars.CSI;
const char_to_int = termi.utils.char_to_int;

const std = @import("std");
const expectEqual = std.testing.expectEqual;
