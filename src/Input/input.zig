pub const raw = @import("raw.zig");
pub const RawInputTag = raw.RawInputTag;
pub const RawInput = raw.RawInput;
pub const RawInputEscaped = raw.RawInputEscaped;
pub const RawInputCsi = raw.RawInputCsi;
pub const readOneEventRaw = raw.readOneEventRaw;

pub const event = @import("event.zig");
pub const Input = event.Input;
pub const InputEvent = event.InputEvent;
pub const InputCode = event.InputCode;
pub const InputCodeTag = event.InputCodeTag;
pub const InputUnicode = event.InputUnicode;
pub const InputModifiers = event.InputModifiers;
pub const InputModifiersTag = event.InputModifiersTag;

pub const parse = @import("parse.zig");
pub const parseRawInputCsi = parse.parseRawInputCsi;

pub const special = @import("special.zig");
pub const InputSpecial = special.InputSpecial;

test {
    std.testing.refAllDecls(@This());
}

const std = @import("std");
