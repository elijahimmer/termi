//! A general manager for terminal state like:
//!     Terminal mode,
//!     Progressive Enhancement,
//!     Alternate Buffer,
//!     Bracketed Paste,
//!
//! And resets anything that has be set with `deinit`.

pub const TermManager = @This();

pub const WriterType = File.Writer;
pub const ReaderType = File.Reader;

writer: WriterType,
reader: ReaderType,
progressive_state: ProgressiveState = .unverified,
mode_start: ?posix.termios = null,
bracketed_set: bool = false,

const ProgressiveState = enum {
    unverified,
    unsupported,
    supported,
    set,
};

pub const WriteError = WriterType.Error;
pub const ReadError = ReaderType.NoEofError;

/// Initializes the TermManager.
/// Should call deinit to clean up any changes.
pub fn init(stdout: WriterType, stdin: ReaderType) TermManager {
    return .{ .writer = stdout, .reader = stdin };
}

/// clean up changes made by TermManager.
pub fn deinit(self: *TermManager) (WriteError || TermiosSetError)!void {
    try self.progressiveReset();
    try self.modeReset();
    try self.bracketedPasteUnset();
}

/// verifies if progressive is supported or not.
/// Returns true if it is.
/// All input in the reader will be discarded up to the response this is looking for.
pub fn progressiveVerify(self: *TermManager) (WriteError || ReadError)!bool {
    return try ProgressiveEnhancement.supported(self.writer, self.reader);
}

/// sets the progressive state.
/// This will silently fail when Progressive Enhancement isn't supported.
/// To know if it is supported, try progressive_verify.
pub fn progressiveSet(self: *TermManager, mode: ProgressiveEnhancement) (WriteError || ReadError)!void {
    switch (self.progressive_state) {
        .unverified => if (!try self.progressiveVerify()) return,
        .unsupported => return,
        else => {},
    }

    try mode.set(self.writer);

    self.progressive_state = .set;
}

/// resets the progressive state.
/// This won't do anything if the progressive was not set through this,
/// or if it is unsupported.
pub fn progressiveReset(self: *TermManager) WriteError!void {
    if (@as(ProgressiveState, self.progressive_state) == .set) {
        try ProgressiveEnhancement.pop(self.writer);
        self.progressive_state = .supported;
    }
}

/// sets the terminal to raw mode
pub fn modeSetRaw(self: *TermManager) (TermiosGetError || TermiosSetError)!void {
    var term_raw = try self.modeGet();

    term_raw.iflag = .{
        .ICRNL = true,
        .IUTF8 = true,
    };
    term_raw.oflag = .{};
    term_raw.cflag = .{};
    term_raw.lflag = .{};

    try posix.tcsetattr(self.writer.context.handle, .NOW, term_raw);
}

/// gets the terminal's termios mode. This just call's posix's tcgetattr
pub fn modeGet(self: *TermManager) TermiosGetError!termios {
    const mode = try posix.tcgetattr(self.writer.context.handle);
    if (self.mode_start == null) self.mode_start = mode;

    return mode;
}

/// sets the terminal's termios mode. This just call's posix's tcsetattr
/// and keeps track of the original state of the terminal.
pub fn modeSet(self: *TermManager, mode: termios) (TermiosSetError || TermiosGetError)!void {
    if (self.mode_start == null) _ = try self.modeGet();
    try posix.tcsetattr(self.writer.context.handle, .NOW, mode);
}

/// resets the terminal's mode, if it was set.
pub fn modeReset(self: *TermManager) posix.TermiosSetError!void {
    if (self.mode_start) |m| try posix.tcsetattr(self.writer.context.handle, .NOW, m);
}

/// sets bracketed paste mode if it was not set yet.
pub fn bracketedPasteSet(self: *TermManager) WriteError!void {
    if (!self.bracketed_set) {
        try self.writer.print(CSI ++ "?2004h", .{});
        self.bracketed_set = false;
    }
}

/// unsets bracketed paste mode if it was set previously
pub fn bracketedPasteUnset(self: *TermManager) WriteError!void {
    if (self.bracketed_set) {
        try self.bracketedPasteUnsetAssumeSet();
        self.bracketed_set = false;
    }
}

/// always unsets the bracketed paste mode
pub fn bracketedPasteUnsetAssumeSet(self: *TermManager) WriteError!void {
    try self.writer.print(CSI ++ "?2004l", .{});
}

test {
    @import("std").testing.refAllDecls(@This());
}

const termi = @import("termi.zig");
const ProgressiveEnhancement = termi.ProgressiveEnhancement;
const CSI = termi.chars.CSI;

const std = @import("std");
const File = std.fs.File;
const posix = std.posix;
const TermiosGetError = posix.TermiosGetError;
const TermiosSetError = posix.TermiosSetError;
const termios = posix.termios;
