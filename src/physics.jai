JUMP_HEIGHT: float32: 2.75 * TILE_SIZE;
BASE_JUMP_DISTANCE: float32: TILE_SIZE * 5;
MAX_JUMP_DISTANCE: float32: TILE_SIZE * 7;
TIME_TO_PEAK: float32: 0.3;
TIME_TO_DESCENT: float32: 0.28;
// Compile time calculated constants
PLAYER_JUMP_SPEED :: #run -> float {
    return (2 * JUMP_HEIGHT) / TIME_TO_PEAK;
}

PLAYER_BASE_MOVE_SPEED :: #run -> float {
    return BASE_JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT);
}

PLAYER_MAX_MOVE_SPEED :: #run -> float {
    return MAX_JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT);
}

RISING_GRAVITY :: #run -> float {
    return (-2 * JUMP_HEIGHT) / (TIME_TO_PEAK * TIME_TO_PEAK);
}

FALLING_GRAVITY :: #run -> float {
    return (-2 * JUMP_HEIGHT) / (TIME_TO_DESCENT * TIME_TO_DESCENT);
}

set_relative_position_and_rotations :: () {
    for *context.entities {
        if !(entity_has_props(it, .RELATIVE_POSITION | .RELATIVE_ROTATION) && entity_valid(it.parent)) continue;

        parent := entity_get(it.parent);
        origin := parent.position;
        theta := parent.rotation;
        if theta != 0.0 {
            rotated_offset := Vector2.{
                                       (it.offset.x * cos(theta)) - (it.offset.y * sin(theta)),
                                       (it.offset.x * sin(theta)) + (it.offset.y * cos(theta))};
            it.position = origin + rotated_offset;
        } else {
            it.position = origin + it.offset;
        }
    }
}

apply_movement_deltas :: () {
    for *context.entities {
        if it.tag == .PLAYER continue;
        if !entity_has_props(it, .SELF_PROPELLED) continue;
        if it.movement_delta.x == 0 {
            it.velocity.x = 0;
        } else {
            it.velocity.x = it.movement_delta.x * PLAYER_BASE_MOVE_SPEED;
            a := 0;
        }
    }
}

process_physical_collisions :: () {
    physical_query :: (it: *Entity) -> bool {
        return entity_has_props(it, .PHYSICAL) && !entity_has_props(it, .SENSOR | .STATIC);
    }
    queried_entities: [..]*Entity;
    queried_entities.allocator = temp;
    array_reserve(*queried_entities, context.collision_tree.capacity * 4);
    for *context.entities {
        if !entity_has_props(it, .PHYSICAL) || entity_has_props(it, .SENSOR) continue;
        bounding_box := aabb_from_entity(it);

        query_quad_tree_into_dynamic_array(context.collision_tree, bounding_box, *queried_entities, physical_query);

        for other: queried_entities {
            if other == it continue;
            if collision_has_been_solved_this_frame(it.handle, other.handle) continue;
            solve_physical_collision(other, it);
        }
        array_reset_keeping_memory(*queried_entities);
    }
}

solve_physical_collision :: (a: *Entity, b: *Entity) {
    sort :: (tag1: Entity_Tag, tag2: Entity_Tag) -> *Entity, *Entity #expand {
        entity1 := ifx `a.tag == tag1 then `a else `b;
        entity2 := ifx `a.tag == tag2 then `a else `b;
        return entity1, entity2;
    }
    get_first_matching :: (tag: Entity_Tag) -> *Entity, *Entity #expand {
        entity1 := ifx `a.tag == tag then `a else `b;
        entity2 := ifx `b.tag == tag then `b else `a;
        return entity1, entity2;
    }
    duo :: (t: Entity_Tag) -> bool #expand {
        return `a.tag == t && `b.tag == t;
    }
    pairing :: (t1: Entity_Tag, t2: Entity_Tag) -> bool #expand {
        return (`a.tag == t1 && `b.tag == t2) || (`a.tag == t2 && `b.tag == t1);
    }

    collision, did_collide := collision_test(a, b);
    if did_collide {
        x_dot := abs(dot(collision.normal, Vector2.{1, 0}));
        y_dot := abs(dot(collision.normal, Vector2.{0, 1}));

        if pairing(.CRATE, .GEAR) {
            gear, crate := sort(.GEAR, .CRATE);
            entity_kinematic_push(crate, gear, collision);
        }

        if pairing(.PLAYER_HEAD_COLLIDER, .GEAR) {
            kill_player();
        }

        if pairing(.PLAYER_FEET_COLLIDER, .GEAR) {
            kill_player();
        }

        if pairing(.CRATE, .WALL) {
            wall, crate := sort(.WALL, .CRATE);
            entity_kinematic_push(crate, wall, collision);
        }

        if pairing(.PLAYER_HEAD_COLLIDER, .WALL) {
            player_head, wall := sort(.PLAYER_HEAD_COLLIDER, .WALL);
            is_oneway := entity_has_props(wall, .ONE_WAY);
            if !is_oneway {
                if x_dot > 0 then set_player_timer_value(.SPRINT, 0);
                player := entity_get(player_head.parent);
                if player {
                    entity_kinematic_push(player, wall, collision);
                }
            }
        }

        if pairing(.PLAYER_FEET_COLLIDER, .WALL) {
            player_feet, wall := sort(.PLAYER_FEET_COLLIDER, .WALL);
            is_oneway := entity_has_props(wall, .ONE_WAY);
            player_holding_down := is_action_held(.MOVE_DOWN);
            is_below_wall := player_feet.position.y < wall.position.y;
            player := entity_get(player_feet.parent);
            if player {
                player_not_falling := player.velocity.y >= 0;
                should_ignore := is_oneway && (player_not_falling || player_holding_down || is_below_wall);
                if !should_ignore {
                    if x_dot > 0 then set_player_timer_value(.SPRINT, 0);
                    entity_kinematic_push(player, wall, collision);
                }
            }
        }

        if pairing(.PLAYER_FEET_COLLIDER, .CRATE) {
            player_feet, crate := sort(.PLAYER_FEET_COLLIDER, .CRATE);
            player := entity_get(player_feet.parent);
            if player {
                push_type: Push_Type;
                if x_dot > 0.1 {
                    set_player_timer_value(.SPRINT, 0);
                    push_type = player_crate_pushing(player, crate);
                }
                if y_dot > 0.1 {
                    player.velocity.y = 0;
                    crate.velocity.y = 0;
                }
                if push_type == {
                case .DYN_DYN;
                    entity_equal_push(player, crate, collision);
                case .DYN_KINEMATIC;
                    entity_kinematic_push(player, crate, collision);
                }
            }
        }

        if pairing(.PLAYER_HEAD_COLLIDER, .CRATE) {
            player_head, crate := sort(.PLAYER_HEAD_COLLIDER, .CRATE);
            player := entity_get(player_head.parent);
            if player {
                push_type: Push_Type;
                if x_dot > 0.1 {
                    set_player_timer_value(.SPRINT, 0);
                }
                if y_dot > 0.1 {
                    player.velocity.y = 0;
                    crate.velocity.y = 0;
                }
                entity_equal_push(player, crate, collision);
            }
        }

        if pairing(.PLAYER_HEAD_COLLIDER, .SWITCH_BLOCK) {
            if x_dot > 0 then set_player_timer_value(.SPRINT, 0);
            player_head, switch_block := sort(.PLAYER_HEAD_COLLIDER, .SWITCH_BLOCK);
            player := entity_get(player_head.parent);
            if player {
                entity_kinematic_push(player, switch_block, collision);
            }
        }

        if pairing(.PLAYER_FEET_COLLIDER, .SWITCH_BLOCK) {
            if x_dot > 0 then set_player_timer_value(.SPRINT, 0);
            player_feet, switch_block := sort(.PLAYER_FEET_COLLIDER, .SWITCH_BLOCK);
            player := entity_get(player_feet.parent);
            if player {
                entity_kinematic_push(player, switch_block, collision);
            }
        }

        if duo(.CRATE) {
            if x_dot > 0.1 {
                a.velocity.x = 0;
                b.velocity.x = 0;
            }
            if y_dot > 0.1 {
                a.velocity.y = 0;
                b.velocity.y = 0;
            }
            entity_equal_push(a, b, collision);
        }

        if pairing(.CRATE, .SWITCH_BLOCK) {
            crate, switch_block := sort(.CRATE, .SWITCH_BLOCK);
            entity_kinematic_push(crate, switch_block, collision);
        }
    }
}

process_sensor_collisions :: () {
}

entity_equal_push :: (a: *Entity, b: *Entity, collision: Collision) #expand {
    a_to_b := b.position - a.position;
    push_normal := ifx dot_product(a_to_b, collision.normal) > 0 then -collision.normal else collision.normal;
    push_amount := collision.depth / 2;
    a.position += push_normal * (push_amount + 0.01);
    b.position += -push_normal * (push_amount + 0.01);
}

entity_kinematic_push :: (dynamic: *Entity, kinematic: *Entity, collision: Collision) #expand {
    kin_to_dyn := dynamic.position - kinematic.position;
    push_normal := ifx dot_product(kin_to_dyn, collision.normal) > 0 then collision.normal else -collision.normal;
    push_amount := collision.depth;
    dynamic.position += push_normal * (push_amount + 0.01);
    if `x_dot > 0.1 {
        dynamic.velocity.x = 0;
    }
    if `y_dot > 0.1 {
        dynamic.velocity.y = 0;
    }
}

// Is this useful?
zero_velo_on_axis :: (entity: *Entity, normal: Vector2) {
    mag_along_axis := dot(entity.velocity, normal);
    if mag_along_axis > 0 {
        entity.velocity += mag_along_axis * -normal;
    }
}

moving_block_velocity :: () {
    for *context.entities {
        if it.tag != .SWITCH_BLOCK continue;
        if entity_has_flags(it, .POWERED) {
            if entity_valid(it.first_child) {
                child := entity_get(it.first_child);
                if distance(child.position, it.position) > 1 {
                    direction := normalize(child.position - it.position);
                    it.velocity = direction * 100;
                } else {
                    it.position = child.position;
                    it.velocity = .{};
                }
            }
        } else {
            if entity_valid(it.last_child) {
                child := entity_get(it.last_child);
                if distance(child.position, it.position) > 1 {
                    direction := normalize(child.position - it.position);
                    it.velocity = direction * 100;
                } else {
                    it.position = child.position;
                    it.velocity = .{};
                }
            }
        }
    }
}

Push_Type :: enum {
    DYN_DYN;
    DYN_KINEMATIC;
}

player_crate_pushing :: (player: *Entity, crate: *Entity) -> Push_Type #expand {
    push_type: Push_Type = .DYN_DYN;
    if player.velocity.x > 0 {
        if entity_has_flags(crate, .RIGHT_BLOCKED) {
            player.velocity.x = 0;
            crate.velocity.x = 0;
            push_type = .DYN_KINEMATIC;
        } else {
            if abs(player.velocity.x) > PLAYER_BASE_MOVE_SPEED / 2 {
                player.velocity.x = PLAYER_BASE_MOVE_SPEED / 2;
            }

            crate.velocity.x = player.velocity.x;
        }
        pdata_set_temp_flags(.PUSHING);
    }

    if player.velocity.x < 0 {
        if entity_has_flags(crate, .LEFT_BLOCKED) {
            player.velocity.x = 0;
            crate.velocity.x = 0;
            push_type = .DYN_KINEMATIC;
        } else {
            if abs(player.velocity.x) > PLAYER_BASE_MOVE_SPEED / 2 {
                player.velocity.x = -PLAYER_BASE_MOVE_SPEED / 2;
            }
            crate.velocity.x = player.velocity.x;
        }
        pdata_set_temp_flags(.PUSHING);
    }
    return push_type;
}

decay_crate_x_velocity :: () {
    for *context.entities {
        if it.tag != .CRATE continue;
        if abs(it.velocity.x) > 1 {
            it.velocity.x *= 0.95;
        } else {
            it.velocity.x = 0;
        }
    }
}

sensor_collision :: () {
    for *context.entities {
        if !(entity_has_props(it, .SENSOR)) continue;
        if it.tag == {
        case .GROUND_SENSOR;
            if !entity_valid(it.parent) continue;
            parent_is_player := context.player_handle.* == it.parent;
            player_holding_down := is_action_held(.MOVE_DOWN);
            touching_ground: bool;
            touching_unstable_ground: bool;
            parent_entity := entity_get(it.parent);

            // Check static collisions
            for static_info, static_handle: context.static_collision_table {
                if !entity_valid(static_handle) continue;
                static_body := entity_get(static_handle);
                is_oneway := entity_has_props(static_body, .ONE_WAY);
                if is_oneway && parent_is_player && player_holding_down continue;
                if !entity_has_props(static_body, .SOLID) continue;
                _, did_collide := dynamic_vs_static_collision_test(it, static_body);
                if did_collide {
                    if parent_entity.tag == .PLAYER && static_body.tag == .WALL {
                        // context.player_data.friction = 8;
                    }
                    touching_ground = true;
                    touching_unstable_ground = entity_has_props(static_body, .UNSTABLE);
                    if it.parent == context.player_handle && entity_has_props(static_body, .DEATH_ZONE) {
                        kill_player();
                        // reset_player();
                    }
                    if static_body.tag == .GEAR && parent_entity.tag == .CRATE {
                        parent_entity.inherited_velocity = rotate(Vector2.{1, 0}, static_body.rotation) * PLAYER_BASE_MOVE_SPEED / 2;
                    }
                }
            }

            // Check dynamic collisions
            for *other_entity: context.entities {
                if other_entity == it || other_entity.handle == it.parent || !entity_has_props(other_entity, .SOLID) || entity_has_props(other_entity, .STATIC) continue;
                _, did_collide := dynamic_vs_dynamic_collision_test(it, other_entity);
                if did_collide {
                    if parent_entity.tag == .PLAYER && (other_entity.tag == .CRATE || other_entity.tag == .SWITCH_BLOCK) {
                        // context.player_data.friction = 25;
                    }
                    touching_ground = true;
                    touching_unstable_ground = entity_has_props(other_entity, .UNSTABLE);
                    if !(other_entity.tag == .CRATE && parent_entity.tag == .CRATE) {
                        if other_entity.velocity == .{0, 0} {
                            parent_entity.inherited_velocity = other_entity.inherited_velocity;
                        } else {
                            parent_entity.inherited_velocity = other_entity.velocity;
                        }
                    }
                }
            }

            if touching_ground {
                parent_entity.flags |= .GROUNDED;
                if it.parent == context.player_handle && !touching_unstable_ground {
                    context.player_data.last_stable_ground = parent_entity.position;
                    c, in_bounds := calculate_map_coord_from_position(parent_entity.position);
                    if in_bounds {
                        if context.player_data.last_room_started_coord != c {
                            print("Snapshotting world\n");
                            snapshot_entities();
                            context.player_data.last_room_started_coord = c;
                            context.player_data.last_room_started_pos = parent_entity.position;
                        }
                    }
                }
            } else {
                parent_entity.flags &= ~.GROUNDED;
                if parent_entity.inherited_velocity != Vector2.{} {
                    parent_entity.inherited_velocity *= 0.9;
                    if length(parent_entity.inherited_velocity) < 1 {
                        parent_entity.inherited_velocity = Vector2.{};
                    }
                }
            }
        case .RIGHT_SENSOR;
            if !entity_valid(it.parent) continue;
            touching_right: bool;

            for static_info, static_handle: context.static_collision_table {
                if !entity_valid(static_handle) continue;
                static_body := entity_get(static_handle);
                if !entity_has_props(static_body, .SOLID) continue;
                _, did_collide := dynamic_vs_static_collision_test(it, static_body);
                if did_collide {
                    touching_right = true;
                }
            }

            for *other_entity: context.entities {
                if other_entity == it || other_entity.handle == it.parent || !entity_has_props(other_entity, .SOLID) || entity_has_props(other_entity, .STATIC) continue;
                _, did_collide := dynamic_vs_dynamic_collision_test(it, other_entity);
                if did_collide touching_right = true;
            }

            parent_entity := entity_get(it.parent);
            if touching_right {
                parent_entity.flags |= .RIGHT_BLOCKED;
            } else {
                parent_entity.flags &= ~.RIGHT_BLOCKED;
            }
        case .LEFT_SENSOR;
            if !entity_valid(it.parent) continue;
            touching_left: bool;

            for static_info, static_handle: context.static_collision_table {
                if !entity_valid(static_handle) continue;
                static_body := entity_get(static_handle);
                if !entity_has_props(static_body, .SOLID) continue;
                _, did_collide := dynamic_vs_static_collision_test(it, static_body);
                if did_collide {
                    touching_left = true;
                }
            }

            for *other_entity: context.entities {
                if other_entity == it || other_entity.handle == it.parent || !entity_has_props(other_entity, .SOLID) || entity_has_props(other_entity, .STATIC) continue;
                _, did_collide := dynamic_vs_dynamic_collision_test(it, other_entity);
                if did_collide touching_left = true;
            }

            parent_entity := entity_get(it.parent);
            if touching_left {
                parent_entity.flags |= .LEFT_BLOCKED;
            } else {
                parent_entity.flags &= ~.LEFT_BLOCKED;
            }
        case .BUTTON;
            being_pressed: bool;
            for *other_entity: context.entities {
                if other_entity == it || other_entity.handle == it.parent || !entity_has_props(other_entity, .PRESSES_BUTTONS) continue;
                _, did_collide := dynamic_vs_dynamic_collision_test(it, other_entity);
                if did_collide {
                    being_pressed = true;
                }
            }
            if being_pressed {
                it.flags |= .POWERED;
            } else {
                it.flags &= ~.POWERED;
            }
        }
    }
}

apply_velocity :: (delta: float32) {
    for *context.entities {
        if !entity_has_props(it, .DYNAMIC) || entity_has_flags(it, .PHYSICS_REST) continue;
        it.position += (it.velocity + it.inherited_velocity) * delta;
    }
}

apply_gravity :: (delta: float32) {
    for *context.entities {
        if !entity_has_props(it, .GRAVITY_AFFECTED) || entity_has_flags(it, .GROUNDED) continue;
        if it.velocity.y >= 0 it.velocity.y += RISING_GRAVITY * delta;
        if it.velocity.y < 0 it.velocity.y += FALLING_GRAVITY * delta;
    }
}
