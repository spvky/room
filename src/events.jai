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
