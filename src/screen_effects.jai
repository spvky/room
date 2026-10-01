Screen_Effect_Handler :: struct {
    current_effects: Screen_Effect_Flags;

    NORMAL_SHAKE :: Vector2.{10, 15};

    shake_magnitude: Vector2 = NORMAL_SHAKE;
}

#add_context screen_effects: *Screen_Effect_Handler;

Screen_Effect_Flags :: enum_flags u8 {
    SHAKE :: 1 << 0;
}

init_screen_effects :: () {
    if !context.screen_effects {
        context.screen_effects = New(Screen_Effect_Handler);
    }
}

add_screen_shake :: (duration: float) {
    context.screen_effects.current_effects |= .SHAKE;
    array_add(*context.timed_events.events, Timed_Event.{duration = duration, proc = remove_screen_shake});
}
