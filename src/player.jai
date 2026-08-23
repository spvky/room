#add_context player_handle: *Entity_Handle;

init_player :: () {
    if !context.player_handle {
        context.player_handle = New(Entity_Handle);
    }
}

player_is_valid :: () -> bool {
    return entity_valid(context.player_handle.*);
}

player_get :: () -> *Entity {
    return entity_get(context.player_handle.*);
}

set_player_move_delta :: () {
    player := player_get();
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
        // print("Delta: %\n", player.movement_delta.x);
    }
}

player_jump :: () {
    player := player_get();
    c, in_bounds := calculate_map_coord_from_position(player.position);
    if in_bounds {
        context.camera.target = Vector2.{xx c.x * (TILE_SIZE * 23), xx c.y * (TILE_SIZE * 23)} + Vector2.{-54, 12};
    }

    if is_action_buffered(.JUMP) && entity_has_flags(player, .GROUNDED) {
        consume_action(.JUMP);
        player.velocity.y = PLAYER_JUMP_SPEED;
    }
}
