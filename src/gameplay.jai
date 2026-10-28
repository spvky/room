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

gameplay_update :: (delta: float32) {
    death_state := context.player_data.state == .DYING;
    // Upkeep
    decay_crate_x_velocity();
    handle_power_conductivity();
    advance_timed_events(delta);
    // Camera
    camera_smoothing(delta);
    camera_follow();
    camera_look(delta);
    zoom_camera(delta);
    // Animation
    advance_animation_timers(delta);
    // handle_entity_sprite_sheets();

    if !death_state {
        // Numbers
        set_player_move_delta(delta);
        player_jump();
        set_relative_position_and_rotations();
        apply_movement_deltas();
        player_apply_speed(delta);
        moving_block_velocity();
        manage_floating_text(delta);

        // Collision
        sensor_collision();
        body_collision(delta);
        raycast_collision();
        handle_water_nodes();

        // Dynamics
        apply_gravity(delta);
        apply_velocity(delta);

        // Interaction
        player_interaction();
        manage_player_state();
    }

    inspector_entity_picking();

    // Cleanup
    table_reset(context.dynamic_collision_hashes);
}

advance_animation_timers :: (delta: float32) {
    animations := context.animations;
    advance_animation_player(*animations.player, delta);
    advance_animation_player(*animations.gears, delta);
}
