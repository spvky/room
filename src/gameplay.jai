gameplay_update :: (delta: float32) {
    // Upkeep
    decay_crate_x_velocity();
    handle_power_conductivity();
    // Camera
    camera_smoothing(delta);
    camera_follow();
    // Animation
    advance_animation_timers(delta);
    handle_entity_sprite_sheets();
    // Numbers
    set_player_move_delta();
    player_jump();
    set_relative_position_and_rotations();
    apply_movement_deltas();
    moving_block_velocity();
    manage_floating_text(delta);

    // Collision
    sensor_collision();
    body_collision();
    raycast_collision();

    // Dynamics
    apply_gravity(delta);
    apply_velocity(delta);

    // Interaction
    player_interaction();
    inspector_entity_picking();

    // Cleanup
    table_reset(context.dynamic_collision_hashes);
}

advance_animation_timers :: (delta: float32) {
    for *context.entities {
        if !entity_has_props(it, .ANIMATED) continue;
        advance_animation_player(*it.animation_player, delta);
    }
}

handle_entity_sprite_sheets :: () {
    for *context.entities {
        if it.render_kind != .SPRITE_SHEET continue;
        if it.tag == {
        case .SWITCH_BLOCK_SWITCH;
            if entity_has_flags(it, .POWERED) {
                it.sprite_sheet.idx = 9;
            } else {
                it.sprite_sheet.idx = 8;
            }
        }
    }
}
