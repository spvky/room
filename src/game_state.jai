Game_State :: enum u8 {
    MAP_PLACEMENT;
    GAMEPLAY;
    PAUSE_SCREEN;
    ROOM_DESIGNER;
}

#add_context game_state: Game_State;

in_game_state :: (state: Game_State) -> bool #expand {
    return context.game_state == state;
}

game_state_update :: () {
    if is_action_buffered(.GOTO_ROOM_DESIGNER) context.game_state = .ROOM_DESIGNER;
    if is_action_buffered(.GOTO_MAP_PLACEMENT) context.game_state = .MAP_PLACEMENT;
    if is_action_buffered(.GOTO_GAMEPLAY) context.game_state = .GAMEPLAY;
}
