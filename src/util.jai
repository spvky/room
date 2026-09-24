coord_to_index :: (c: Coord, kind: Coord_Kind = .ROOM) -> int {
    width: int;
    if kind == {
    case .ROOM;
        width = ROOM_WIDTH;
    case .MAP;
        width = MAP_WIDTH;
    case .WORLD;
        width = WORLD_WIDTH;
    }
    return (c.y * width) + c.x;
}

world_coord_to_vector2 :: (c: Coord) -> Vector2 #expand {
    return c * Vector2.{TILE_SIZE, TILE_SIZE};
}

check_collision_tile_value :: (r: *Room, c: Coord) -> Collision_Tile #expand {
    return r.int_grid[coord_to_index(c)];
}

check_world_collision_tile_value :: (c: Coord) -> Collision_Tile {
    return context.world.collision[coord_to_index(c, .WORLD)];
}

get_room_from_hash :: (hash: u32) -> *Room {
    return table_find_pointer(context.room_table, hash);
}

mouse_pointer_to_gameplay_pos :: () -> Vector2, bool {
    raw_x, raw_y, ok := get_mouse_pointer_position();
    raw_y = WINDOW_HEIGHT - raw_y;

    if raw_x < 0 || raw_y < 0 || raw_x > WINDOW_WIDTH || raw_y > WINDOW_HEIGHT {
        return Vector2.{}, false;
    }

    screen_scaled_x := (cast(float32)raw_x) / WINDOW_WIDTH;
    screen_scaled_y := (cast(float32)raw_y) / WINDOW_HEIGHT;

    true_x := screen_scaled_x * cast(float32)DISPLAY_WIDTH;
    true_y := screen_scaled_y * cast(float32)DISPLAY_HEIGHT;

    display_offset := Vector2.{(cast(float32)DISPLAY_WIDTH) / 2, (cast(float32)DISPLAY_HEIGHT) / 2};

    return context.camera.position + Vector2.{true_x, true_y} - display_offset, ok;
}

gameplay_pos_to_screen_position :: (v: Vector2) -> int, int, bool {
    display_offset := Vector2.{(cast(float32)DISPLAY_WIDTH) / 2, (cast(float32)DISPLAY_HEIGHT) / 2};
    adjusted_pos := v - context.camera.position + display_offset;
    display_scaled_x := adjusted_pos.x / (cast(float32)DISPLAY_WIDTH);
    display_scaled_y := adjusted_pos.y / (cast(float32)DISPLAY_HEIGHT);

    if display_scaled_x < 0 || display_scaled_x > 1 || display_scaled_y < 0 || display_scaled_y > 1 return 0, 0, false;

    screen_float_x := display_scaled_x * WINDOW_WIDTH;
    screen_float_y := display_scaled_y * WINDOW_HEIGHT;

    return cast(s64)screen_float_x, cast(s64)screen_float_y, true;
}
