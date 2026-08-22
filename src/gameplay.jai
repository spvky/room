gameplay_update :: () {
    p: Entity;
    p.position = player_pos;
    p.shape_kind = .CIRCLE;
    p.radius = TILE_SIZE / 2;

    hit: bool;
    for context.static_collision_table {
        static := entity_get(it_index);
        collision, did_collide := dynamic_vs_static_collision_test(*p, static);
        if did_collide {
            dir_to_static := normalize(static.position - p.position);
            push_direction := ifx dot_product(dir_to_static, collision.normal) < 0 then collision.normal else -collision.normal;
            print("Current Position: %\nPush Amount: %\n", p.position, push_direction * collision.depth);
            player_pos += push_direction * collision.depth;
            hit = true;
        }
    }
    player_colliding = hit;
    set_relative_position_and_rotations();
    sensor_collision();
    set_player_move_delta();
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

sensor_collision :: () {
    player := player_get();
    for *context.entities {
        if !(entity_has_props(it, .SENSOR) && entity_valid(it.parent)) continue;
        if it.tag == {
        case .GROUND_SENSOR;
            touching_ground: bool;

            // Check static collisions
            for static_info, static_handle: context.static_collision_table {
                if !entity_valid(static_handle) continue;
                static_body := entity_get(static_handle);
                _, did_collide := dynamic_vs_static_collision_test(it, static_body);
                if did_collide touching_ground = true;
            }

            // Check dynamic collisions
            for *other_entity: context.entities {
                if other_entity == it || other_entity.handle == it.parent || !entity_has_props(other_entity, .SOLID) continue;
                _, did_collide := dynamic_vs_dynamic_collision_test(it, other_entity);
                if did_collide touching_ground = true;
            }

            parent_entity := entity_get(it.parent);
            if touching_ground then parent_entity.flags |= .GROUNDED; else parent_entity.flags &= ~.GROUNDED;
        }
    }
}
