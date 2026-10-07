DECEL_THRESHOLD :: 0.2;
TIME_TO_MAX_SPEED :: 1;

Player_Data :: struct {
    current_coord: Coord;
    last_stable_ground: Vector2;
    last_room_started_coord: Coord;
    last_room_started_pos: Vector2;
    state: Player_State;
    prev_state: Player_State;
    timers: Timer_Collection;
    stored_player: Entity;
    current_room: Coord;
    current_position: Vector2;
    has_stored_player: bool;
}

Player_State :: enum {
    IDLE;
    RUN;
    PUSH;
    RISE;
    FALL;
}

Timer_Collection :: struct {
    CARDINALITY :: #run -> int {
        info := cast(*Type_Info_Enum)Timer_Type;
        return info.values.count;
    }
    values: [CARDINALITY]float;
}

Timer_Type :: enum u8 {
    SPRINT;
    DECELERATE;
    LOOK_DOWN;
    LOOK_UP;
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

get_player_timer_value :: (type: Timer_Type) -> float #expand {
    return context.player_data.timers.values[type];
}

set_player_timer_value :: (type: Timer_Type, value: float) #expand {
    context.player_data.timers.values[type] = value;
}

increase_player_timer_value :: (type: Timer_Type, delta: float) #expand {
    context.player_data.timers.values[type] += delta;
}

player_is_valid :: () -> bool {
    return entity_valid(context.player_handle.*);
}

player_get :: () -> *Entity {
    return entity_get(context.player_handle.*);
}

reset_player :: () {
    restore_snapshot();
    print("Resetting Player: %\n", context.player_data.last_stable_ground);
}

manage_player_state :: () {
    player := player_get();
    data := context.player_data;
    state: Player_State;

    if entity_has_flags(player, .GROUNDED) {
        if abs(player.movement_delta.x) > 0 {
            state = .RUN;
        } else {
            state = .IDLE;
        }
    } else {
        if player.velocity.y >= 0 then state = .RISE; else state = .FALL;
    }
    data.prev_state = data.state;
    data.state = state;
}

set_player_move_delta :: (delta: float) {
    player := player_get();
    if player {
        c, in_bounds := calculate_map_coord_from_position(player.position);
        if in_bounds {
            context.camera.target_room = c;
        }
        x: float32;
        if is_action_held(.MOVE_LEFT) {
            x -= 1;
        }
        if is_action_held(.MOVE_RIGHT) {
            x += 1;
        }

        if entity_has_flags(player, .GROUNDED) {
            if x == 0 {
                increase_player_timer_value(.DECELERATE, delta);
            } else {
                decel_value := get_player_timer_value(.DECELERATE);
                if decel_value >= DECEL_THRESHOLD {
                    set_player_timer_value(.SPRINT, 0);
                }
                set_player_timer_value(.DECELERATE, 0);
                increase_player_timer_value(.SPRINT, delta);
            }
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
    for *context.entities {
        if !entity_has_props(it, .INTERACTABLE) || it == player continue;
        if distance(it.position, player.position) <= TILE_SIZE && is_action_buffered(.INTERACT) {
            if it.tag == {
            case .LEVER;
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
                room_ptr := table_find_pointer(context.room_table, it.room_pickup_hash);
                has_been_picked_up := room_ptr.flags & .PICKED_UP == .PICKED_UP;
                if !has_been_picked_up {
                    consume_action(.INTERACT);
                    array_add(*context.map_screen_state.available_rooms, it.room_pickup_hash);
                    room_ptr := table_find_pointer(context.room_table, it.room_pickup_hash);
                    if room_ptr {
                        room_ptr.flags |= .PICKED_UP;
                    }
                }
            }
        }
    }
}

player_apply_speed :: () {
    player := player_get();
    if !player {
        print("Failed to find player, skipping player_apply_speed!\n");
        return;
    }
    player_move_speed: float;
    clamped_sprint_timer := clamp(get_player_timer_value(.SPRINT), 0, TIME_TO_MAX_SPEED);
    // speed_base :=
    if player.movement_delta.x == 0 {
        player.velocity.x = 0;
    } else {
        player.velocity.x = player.movement_delta.x * PLAYER_BASE_MOVE_SPEED;
    }
}

make_player :: (position: Vector2, map_coord: Coord, e := context.entities) -> Entity_Handle {
    print("Player Spawning in Room: %\n", map_coord);
    entity: Entity;
    half_tile := Vector2.{TILE_SIZE, TILE_SIZE} / 2;
    entity.position = position;
    entity.current_room = map_coord;
    entity.shape_kind = .CIRCLE;
    entity.radius = TILE_SIZE / 2;
    entity.tag = .PLAYER;
    entity.props = .RENDERABLE | .GRAVITY_AFFECTED | .DYNAMIC | .SELF_PROPELLED | .PRESSES_BUTTONS | .NO_HANDLE_REFRESH;
    entity.render_kind = .SPRITE;
    entity.sprite = sprite(6);
    entity.render_extents = Vector2.{TILE_SIZE, TILE_SIZE};
    entity.movement_delta.x = 0;
    player_handle := entity_add(entity, e = e);

    // Ground Sensor Entity
    gse: Entity;
    gse.offset = Vector2.{0, -TILE_SIZE / 2};
    gse.extents = Vector2.{TILE_SIZE * 0.8, TILE_SIZE / 8};
    gse.shape_kind = .RECTANGLE;
    gse.tag = .GROUND_SENSOR;
    gse.props = .SENSOR | .RELATIVE_POSITION | .RELATIVE_ROTATION | .NO_HANDLE_REFRESH;
    entity_add_child(player_handle, gse, e = e);

    // Left Ray Entity
    lre: Entity;
    lre.offset = Vector2.{(entity.radius * 0.9), 0};
    lre.tag = .WALL_CASTER;
    lre.ray.direction = .{1, 0};
    lre.ray.max_toi = 32.0;
    lre.props = .RAY_CASTER | .RELATIVE_POSITION | .RELATIVE_ROTATION | .NO_HANDLE_REFRESH;
    entity_add_child(player_handle, lre, e = e);
    return player_handle;
}

store_player :: () {
    assert(player_is_valid(), "Tried to store player and they didn't exist!\n");
    player := player_get();
    context.player_data.current_room = context.camera.target_room;
    context.player_data.current_position = player.position;
    context.player_data.stored_player = player.*;
    context.player_data.has_stored_player = true;
}

restore_player :: () {
    assert(context.player_data.has_stored_player, "Tried to restore an unstored player!\n");
    context.player_handle.* = entity_add(context.player_data.stored_player);

    // Ground Sensor Entity
    gse: Entity;
    gse.offset = Vector2.{0, -TILE_SIZE / 2};
    gse.extents = Vector2.{TILE_SIZE * 0.8, TILE_SIZE / 8};
    gse.shape_kind = .RECTANGLE;
    gse.tag = .GROUND_SENSOR;
    gse.props = .SENSOR | .RELATIVE_POSITION | .RELATIVE_ROTATION;
    entity_add_child(context.player_handle.*, gse);
}
