Entity_Event :: struct {
    using expensive_payload: Expensive_Event_Payload;
    #overlay (expensive_payload) using destroy_payload: Destroy_Entity_Payload;
}

Entity_Event_Type :: enum {
    DESTORY_ENTITY;
}

Destroy_Entity_Payload :: struct {
    handle_to_destroy: Entity_Handle;
}

Expensive_Event_Payload :: struct {
    a: int;
    b: int;
    c: int;
    d: int;
}

Entity_Event_Proc :: #type (handle: Entity_Handle) -> void;
Event_Proc :: #type ();

Timed_Entity_Event :: struct {
    target: Entity_Handle;
    duration: float;
    current: float;
    start_proc: Entity_Event_Proc;
    end_proc: Entity_Event_Proc;
}

Timed_Event :: struct {
    duration: float;
    current: float;
    proc: Event_Proc;
    triggered: bool;
}

Timed_Event_Manager :: struct {
    entity_events: [..]Timed_Entity_Event;
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
