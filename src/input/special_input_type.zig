pub const SpecialInputType = enum {
    escape, // 27 u
    enter, // 13 u
    tab, // 9 u
    backspace, // 127 u
    insert, // 2 u
    delete, // 3 ~
    up, // 1 A
    down, // 1 B
    right, // 1 C
    left, // 1 D
    page_up, // 5 ~
    page_down, // 6 ~
    home, // 1 H or 7 ~
    end, // 1 F or 8 ~
    caps_lock, // 57358 u
    scroll_lock, //57359 u
    num_lock, //57360 u
    print_screen, //57361 u
    pause, //57362 u
    menu, //57363 u
    F1, //1 P or 11 ~
    F2, //1 Q or 12 ~
    F3, //13 ~
    F4, //1 S or 14 ~
    F5, //15 ~
    F6, //17 ~
    F7, //18 ~
    F8, //19 ~
    F9, //20 ~
    F10, //21 ~
    F11, //23 ~
    F12, //24 ~
    F13, //57376 u
    F14, //57377 u
    F15, //57378 u
    F16, //57379 u
    F17, //57380 u
    F18, //57381 u
    F19, //57382 u
    F20, //57383 u
    F21, //57384 u
    F22, //57385 u
    F23, //57386 u
    F24, //57387 u
    F25, //57388 u
    F26, //57389 u
    F27, //57390 u
    F28, //57391 u
    F29, //57392 u
    F30, //57393 u
    F31, //57394 u
    F32, //57395 u
    F33, //57396 u
    F34, //57397 u
    F35, //57398 u
    kp_0, //57399 u
    kp_1, //57400 u
    kp_2, //57401 u
    kp_3, //57402 u
    kp_4, //57403 u
    kp_5, //57404 u
    kp_6, //57405 u
    kp_7, //57406 u
    kp_8, //57407 u
    kp_9, //57408 u
    kp_decimal, //57409 u
    kp_divide, //57410 u
    kp_multiply, //57411 u
    kp_subtract, //57412 u
    kp_add, //57413 u
    kp_enter, //57414 u
    kp_equal, //57415 u
    kp_separator, //57416 u
    kp_left, //57417 u
    kp_right, //57418 u
    kp_up, //57419 u
    kp_down, //57420 u
    kp_page_up, //57421 u
    kp_page_down, //57422 u
    kp_home, //57423 u
    kp_end, //57424 u
    kp_insert, //57425 u
    kp_delete, //57426 u
    kp_begin, //1 E or 57427 ~
    media_play, //57428 u
    media_pause, //57429 u
    media_play_pause, //57430 u
    media_reverse, //57431 u
    media_stop, //57432 u
    media_fast_forward, //57433 u
    media_rewind, //57434 u
    media_track_next, //57435 u
    media_track_previous, //57436 u
    media_record, //57437 u
    lower_volume, //57438 u
    raise_volume, //57439 u
    mute_volume, //57440 u
    left_shift, //57441 u
    left_control, //57442 u
    left_alt, //57443 u
    left_super, //57444 u
    left_hyper, //57445 u
    left_meta, //57446 u
    right_shift, //57447 u
    right_control, //57448 u
    right_alt, //57449 u
    right_super, //57450 u
    right_hyper, //57451 u
    right_meta, //57452 u
    iso_level3_shift, //57453 u
    iso_level5_shift, //57454 u
};
