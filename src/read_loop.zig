
pub fn read_loop(stream: anytype, comptime callback: *const fn (InputEvent, []const u8, anytype) anyerror!ReturnCode, args: anytype) anyerror!void {
    var chord = try std.BoundedArray(u8, 256).init(0);
    process_loop: while (true) {
        try chord.resize(0);
        var read_state = ReadState.normal;
        var input = RawEscapedInput{.H = 0};

        read_loop: while (true) {
            const char = try stream.readByte();
            try chord.append(char);

            switch (read_state) {
                .normal => switch (char) {
                    chars.ESC => read_state = .escaped,
                    else => {
                        input.A = char;
                        break :read_loop;
                    },
                },
                .escaped => switch (char) {
                    '[' => read_state = .csi,
                    else => read_state = .normal,
                },
                .csi => switch (char) {
                    '0'...'9' => input.A = (input.A orelse 0 * 10) + char_to_int(char),
                    ':' => read_state = .B,
                    ';' => read_state = .C,
                    'u' => break :read_loop,
                    else => continue :process_loop, // invalid
                },
                .alternate => switch (char) {
                    '0'...'9' => input.B = ((input.B orelse 0) * 10) + char_to_int(char),
                    ';' => read_state = .C,
                    'u' => break :read_loop,
                    else => continue :process_loop, // invalid
                },
                .modifier => switch (char) {
                    '0'...'9' => input.C = @bitCast((@as(u9, @bitCast(input.C)) * 10) + char_to_int(char)),
                    ':' => read_state = .event_type,
                    ';' => read_state = .code_points,
                    'u' => break :read_loop,
                    else => continue :process_loop, // invalid
                },
                .event_type => switch (char) {
                    '1'...'3' => key.event_type = @enumFromInt(@as(u2, @truncate(char))),
                    ';' => read_state = .code_points,
                    'u' => break :read_loop,
                    else => continue :process_loop, // invalid
                },
                .code_points => switch (char) {
                    '0'...'9' => key.code_points = ((key.code_points orelse 0) * 10) + char_to_int(char),
                    'u' => break :read_loop,
                    else => continue :process_loop, // invalid
                },
            }
        }

        if (@as(u9, @bitCast(key.modifier)) > 0) key.modifier = @bitCast(@as(u9, @bitCast(key.modifier)) - 1);

        assert(key.code != 0);

        switch (try @call(.auto, callback, .{ key, chord.constSlice(), args })) {
            .success => {},
            .stop => return,
        }
    }
}

const termi = @import("termi.zig");
const chars = termi.chars;
const RawInput = termi.RawInput;
const InputEvent = termi.InputEvent;

const std = @import("std");
const assert = std.debug.assert;
