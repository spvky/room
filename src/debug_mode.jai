Debug_Mode_State :: struct {
    on: bool;
}

#add_context debug_mode: *Debug_Mode_State;

init_debug_mode :: () {
    if !context.debug_mode {
        context.debug_mode = New(Debug_Mode_State);
    }
}
