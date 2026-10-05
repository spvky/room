// Event :: struct {
//     kind: Event_Kind;
// }

Event_Kind :: enum {
    NEW_ROOM;
    PLAYER_DEATH;
}

// Event_Proc :: #type (event: Event);
Timed_Event_Proc :: #type ();

Timed_Event :: struct {
    duration: float;
    current: float;
    proc: Timed_Event_Proc;
    triggered: bool;
}

Timed_Event_Manager :: struct {
    events: [..]Timed_Event;
}

#add_context timed_events: *Timed_Event_Manager;

init_events :: () #expand {
    init_timed_events();
}

init_timed_events :: () #expand {
    if !context.timed_events {
        context.timed_events = New(Timed_Event_Manager);
    }
}

advance_timed_events :: (delta: float) {
    for *context.timed_events.events {
        if it.triggered continue;
        it.current += delta;
        if it.current >= it.duration {
            it.proc();
            it.triggered = true;
        }
    }
}

remove_screen_effects :: (flags: Screen_Effect_Flags) {
    context.screen_effects.current_effects &= ~flags;
}

remove_screen_shake :: () {
    context.screen_effects.current_effects &= ~.SHAKE;
}
