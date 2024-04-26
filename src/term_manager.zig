pub fn TermManager(comptime WriterType: type) type {
    return struct {
        writer: WriterType,
        start_mode: ?posix.termios = null,
        progerssive_was_set: bool = false,
        alternate_screen_set: bool = false,

        const Self = @This();
        pub const WriteError = WriterType.Error;

        /// restores the terminal to how it was before
        /// modifications
        pub fn deinit(self: *Self) (posix.TermiosSetError || WriteError)!void {
            try self.reset_mode();
            try self.reset_progressive();
            try self.leave_alternate_screen();
        }

        pub const SetModeError = posix.TermiosSetError || posix.TermiosGetError;

        /// Sets to terminal mode to 'raw'
        pub fn set_raw_mode(self: *Self) SetModeError!void {
            var term_raw = try posix.tcgetattr(self.writer.context.handle);

            if (self.start_mode == null) self.start_mode = term_raw;

            term_raw.iflag = .{
                .ICRNL = true,
                .IUTF8 = true,
            };
            term_raw.oflag = .{};
            term_raw.cflag = .{};
            term_raw.lflag = .{};

            try posix.tcsetattr(self.writer.context.handle, .NOW, term_raw);
        }

        /// Sets the terminal mode to specified
        pub fn set_mode(self: *Self, mode: posix.termios) SetModeError!void {
            if (self.start_mode == null) self.start_mode = try posix.tcgetattr(self.writer);

            try posix.tcsetattr(self.writer, .NOW, mode);
        }

        /// Restores the terminal to where it was before modification
        /// with `set_raw_mode` or `set_mode`. Safe to use even if no mode was set.
        pub fn reset_mode(self: *Self) SetModeError!void {
            if (self.start_mode) |m| try posix.tcsetattr(self.writer.context.handle, .NOW, m);
        }

        /// Set the progressive mode
        pub fn set_progressive(self: *Self, enhance: ProgressiveEnhancement) WriteError!void {
            try enhance.set(self.writer);
            self.progerssive_was_set = true;
        }

        /// Remove any trace of the progressive changes.
        /// Safe to use even without setting progression
        pub fn reset_progressive(self: *Self) WriteError!void {
            if (self.progerssive_was_set) {
                try ProgressiveEnhancement.pop(self.writer);
                self.progerssive_was_set = false;
            }
        }

        pub fn enter_alternate_screen(self: *Self) WriteError!void {
            if (!self.alternate_screen_set) {
                try ec.print_command(self.writer, .enter_alternate_screen, .{});
                self.alternate_screen_set = true;
            }
        }
        pub fn leave_alternate_screen(self: *Self) WriteError!void {
            if (self.alternate_screen_set) {
                try ec.print_command(self.writer, .leave_alternate_screen, .{});
                self.alternate_screen_set = false;
            }
        }

        pub fn clear(self: *Self) WriteError!void {
            try ec.print_command(self.writer, .erase_screen, .{});
        }
    };
}

pub fn termManager(writer: anytype) TermManager(@TypeOf(writer)) {
    return .{ .writer = writer };
}

const termi = @import("termi.zig");
const ProgressiveEnhancement = termi.ProgressiveEnhancement;
const term_mode = termi.term_mode;
const ec = termi.escape_codes;

const std = @import("std");
const posix = std.posix;
const assert = std.debug.assert;
const testing = std.testing;
