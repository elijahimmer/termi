/// Represents a single key press.
/// CSI unicode-key-code:alternate-key-codes ; modifiers:event-type ; text-as-codepoints u
pub const Key = struct {
    /// the unicode key code
    code: u16 = 0,
    /// a alternate key code
    alternate: ?u16 = 0,
    /// the key modifiers (shift, ctrl, etc.)
    modifier: KeyModifiers = .{},
    /// the event type
    event_type: KeyEventType = .press,
    /// the unicode code points
    code_points: ?u21 = 0,
};

/// The type of key event (.press is default)
pub const KeyEventType = enum(u2) {
    press = 1,
    repeat = 2,
    release = 3,
};

/// Modifiers https://sw.kovidgoyal.net/kitty/keyboard-protocol/#modifiers
/// shift     0b1         (1)
/// alt       0b10        (2)
/// ctrl      0b100       (4)
/// super     0b1000      (8)
/// hyper     0b10000     (16)
/// meta      0b100000    (32)
/// caps_lock 0b1000000   (64)
/// num_lock  0b10000000  (128)
pub const KeyModifiers = packed struct(u9) {
    shift: bool = false,
    alt: bool = false,
    ctrl: bool = false,
    super: bool = false,
    hyper: bool = false,
    meta: bool = false,
    caps_lock: bool = false,
    num_lock: bool = false,
    /// extra bit as it is given as 1 + the modifiers
    _: bool = false,
};
