Game_State :: enum u8 {
    MAP_PLACEMENT;
    GAMEPLAY;
    PAUSE_SCREEN;
    ROOM_DESIGNER;
    ROOM_EDITOR;
}

#add_context game_state: Game_State;

in_game_state :: (state: Game_State) -> bool #expand {
    return context.game_state == state;
}

open_map_placement_screen :: () {
    store_player();
    context.game_state = .MAP_PLACEMENT;
}

exit_map_placement_screen :: () {
    bake_world();
    restore_player();
    snap_camera_pos();
    context.game_state = .GAMEPLAY;
}

game_state_update :: () {
    if is_action_buffered(.GOTO_MAP_PLACEMENT) {
        consume_action(.GOTO_MAP_PLACEMENT);
        rooms_refresh();
        map_refresh();
        context.game_state = .MAP_PLACEMENT;
    }
    if is_action_buffered(.GOTO_ROOM_EDITOR) {
        consume_action(.GOTO_ROOM_EDITOR);
        context.game_state = .ROOM_EDITOR;
    }
    if is_action_buffered(.GOTO_GAMEPLAY) {
        consume_action(.GOTO_GAMEPLAY);
        context.player_data.has_stored_player = false;
        rooms_refresh();
        map_refresh();
        bake_world();
        context.game_state = .GAMEPLAY;
        snap_camera_pos();
    }

    if is_action_buffered(.TOGGLE_DEBUG_MODE) {
        consume_action(.TOGGLE_DEBUG_MODE);
        context.debug_mode.on = !context.debug_mode.on;
    }
}
