/// This keeps track of the stacks put onto and popped on the terminal's enhancement
/// stack. This helps prevent your application from leaving some stack frames left
/// and botch existing stack frames so you don't mess up other applications.
/// Use ProgressiveEnhancement struct if you don't care for the safety.
/// You should make sure you reset your enhancement stack on panic so a panic doesn't
/// ruin the terminal.
///
/// Make sure you .deinit() to make sure you don't leave
/// enhancement frames behind.
pub fn EnhancementStack(comptime WriterType: type) type {
    return struct {
        writer: WriterType,
        enhancement_frames: u8 = 0,

        const Self = @This();

        /// Cleans up and resets all enhancements
        pub fn deinit(self: *Self) WriterType.Error!void {
            if (self.enhancement_frames > 0) self.popMany(self.enhancement_frames) catch |err| switch (err) {
                error.@"Popped More Enhancement Frames Than Pushed", error.@"Cannot Pop Zero Enhancement Frames" => unreachable,
                else => |e| return e,
            };
        }

        const SetError = error{@"Set With No Enhancement Frames"} || WriterType.Error;

        /// asserts you have pushed your own stack frame before using it
        pub fn set(self: *Self, enhancement: ProgressiveEnhancement) SetError!void {
            assert(self.enhancement_frames > 0); // you should only set while you have a stack frame pushed.

            try enhancement.set();
        }

        const PushError = error{@"Too Many Enhancement Frames Pushed"} || WriterType.Error;

        /// Pushes a progressive onto the stack.
        /// Should only really be used once, and it should be poped whenever you are done using it.
        pub fn push(self: *Self, enhancement: ProgressiveEnhancement) PushError!void {
            if (self.enhancement_frames >= std.math.maxInt(@TypeOf(self.enhancement_frames))) return error.@"Too Many Enhancement Frames Pushed";
            self.enhancement_frames += 1;

            try enhancement.push(self.writer);
        }

        const PopError = error{@"No Enhancement Frames To Pop"} || WriterType.Error;

        /// disables select progressive enhancements
        pub fn pop(self: *Self) PopError!void {
            if (self.enhancement_frames == 0) return error.@"No Enhancement Frames To Pop";
            self.enhancement_frames -= 1;
            try ProgressiveEnhancement.pop(self.writer);
        }

        const PopManyError = error{ @"Popped More Enhancement Frames Than Pushed", @"Cannot Pop Zero Enhancement Frames" } || WriterType.Error;

        /// pop many buffer stacks
        pub fn popMany(self: *Self, count: u8) PopManyError!void {
            if (count == 0) return error.@"Cannot Pop Zero Enhancement Frames";
            if (count > self.enhancement_frames) return error.@"Popped More Enhancement Frames Than Pushed";

            self.enhancement_frames -= count;
            try ProgressiveEnhancement.popMany(self.writer, count);
        }
    };
}

/// Create a Enhancement Manager for a specific writer.
/// This keeps track of the enhancement stack frames you push and pop so you don't
/// mess up other applications by leaving some frames over, or changing theirs.
///
/// Make sure you .deinit() to make sure you don't leave
/// enhancement frames behind.
pub fn enhancementStack(writer: anytype) EnhancementStack(@TypeOf(writer)) {
    return .{ .writer = writer };
}

/// Create a Enhancement Manager and immediately the enhancement onto the stack.
pub fn enhancementStackWithSet(writer: anytype, enhancement: ProgressiveEnhancement) EnhancementStack(@TypeOf(writer)).PushError!EnhancementStack(@TypeOf(writer)) {
    var self: EnhancementStack(@TypeOf(writer)) = .{ .writer = writer };
    try self.push(enhancement);
    return self;
}

test EnhancementStack {
    const expectError = testing.expectError;
    var write_buffer = std.ArrayList(u8).init(testing.allocator);
    defer write_buffer.deinit();

    const writer = write_buffer.writer();

    var man = enhancementStack(writer);

    try expectError(error.@"No Enhancement Frames To Pop", man.pop());
    try expectError(error.@"Popped More Enhancement Frames Than Pushed", man.popMany(1));

    for (0..155) |_| try man.push(.{});
    try expectError(error.@"Popped More Enhancement Frames Than Pushed", man.popMany(156));

    for (0..100) |_| try man.push(.{});
    try expectError(error.@"Too Many Enhancement Frames Pushed", man.push(.{}));

    try man.deinit();

    try testing.expectEqualStrings(write_buffer.items, (CSI ++ ">0u") ** 255 ++ CSI ++ "<255u");
}

/// Kitty's Progressive Enhancement:
/// https://sw.kovidgoyal.net/kitty/keyboard-protocol/
pub const ProgressiveEnhancement = packed struct(u5) {
    /// Disambiguate escape codes
    disambiguate: bool = false,
    /// Report event types
    event_types: bool = false,
    /// Report alternate keys
    alternate_keys: bool = false,
    /// Report all keys as escape codes
    keys_as_escape_codes: bool = false,
    /// Report associated text
    associated_text: bool = false,

    /// Sets the terminal's current progressive mode.
    /// Should only be used after you have pushed
    pub fn set(self: @This(), writer: anytype) @TypeOf(writer).Error!void {
        try writer.print(CSI ++ "={}u", .{@as(u5, @bitCast(self))});
    }

    /// Pushes a progressive onto the stack.
    /// Should only really be used once, and it should be poped whenever you are done using it.
    pub fn push(self: @This(), writer: anytype) @TypeOf(writer).Error!void {
        try writer.print(CSI ++ ">{}u", .{@as(u5, @bitCast(self))});
    }

    /// disables select progressive enhancements
    pub fn pop(writer: anytype) @TypeOf(writer).Error!void {
        try ProgressiveEnhancement.popMany(writer, 1);
    }

    /// pop many buffer stacks
    pub fn popMany(writer: anytype, count: usize) @TypeOf(writer).Error!void {
        try writer.print(CSI ++ "<{}u", .{count});
    }
};

const termi = @import("termi.zig");
const CSI = termi.escape_codes.CSI;

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
