pub const Chord = std.BoundedArray(16, u8);

pub const RawInput = struct {
    chord: Chord,
    input_type: RawInputType,
};

pub const RawInputTypeTag = enum {
    normal,
    escaped,
    csi,
};

pub const RawInputType = union(RawInputTypeTag) {
    normal: u8,
    escaped: RawInputEscaped,
    csi: RawInputCsi,
};

pub const RawInputEscaped = struct {
    num: ?u8 = null,
    mod: u8 = undefined,

    const Self = @This();

    pub fn print(self: *const Self, writer: anytype) @TypeOf(writer).Error!void {
        try writer.print("^[", .{});
        if (self.num) |num| try writer.print("{}", .{num});
        try writer.print("{}", .{self.mod});
    }
};

pub const RawInputCsi = struct {
    A: ?u16 = null,
    B: ?u16 = null,
    C: ?u16 = null,
    D: ?u16 = null,
    E: ?u24 = null,
    mod: u8 = undefined,

    const Self = @This();

    pub fn print(self: *const Self, writer: anytype) @TypeOf(writer).Error!void {
        try writer.print("^[[", .{});
        if (self.A) |A| try writer.print("{}", .{A});
        if (self.B) |B| try writer.print(":{}", .{B});
        if (self.C != null or self.D != null or self.E != null) try writer.print(";", .{});
        if (self.C) |C| try writer.print("{}", .{C});
        if (self.D) |D| try writer.print(":{}", .{D});
        if (self.E) |E| try writer.print(";{}", .{E});
        try writer.print("{c}", .{self.F});
    }
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

/// reads one RawInput from a reader, either a single character or a escaped string
/// You should use a buffered reader.
pub fn readOneEventRaw(reader: anytype) @TypeOf(reader).NoEofError!RawInput {
    var read_state = ReadState.normal;
    var input: RawInput = undefined;

    read_loop: while (true) {
        const char = try reader.readByte();

        switch (read_state) {
            .normal => switch (char) {
                chars.ESC => read_state = .escaped,
                else => {
                    input = .{ .normal = char };
                    break :read_loop;
                },
            },
            .escaped => switch (char) {
                '[' => {
                    read_state = .A;
                    input = .{ .csi = .{} };
                },
                '0'...'9' => input = .{ .escaped = .{ .num = char_to_int(char) } },
                else => break :read_loop switch (input) {
                    .escaped => |*esc| esc.mod = char,
                    else => input = .{ .escaped = .{ .mod = char } },
                },
            },
            .A => switch (char) {
                '0'...'9' => input.csi.A = (input.csi.A orelse 0) * 10 + char_to_int(char),
                ':' => read_state = .B,
                ';' => read_state = .C,
                else => {
                    input.csi.mod = char;
                    break :read_loop;
                },
            },
            .B => switch (char) {
                '0'...'9' => input.csi.B = (input.csi.B orelse 0) * 10 + char_to_int(char),
                ';' => read_state = .C,
                else => {
                    input.csi.mod = char;
                    break :read_loop;
                },
            },
            .C => switch (char) {
                '0'...'9' => input.csi.C = (input.csi.C orelse 0) * 10 + char_to_int(char),
                ':' => read_state = .D,
                ';' => read_state = .E,
                else => {
                    input.csi.mod = char;
                    break :read_loop;
                },
            },
            .D => switch (char) {
                '0'...'9' => input.csi.D = (input.csi.D orelse 0) * 10 + char_to_int(char),
                ';' => read_state = .E,
                else => {
                    input.csi.mod = char;
                    break :read_loop;
                },
            },
            .E => switch (char) {
                '0'...'9' => input.csi.E = (input.csi.E orelse 0) * 10 + char_to_int(char),
                else => {
                    input.csi.mod = char;
                    break :read_loop;
                },
            },
        }
    }

    return input;
}

const termi = @import("../termi.zig");
const char_to_int = termi.utils.char_to_int;
const chars = termi.chars;

const std = @import("std");
const assert = std.debug.assert;
