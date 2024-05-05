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
bracketede_paste_set: bool = false,
alternate_buffer_set: bool = false,

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
/// This errors if the input files are not ttys.
pub fn init(stdout: File, stdin: File) error{NotATerminal}!TermManager {
    if (!posix.isatty(stdout.handle) and !posix.isatty(stdin.handle)) return error.NotATerminal;
    return .{ .writer = stdout.writer(), .reader = stdin.reader() };
}

/// clean up changes made by TermManager.
/// This deinits everything, even if it errors, returning the errors after.
pub fn deinit(self: *TermManager) (WriteError || TermiosSetError)!void {
    const err1 = self.progressiveReset();
    const err2 = self.modeReset();
    const err3 = self.bracketedPasteUnset();
    const err4 = self.alternateBufferLeave();

    try err1;
    try err2;
    try err3;
    try err4;
}

/// verifies if progressive is supported or not.
/// Returns true if it is.
/// All input in the reader will be discarded up to the response this is looking for.
pub fn progressiveVerify(self: *TermManager) (WriteError || ReadError)!bool {
    return try ProgressiveEnhancement.supported(self.writer, self.reader);
}

/// sets the progressive state.
/// This will silently fail when Progressive Enhancement isn't supported.
/// To know if it is supported, try progressiveVerify.
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

/// Records the terminal's start mode if it hasn't already
pub fn modeGetStartState(self: *TermManager) TermiosGetError!termios {
    if (self.mode_start) |m| return m else {
        self.mode_start = try posix.tcgetattr(self.writer.context.handle);
        return self.mode_start.?;
    }
}

/// Gets the terminal's termios mode,
/// as well as keeping track of the terminal's original state before changes.
pub fn modeGet(self: *TermManager) TermiosGetError!termios {
    const mode = try posix.tcgetattr(self.writer.context.handle);
    if (self.mode_start == null) self.mode_start = mode;

    return mode;
}

/// sets the terminal to raw mode
pub fn modeSetRaw(self: *TermManager) (TermiosGetError || TermiosSetError)!void {
    var term_raw = try self.modeGetStartState();

    term_raw.iflag = .{
        .ICRNL = true,
        .IUTF8 = true,
    };
    term_raw.oflag = .{};
    term_raw.cflag = .{};
    term_raw.lflag = .{};

    try posix.tcsetattr(self.writer.context.handle, .NOW, term_raw);
}

/// sets the terminal's termios mode.
/// and keeps track of the original state of the terminal.
pub fn modeSet(self: *TermManager, mode: termios) (TermiosSetError || TermiosGetError)!void {
    if (self.mode_start == null) _ = try self.modeGetStartState();
    try posix.tcsetattr(self.writer.context.handle, .NOW, mode);
}

/// resets the terminal's mode, if it was set.
pub fn modeReset(self: *TermManager) posix.TermiosSetError!void {
    if (self.mode_start) |m| try posix.tcsetattr(self.writer.context.handle, .NOW, m);
}

/// sets bracketed paste mode if you haven't already
pub fn bracketedPasteSet(self: *TermManager) WriteError!void {
    if (!self.bracketede_paste_set) {
        try Command.bracketed_paste_set.print(self.writer, .{});
        self.bracketede_paste_set = true;
    }
}

/// unsets bracketed paste mode if you've entered it
pub fn bracketedPasteUnset(self: *TermManager) WriteError!void {
    if (self.bracketede_paste_set) {
        try Command.bracketed_paste_unset.print(self.writer, .{});
        self.bracketede_paste_set = false;
    }
}

/// enters a alternate screen buffer if not in one already (not always supported)
pub fn alternateBufferEnter(self: *TermManager) WriteError!void {
    if (!self.alternate_buffer_set) {
        try Command.alternate_buffer_enter.print(self.writer, .{});
        self.alternate_buffer_set = true;
    }
}

/// leaves a alternate screen buffer if you have entered one (not always supported)
pub fn alternateBufferLeave(self: *TermManager) WriteError!void {
    if (self.alternate_buffer_set) {
        try Command.alternate_buffer_leave.print(self.writer, .{});
        self.alternate_buffer_set = false;
    }
}

/// sends any command to the terminal. This does not keep track of commands sent,
/// so sending through this will not keep track of the state properly. Use well.
pub fn sendCommand(self: TermManager, comptime command: Command, args: anytype) WriteError!void {
    try command.print(self.writer, args);
}

const termi = @import("root.zig");
const ProgressiveEnhancement = termi.ProgressiveEnhancement;
const Command = termi.Command;

const std = @import("std");
const File = std.fs.File;
const posix = std.posix;
const TermiosGetError = posix.TermiosGetError;
const TermiosSetError = posix.TermiosSetError;
const termios = posix.termios;
