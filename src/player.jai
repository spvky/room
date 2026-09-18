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

player_interaction :: () {
    player := player_get();
    entities_to_remove: [..]Entity_Handle;
    entities_to_remove.allocator = temp;
    for *context.entities {
        if !entity_has_props(it, .INTERACTABLE) || it == player continue;
        if distance(it.position, player.position) <= TILE_SIZE && is_action_buffered(.INTERACT) {
            if it.tag == {
            case .SWITCH_BLOCK_SWITCH;
                consume_action(.INTERACT);
                if entity_has_flags(it, .POWERED) {
                    it.flags &= ~.POWERED;
                } else {
                    it.flags |= .POWERED;
                }
            case .ASSEMBLER;
                consume_action(.INTERACT);
                if entity_has_flags(it, .POWERED) {
                    open_map_placement_screen();
                }
            case .ROOM_PICKUP;
                consume_action(.INTERACT);
                array_add(*context.map_screen_state.available_rooms, it.room_pickup_hash);
                array_add(*entities_to_remove, it.handle);
                room_ptr := table_find_pointer(context.room_table, it.room_pickup_hash);
                if room_ptr {
                    room_ptr.flags |= .PICKED_UP;
                }
            }
        }
    }
    if entities_to_remove.count > 0 {
        for entities_to_remove {
            entity_remove(it);
        }
    }
}

store_player :: () {
    assert(player_is_valid(), "Tried to store player and they didn't exist!\n");
    player := player_get();
    context.game_data.stored_player = player.*;
    context.game_data.has_stored_player = true;
}

restore_player :: () {
    assert(context.game_data.has_stored_player, "Tried to restore an unstored player!\n");
    context.player_handle.* = entity_add(context.game_data.stored_player);

    // Ground Sensor Entity
    gse: Entity;
    gse.offset = Vector2.{0, -TILE_SIZE / 2};
    gse.extents = Vector2.{TILE_SIZE * 0.8, TILE_SIZE / 8};
    gse.shape_kind = .RECTANGLE;
    gse.tag = .GROUND_SENSOR;
    gse.props = .SENSOR | .RELATIVE_POSITION | .RELATIVE_ROTATION;
    entity_add_child(context.player_handle.*, gse);

    // Left Ray Entity
    lre: Entity;
    lre.offset = Vector2.{(context.game_data.stored_player.radius * 0.9), 0};
    lre.tag = .WALL_CASTER;
    lre.ray.direction = .{1, 0};
    lre.ray.max_toi = 32.0;
    lre.props = .RAY_CASTER | .RELATIVE_POSITION | .RELATIVE_ROTATION;
    entity_add_child(context.player_handle.*, lre);
}
