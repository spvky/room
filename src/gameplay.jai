gameplay_update :: (delta: float32) {
    // Camera
    camera_smoothing(delta);
    camera_follow();
    // Animation
    advance_animation_timers(delta);
    // Numbers
    set_player_move_delta();
    player_jump();
    set_relative_position_and_rotations();
    apply_movement_deltas();

    // Collision
    sensor_collision();
    body_collision();
    raycast_collision();

    // Dynamics
    apply_gravity(delta);
    apply_velocity(delta);
}

advance_animation_timers :: (delta: float32) {
    for *context.entities {
        if !entity_has_props(it, .ANIMATED) continue;
        advance_animation_player(*it.animation_player, delta);
    }
}
