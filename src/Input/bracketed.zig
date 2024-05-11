pub fn readBracketedPaste(reader: anytype, allocator: Allocator) @TypeOf(reader).Error!void {
    var output = ArrayList(u8).init(allocator);
    errdefer output.deinit();

    var read_state = .escaped;

    read_loop: while (true) {
        reader.readUntilDeliminaterArrayList(&output, chars.ESC);

        var chord = BoundedArray(u8, 6){};
        var csi_number = 0;

        char_loop: while (reader.readByte()) |char| {
            chord.append(char) catch unreachable;

            switch (read_state) {
                .escaped => switch (char) {
                    '[' => read_state = .csi,
                    else => break :char_loop,
                },
                .csi => switch (char) {
                    '0'...'9' => csi_number = (csi_number * 10) + charToInt(char),
                    '~' => switch (csi_number) {
                        // TODO: Consider nested bracketed paste? (is that even possible/probable)?
                        201 => break :read_loop,
                        else => break :char_loop,
                    },
                },
            }
        }

        output.appendSlice(chord.constSlice());
    }

    return output;
}

const ReadState = enum {
    escaped,
    csi,
};

const termi = @import("../root.zig");
const chars = termi.chars;
const charToInt = termi.utils.charToInt;

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const BoundedArray = std.BoundedArray;
