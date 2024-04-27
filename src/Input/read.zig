//const ReadState = enum {
//    normal,
//    escaped,
//    A,
//    B,
//    C,
//    D,
//    E,
//};
//
//pub fn normalToInput(char: u8) Input {
//}
//
//pub fn readOneInput(reader: anytype) @TypeOf(reader).NoEofError!Input {
//    var read_state = ReadState.normal;
//    var input:  = undefined;
//
//    read_loop: while (true) {
//        const char = try reader.readByte();
//
//        switch (read_state) {
//            .normal => switch (char) {
//                chars.ESC => read_state = .escaped,
//                else => return normalToInput(char),
//            },
//            .escaped => switch (char) {
//                '[' => {
//                    read_state = .A;
//                    input = .{ .csi = .{} };
//                },
//                '0'...'9' => input = .{ .escaped = .{ .num = char_to_int(char) } },
//                else => break :read_loop switch (input) {
//                    .escaped => |*esc| esc.mod = char,
//                    else => input = .{ .escaped = .{ .mod = char } },
//                },
//            },
//            .A => switch (char) {
//                '0'...'9' => input.csi.A = (input.csi.A orelse 0) * 10 + char_to_int(char),
//                ':' => read_state = .B,
//                ';' => read_state = .C,
//                else => {
//                    input.csi.mod = char;
//                    break :read_loop;
//                },
//            },
//            .B => switch (char) {
//                '0'...'9' => input.csi.B = (input.csi.B orelse 0) * 10 + char_to_int(char),
//                ';' => read_state = .C,
//                else => {
//                    input.csi.mod = char;
//                    break :read_loop;
//                },
//            },
//            .C => switch (char) {
//                '0'...'9' => input.csi.C = (input.csi.C orelse 0) * 10 + char_to_int(char),
//                ':' => read_state = .D,
//                ';' => read_state = .E,
//                else => {
//                    input.csi.mod = char;
//                    break :read_loop;
//                },
//            },
//            .D => switch (char) {
//                '0'...'9' => input.csi.D = (input.csi.D orelse 0) * 10 + char_to_int(char),
//                ';' => read_state = .E,
//                else => {
//                    input.csi.mod = char;
//                    break :read_loop;
//                },
//            },
//            .E => switch (char) {
//                '0'...'9' => input.csi.E = (input.csi.E orelse 0) * 10 + char_to_int(char),
//                else => {
//                    input.csi.mod = char;
//                    break :read_loop;
//                },
//            },
//        }
//    }
//
//    return input;
//}
