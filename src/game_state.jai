Game_State :: enum u8 {
    MAP_PLACEMENT;
    GAMEPLAY;
    PAUSE_SCREEN;
    ROOM_DESIGNER;
}

Game_Data :: struct {
    has_stored_player: bool;
    stored_player: Entity;
}

#add_context game_state: Game_State;
#add_context game_data: *Game_Data;

init_game_data :: () {
    if !context.game_data {
        context.game_data = New(Game_Data);
    }
}

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
    if is_action_buffered(.GOTO_ROOM_DESIGNER) context.game_state = .ROOM_DESIGNER;
    if is_action_buffered(.GOTO_MAP_PLACEMENT) {
        consume_action(.GOTO_MAP_PLACEMENT);
        rooms_refresh();
        map_refresh();
        context.game_state = .MAP_PLACEMENT;
    }
    if is_action_buffered(.GOTO_GAMEPLAY) {
        consume_action(.GOTO_GAMEPLAY);
        context.game_data.has_stored_player = false;
        rooms_refresh();
        map_refresh();
        bake_world();
        snap_camera_pos();

        context.game_state = .GAMEPLAY;
    }
}
