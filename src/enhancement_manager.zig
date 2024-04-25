pub fn EnhancementManager(comptime WriterType: type) type {
    return struct {
        writer: WriterType,
        stack_frames: u8 = 0,

        const Self = @This();

        pub fn deinit(self: *Self) void {
            assert(self.stack_frames == 0);
        }

        pub fn deinitPopFrames(self: *Self) WriterType.Error!void {
            if (self.stack_frames > 0) try self.pop_many(self.stack_frames);
            assert(self.stack_frames == 0);
        }

        /// asserts you have pushed your own stack frame before using it
        pub fn set(self: *Self, enhancement: ProgressiveEnhancement) WriterType.Error!void {
            assert(self.stack_frames > 0); // you should only set while you have a stack frame pushed.
            try self.writer.print(CSI ++ "={}u", .{@as(u5, @bitCast(enhancement))});
        }

        /// Pushes a progressive onto the stack.
        /// Should only really be used once, and it should be poped whenever you are done using it.
        pub fn push(self: *Self, enhancement: ProgressiveEnhancement) WriterType.Error!void {
            assert(self.stack_frames < std.math.maxInt(@TypeOf(self.stack_frames))); // you shouldn't have this many frames pushed...
            self.stack_frames += 1;
            try self.writer.print(CSI ++ ">{}u", .{@as(u5, @bitCast(enhancement))});
        }

        /// disables select progressive enhancements
        pub fn pop(self: *Self) WriterType.Error!void {
            assert(self.stack_frames > 0); // you didn't push before you pop-ed
            self.stack_frames -= 1;
            self.pop_many_progressive(1);
        }

        /// pop many buffer stacks
        pub fn pop_many(self: *Self, count: u8) WriterType.Error!void {
            assert(count > 0);
            assert(self.stack_frames >= count); // you pop-ed more than you pushed
            self.stack_frames -= count;
            try self.writer.print(CSI ++ "<{}u", .{count});
        }
    };
}

pub fn enhancementManager(writer: anytype) EnhancementManager(@TypeOf(writer)) {
    return .{ .writer = writer };
}
pub fn enhancementManagerWithSet(writer: anytype, enhancement: ProgressiveEnhancement) @TypeOf(writer).Error!EnhancementManager(@TypeOf(writer)) {
    var self: EnhancementManager(@TypeOf(writer)) = .{ .writer = writer };
    try self.push(enhancement);
    return self;
}

test EnhancementManager {}

pub const termi = @import("termi.zig");
const ProgressiveEnhancement = termi.ProgressiveEnhancement;
const CSI = termi.escape_codes.CSI;

const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
