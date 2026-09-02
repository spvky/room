Player_Data :: struct {
    last_stable_ground: Vector2;
}

#add_context player_handle: *Entity_Handle;
#add_context player_data: *Player_Data;

init_player :: () {
    if !context.player_handle {
        context.player_handle = New(Entity_Handle);
    }

    if !context.player_data {
        context.player_data = New(Player_Data);
    }
}

player_is_valid :: () -> bool {
    return entity_valid(context.player_handle.*);
}

player_get :: () -> *Entity {
    return entity_get(context.player_handle.*);
}

reset_player :: () {
    print("Resetting Player: %\n", context.player_data.last_stable_ground);
    player := player_get();
    player.movement_delta = .{};
    player.position = context.player_data.last_stable_ground;
    player.velocity = .{};
}

set_player_move_delta :: () {
    player := player_get();
    c, in_bounds := calculate_map_coord_from_position(player.position);
    if in_bounds then context.camera.target_room = c;
    if player.state == {
    case .MOVING;
        #through;
    case .STAND;
        #through;
    case .RISING;
        #through;
    case .FALLING;
        x: float32;
        if is_action_held(.MOVE_LEFT) {
            x -= 1;
        }
        if is_action_held(.MOVE_RIGHT) {
            x += 1;
        }

        player.movement_delta.x = x;
    }
}

player_jump :: () {
    player := player_get();
    if is_action_buffered(.JUMP) && entity_has_flags(player, .GROUNDED) {
        consume_action(.JUMP);
        player.velocity.y = PLAYER_JUMP_SPEED;
    }
}
