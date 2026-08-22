gameplay_update :: (delta: float32) {
    // Numbers
    set_player_move_delta();
    player_jump();
    set_relative_position_and_rotations();
    apply_movement_deltas();

    // Collision
    sensor_collision();
    body_collision();

    // Dynamics
    apply_gravity(delta);
    apply_velocity(delta);
}
