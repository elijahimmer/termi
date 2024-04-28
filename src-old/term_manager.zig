pub fn TermManager(comptime WriterType: type, comptime ReaderType: type) type {
    return struct {
        writer: WriterType,
        reader: ReaderType,
        start_mode: ?posix.termios = null,
        progressive_mode: ProgressiveMode = .unverified,
        alternate_screen_set: bool = false,

        const ProgressiveMode = enum {
            unverified,
            unsupported,
            supported,
            set,
        };

        const Self = @This();
        pub const WriteError = WriterType.Error;
        pub const ReadError = ReaderType.NoEofError;

        /// restores the terminal to how it was before
        /// modifications
        pub fn deinit(self: *Self) (posix.TermiosSetError || WriteError)!void {
            try self.resetMode();
            try self.resetProgressive();
            try self.leaveAlternateScreen();
        }

        pub const SetModeError = posix.TermiosSetError || posix.TermiosGetError;

        /// Sets to terminal mode to 'raw'
        pub fn setRawMode(self: *Self) SetModeError!void {
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
        pub fn setMode(self: *Self, mode: posix.termios) SetModeError!void {
            if (self.start_mode == null) self.start_mode = try posix.tcgetattr(self.writer);

            try posix.tcsetattr(self.writer, .NOW, mode);
        }

        /// Restores the terminal to where it was before modification
        /// with `set_raw_mode` or `set_mode`. Safe to use even if no mode was set.
        pub fn resetMode(self: *Self) SetModeError!void {
            if (self.start_mode) |m| try posix.tcsetattr(self.writer.context.handle, .NOW, m);
        }

        /// Set the progressive mode
        pub fn setProgressive(self: *Self, enhance: ProgressiveEnhancement) (WriteError || ReadError)!void {
            switch (self.progressive_mode) {
                .unverified => {
                    if (!try self.verifyProgressive()) return;
                },
                .unsupported => return,
                else => {},
            }

            try self.setProgressiveAssumeSupported(enhance);
        }

        pub fn setProgressiveAssumeSupported(self: *Self, enhance: ProgressiveEnhancement) WriteError!void {
            switch (self.progressive_mode) {
                .set => try enhance.set(self.writer),
                else => try enhance.push(self.writer),
            }
            self.progressive_mode = .set;
        }

        /// Remove any trace of the progressive changes.
        /// Safe to use even without setting progression
        pub fn resetProgressive(self: *Self) WriteError!void {
            if (self.progressive_mode == .set) {
                try ProgressiveEnhancement.pop(self.writer);
                self.progressive_mode = .supported;
            }
        }

        /// verifies whether or not progressive enhancement is supported
        /// If you forced progressive state with setProgressiveAssumeSupported,
        /// yet it is not supported, this will reset the progressive state.
        pub fn verifyProgressive(self: *Self) (WriteError || ReadError)!bool {
            const supported = try ProgressiveEnhancement.supported(self.writer, self.reader);
            if (supported) {
                if (self.progressive_mode != .set) self.progressive_mode = .supported;
            } else {
                if (self.progressive_mode == .set) try ProgressiveEnhancement.pop(self.writer);
                self.progressive_mode = .unsupported;
            }
            return supported;
        }

        pub fn enterAlternateScreen(self: *Self) WriteError!void {
            if (!self.alternate_screen_set) {
                try ec.print_command(self.writer, .enter_alternate_screen, .{});
                self.alternate_screen_set = true;
            }
        }
        pub fn leaveAlternateScreen(self: *Self) WriteError!void {
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

pub fn termManager(writer: anytype, reader: anytype) TermManager(@TypeOf(writer), @TypeOf(reader)) {
    return .{ .writer = writer, .reader = reader };
}

const termi = @import("termi.zig");
const ProgressiveEnhancement = termi.ProgressiveEnhancement;
const term_mode = termi.term_mode;
const ec = termi.escape_codes;

const std = @import("std");
const posix = std.posix;
const assert = std.debug.assert;
const testing = std.testing;
