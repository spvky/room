DECEL_THRESHOLD :: 0.2;
TIME_TO_MAX_SPEED :: 1.2;
SKID_MULTIPLIER :: 8;

Player_Data :: struct {
    current_coord: Coord;
    last_stable_ground: Vector2;
    last_room_started_coord: Coord;
    last_room_started_pos: Vector2;
    friction: float = 25.0;
    current_speed: float;
    speed_to_add: float;
    state: Player_State;
    prev_state: Player_State;
    timers: Timer_Collection;
    stored_player: Entity;
    current_room: Coord;
    current_position: Vector2;
    has_stored_player: bool;
    player_flags: Player_Temp_Flags;
    facing_right: bool = true;

    PLAYER_OFFSET :: Vector2.{0, TILE_SIZE / 1.35};
    PLAYER_EXTENTS :: Vector2.{TILE_SIZE * 1.5, TILE_SIZE * 2.5};
}

pdata_has_temp_flags :: (f: Player_Temp_Flags) -> bool #expand {
    return context.player_data.player_flags & f == f;
}

pdata_set_temp_flags :: (f: Player_Temp_Flags) #expand {
    context.player_data.player_flags |= f;
}

pdata_unset_temp_flags :: (f: Player_Temp_Flags) #expand {
    context.player_data.player_flags &= ~f;
}

pdata_wipe_flags :: () #expand {
    context.player_data.player_flags = 0;
}

Player_Temp_Flags :: enum u8 {
    PUSHING :: 1 << 0;
}

Player_State :: enum {
    IDLE;
    RUN;
    PUSH;
    RISE;
    FALL;
    SKID;
    WALK;
    DYING;
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
    context.player_data.state = .IDLE;
    context.player_data.prev_state = .IDLE;
    print("Resetting Player: %\n", context.player_data.last_stable_ground);
}

kill_player :: () {
    player := player_get();
    if player {
        print("Killing Player\n");
        context.player_data.state = .DYING;
        context.player_data.prev_state = .DYING;
        set_animation(*context.animations.player, *PLAYER_DEATH_ANIMATION);
    }
}

manage_player_state :: () {
    if context.player_data.state == .DYING then return;
    player := player_get();
    anim := *context.animations.player;
    if player {
        data := context.player_data;
        pushing_this_frame := pdata_has_temp_flags(.PUSHING) || (entity_has_flags(player, .RIGHT_BLOCKED) && player.movement_delta.x > 0) || (entity_has_flags(player, .LEFT_BLOCKED) && player.movement_delta.x < 0);

        state: Player_State;
        if entity_has_flags(player, .GROUNDED) {
            if pushing_this_frame {
                state = .PUSH;
            } else {
                if abs(player.movement_delta.x) > 0 {
                    if is_action_held(.SPRINT) {
                        if signs_match(player.movement_delta.x, player.velocity.x) {
                            state = .RUN;
                        } else {
                            state = .SKID;
                        }
                    } else {
                        state = .WALK;
                    }
                } else {
                    state = .IDLE;
                }
            }
        } else {
            if player.velocity.y >= 0 then state = .RISE; else state = .FALL;
        }
        data.prev_state = data.state;
        data.state = state;

        if data.prev_state != data.state {
            if data.state == {
            case .IDLE;
                if data.prev_state == .RUN {
                    set_animation(anim, *PLAYER_RUN_TO_IDLE_ANIMATION);
                } else {
                    set_animation(anim, *PLAYER_IDLE_ANIMATION);
                }
            case .WALK;
                set_animation(anim, *PLAYER_WALK_ANIMATION, 0.075);
            case .PUSH;
                set_animation(anim, *PLAYER_PUSH_ANIMATION, 0.075);
            case .RUN;
                if data.prev_state == .FALL {
                    set_animation(anim, *PLAYER_RUN_ANIMATION);
                } else {
                    set_animation(anim, *PLAYER_DASH_ANIMATION);
                }
            case .SKID;
                set_animation(anim, *PLAYER_SKID_ANIMATION, 0.03);
            case .RISE;
                set_animation(anim, *PLAYER_JUMP_ANIMATION);
            case .FALL;
                set_animation(anim, *PLAYER_FALL_ANIMATION);
            }
        }
    }
    pdata_wipe_flags();
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
            if context.player_data.state != .SKID then context.player_data.facing_right = false;
        }
        if is_action_held(.MOVE_RIGHT) {
            x += 1;
            context.player_data.state != .SKID; context.player_data.facing_right = true;
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

player_apply_speed :: (delta: float) {
    player := player_get();
    if !player {
        // print("Failed to find player, skipping player_apply_speed!\n");
        return;
    }
    clamped_sprint_timer := clamp(get_player_timer_value(.SPRINT), 0, TIME_TO_MAX_SPEED);
    t := clamped_sprint_timer / TIME_TO_MAX_SPEED;
    p_speed := player.velocity.x;
    abs_speed := abs(player.velocity.x);
    if player.movement_delta.x == 0 {
        if entity_has_flags(player, .GROUNDED) {
            if abs_speed > 1 {
                player.velocity.x += -p_speed * context.player_data.friction * delta;
            } else {
                player.velocity.x = 0;
            }
        }
    } else {
        if is_action_held(.SPRINT) {
            curved_speed := ramp(PLAYER_BASE_MOVE_SPEED, PLAYER_MAX_MOVE_SPEED, t);
            if signs_match(p_speed, player.movement_delta.x) {
                if abs_speed < curved_speed {
                    player.velocity.x += player.movement_delta.x * curved_speed * delta * 10;
                } else {
                    player.velocity.x = player.movement_delta.x * curved_speed;
                }
            } else {
                player.velocity.x += player.movement_delta.x * curved_speed * delta * 3;
            }
        } else {
            if entity_has_flags(player, .GROUNDED) {
                player.velocity.x = (PLAYER_BASE_MOVE_SPEED * 0.6) * player.movement_delta.x;
            } else {
                if signs_match(p_speed, player.movement_delta.x) {
                    player.velocity.x = (PLAYER_BASE_MOVE_SPEED * 0.6) * player.movement_delta.x;
                } else {
                    player.velocity.x += (PLAYER_BASE_MOVE_SPEED * 0.6) * player.movement_delta.x * delta;
                }
            }
        }
    }
}

make_player :: (position: Vector2, map_coord: Coord, e := context.entities) -> Entity_Handle {
    entity: Entity;
    half_tile := Vector2.{TILE_SIZE, TILE_SIZE} / 2;
    entity.position = position;
    entity.current_room = map_coord;
    entity.tag = .PLAYER;
    entity.props = .RENDERABLE | .DYNAMIC | .GRAVITY_AFFECTED | .SELF_PROPELLED | .NO_HANDLE_REFRESH | .ANIMATED;
    entity.movement_delta.x = 0;

    player_handle := entity_add(entity, e = e);

    // Feet Collider
    fc: Entity;
    fc.offset = Vector2.{0, -TILE_SIZE / 4};
    fc.shape_kind = .CIRCLE;
    fc.radius = TILE_SIZE / 4;
    fc.tag = .PLAYER_FEET_COLLIDER;
    fc.props = .DYNAMIC | .RELATIVE_POSITION | .RELATIVE_ROTATION | .PRESSES_BUTTONS | .NO_HANDLE_REFRESH | .COLLIDER;
    entity_add_child(player_handle, fc, e = e);

    // Head Collider
    hc: Entity;
    hc.offset = Vector2.{0, TILE_SIZE / 5};
    hc.shape_kind = .CIRCLE;
    hc.radius = TILE_SIZE / 5;
    hc.tag = .PLAYER_FEET_COLLIDER;
    hc.props = .DYNAMIC | .RELATIVE_POSITION | .RELATIVE_ROTATION | .PRESSES_BUTTONS | .NO_HANDLE_REFRESH | .COLLIDER;
    entity_add_child(player_handle, hc, e = e);

    // Ground Sensor Entity
    gse: Entity;
    gse.offset = Vector2.{0, -TILE_SIZE / 2};
    gse.extents = Vector2.{TILE_SIZE * 0.4, TILE_SIZE / 8};
    gse.shape_kind = .RECTANGLE;
    gse.tag = .GROUND_SENSOR;
    gse.props = .SENSOR | .RELATIVE_POSITION | .RELATIVE_ROTATION | .NO_HANDLE_REFRESH;
    entity_add_child(player_handle, gse, e = e);

    // Left Wall Sensor Entity
    lws: Entity;
    lws.offset = Vector2.{-TILE_SIZE / 4, 0};
    lws.extents = Vector2.{TILE_SIZE / 8, TILE_SIZE * 0.8};
    lws.shape_kind = .RECTANGLE;
    lws.tag = .LEFT_SENSOR;
    lws.props = .SENSOR | .RELATIVE_POSITION | .RELATIVE_ROTATION | .NO_HANDLE_REFRESH;
    entity_add_child(player_handle, lws, e = e);

    // Right Wall Sensor Entity
    rws: Entity;
    rws.offset = Vector2.{TILE_SIZE / 4, 0};
    rws.extents = Vector2.{TILE_SIZE / 8, TILE_SIZE * 0.8};
    rws.shape_kind = .RECTANGLE;
    rws.tag = .RIGHT_SENSOR;
    rws.props = .SENSOR | .RELATIVE_POSITION | .RELATIVE_ROTATION | .NO_HANDLE_REFRESH;
    entity_add_child(player_handle, rws, e = e);
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
