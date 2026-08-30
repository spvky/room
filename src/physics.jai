JUMP_HEIGHT: float32: 3.5 * TILE_SIZE;
JUMP_DISTANCE: float32: TILE_SIZE * 7;
TIME_TO_PEAK: float32: 0.3;
TIME_TO_DESCENT: float32: 0.28;
// Compile time calculated constants
PLAYER_JUMP_SPEED :: #run calculate_jump_speed();
PLAYER_MOVE_SPEED :: #run calculate_lateral_speed();
RISING_GRAVITY :: #run calculate_rising_gravity();
FALLING_GRAVITY :: #run calculate_falling_gravity();

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
        if !entity_has_props(it, .SELF_PROPELLED) continue;
        if it.movement_delta.x == 0 {
            it.velocity.x = 0;
        } else {
            it.velocity.x = it.movement_delta.x * PLAYER_MOVE_SPEED;
            a := 0;
        }
    }
}

body_collision :: () {
    for *context.entities {
        if !(entity_has_props(it, .DYNAMIC)) continue;
        // Static Collision
        for static_info, static_handle: context.static_collision_table {
            static_ptr := entity_get(static_handle);
            static_collision, static_collision_occurred := dynamic_vs_static_collision_test(it, static_ptr);
            if static_collision_occurred {
                dir_to_static := normalize(static_ptr.position - it.position);
                corrected_normal := ifx dot_product(dir_to_static, static_collision.normal) < 0 then static_collision.normal else -static_collision.normal;
                it.position += corrected_normal * (static_collision.depth + 0.01);
                x_dot := abs(dot(static_collision.normal, Vector2.{1, 0}));
                y_dot := abs(dot(static_collision.normal, Vector2.{0, 1}));
                if x_dot > 0.1 {
                    it.velocity.x = 0;
                }
                if y_dot > 0.1 {
                    it.velocity.y = 0;
                }
            }
        }

        a := 0;

        // Dynamic Collision
        for *dynamic_ptr: context.entities {
            if !entity_has_props(dynamic_ptr, .SOLID) || !entity_has_props(dynamic_ptr, .DYNAMIC) continue;
            if dynamic_ptr == it || dynamic_ptr.handle == it.parent || it.handle == dynamic_ptr.handle continue;
            dynamic_collision, dynamic_collision_occurred := dynamic_vs_dynamic_collision_test(it, dynamic_ptr);
            if dynamic_collision_occurred {
                dir_to_dynamic := normalize(dynamic_ptr.position - it.position);
                corrected_normal := ifx dot_product(dir_to_dynamic, dynamic_collision.normal) < 0 then dynamic_collision.normal else -dynamic_collision.normal;
                it.position += corrected_normal * (dynamic_collision.depth + 0.01);
                x_dot := abs(dot(corrected_normal, Vector2.{1, 0}));
                y_dot := abs(dot(corrected_normal, Vector2.{0, 1}));
                // vel_to_dynamic := dot(dir_to_dynamic)
                if x_dot > 0.1 {
                    it.velocity.x = 0;
                }
                if y_dot > 0.1 {
                    it.velocity.y = 0;
                }
            }
        }
    }
}

sensor_collision :: () {
    for *context.entities {
        if !(entity_has_props(it, .SENSOR)) continue;
        if it.tag == {
        case .GROUND_SENSOR;
            if !entity_valid(it.parent) continue;
            touching_ground: bool;

            // Check static collisions
            for static_info, static_handle: context.static_collision_table {
                if !entity_valid(static_handle) continue;
                static_body := entity_get(static_handle);
                if !entity_has_props(static_body, .SOLID) continue;
                _, did_collide := dynamic_vs_static_collision_test(it, static_body);
                if did_collide touching_ground = true;
            }

            // Check dynamic collisions
            for *other_entity: context.entities {
                if other_entity == it || other_entity.handle == it.parent || !entity_has_props(other_entity, .SOLID) || entity_has_props(other_entity, .STATIC) continue;
                _, did_collide := dynamic_vs_dynamic_collision_test(it, other_entity);
                if did_collide touching_ground = true;
            }

            parent_entity := entity_get(it.parent);
            if touching_ground then parent_entity.flags |= .GROUNDED; else parent_entity.flags &= ~.GROUNDED;
        }
    }
}

raycast_collision :: () {
    for *context.entities {
        if !(entity_has_props(it, .RAY_CASTER)) continue;
        ray_start := it.position;
        ray_end := it.position + (it.ray.direction * it.ray.max_toi);
        hit_dist := FLOAT32_MAX;
        hit_point: Vector2;
        hit_handle: Entity_Handle;
        did_hit := false;
        if it.tag == {
        case .WALL_CASTER;
            for *other_entity: context.entities {
                if !entity_has_props(other_entity, .SOLID) || other_entity.tag != .CRATE continue;
                edges, is_rect := rigidbody_edges(other_entity);
                if is_rect {
                    for e: edges {
                        int_point, intersects := line_intersection_test(e[0], e[1], ray_start, ray_end);
                        // debug
                        if intersects {
                            dist := distance_squared(int_point, ray_start);
                            if dist < hit_dist {
                                did_hit = true;
                                hit_dist = dist;
                                hit_point = int_point;
                                hit_handle = other_entity.handle;
                            }
                        }
                    }
                }
            }
            if did_hit {
                it.ray.hit = true;
                it.ray.hit_point = hit_point;
                it.ray.hit_handle = hit_handle;
            } else {
                it.ray.hit = false;
            }
        }
    }
}

apply_velocity :: (delta: float32) {
    for *context.entities {
        if !entity_has_props(it, .DYNAMIC) || entity_has_flags(it, .PHYSICS_REST) continue;
        it.position += it.velocity * delta;
    }
}

apply_gravity :: (delta: float32) {
    for *context.entities {
        if !entity_has_props(it, .GRAVITY_AFFECTED) || entity_has_flags(it, .GROUNDED) continue;
        if it.velocity.y >= 0 it.velocity.y += RISING_GRAVITY * delta;
        if it.velocity.y < 0 it.velocity.y += FALLING_GRAVITY * delta;
    }
}

#scope_file
calculate_jump_speed :: () -> float32 {
    return (2 * JUMP_HEIGHT) / TIME_TO_PEAK;
}

calculate_rising_gravity :: () -> float32 {
    return (-2 * JUMP_HEIGHT) / (TIME_TO_PEAK * TIME_TO_PEAK);
}

calculate_falling_gravity :: () -> float32 {
    return (-2 * JUMP_HEIGHT) / (TIME_TO_DESCENT * TIME_TO_DESCENT);
}

calculate_lateral_speed :: () -> float32 {
    return JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT);
}
