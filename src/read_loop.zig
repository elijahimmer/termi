pub const ReturnCode = enum {
    success,
    stop,
};

/// CSI unicode-key-code:alternate-key-codes ; modifiers:event-type ; text-as-codepoints u
pub const ReadState = enum {
    normal,
    escaped,
    csi,
    alternate,
    modifier,
    event_type,
    code_points,
};

pub fn read_loop(stream: anytype, comptime callback: *const fn (Key, []const u8, anytype) anyerror!ReturnCode, args: anytype) anyerror!void {
    var chord = try std.BoundedArray(u8, 256).init(0);
    process_loop: while (true) {
        try chord.resize(0);
        var read_state = ReadState.normal;
        var key = Key{};

        read_loop: while (true) {
            const char = try stream.readByte();
            try chord.append(char);

            switch (read_state) {
                .normal => switch (char) {
                    chars.ESC => read_state = .escaped,
                    else => {
                        key.code = char;
                        break :read_loop;
                    },
                },
                .escaped => switch (char) {
                    '[' => read_state = .csi,
                    else => read_state = .normal,
                },
                .csi => switch (char) {
                    '0'...'9' => key.code = (key.code * 10) + @as(u4, @truncate(char)),
                    ':' => read_state = .alternate,
                    ';' => read_state = .modifier,
                    'u' => break :read_loop,
                    else => continue :process_loop, // invalid
                },
                .alternate => switch (char) {
                    '0'...'9' => key.alternate = ((key.alternate orelse 0) * 10) + char_to_int(char),
                    ';' => read_state = .modifier,
                    'u' => break :read_loop,
                    else => continue :process_loop, // invalid
                },
                .modifier => switch (char) { //@as(u4, @truncate(char)) returns the number of the char represents
                    '0'...'9' => key.modifier = @bitCast((@as(u9, @bitCast(key.modifier)) * 10) + char_to_int(char)),
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

/// just keeps the 4 least significant bits
/// In ASCII that turns the digit into it's number value
pub fn char_to_int(char: u8) u4 {
    return @as(u4, @truncate(char));
}

const termi = @import("termi.zig");
const chars = termi.chars;
const Key = termi.Key;

const std = @import("std");
const assert = std.debug.assert;
