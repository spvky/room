ROOM_WIDTH :: 22;
ROOM_HEIGHT :: 22;

Room :: struct {
    name: string;
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Room_Tile;
    entities: [..]Entity;
    rune: Rune; // = #run create_rune(.DO);
}

#add_context current_room: *Room;

make_room :: (name: string) -> Room {
    room: Room;
    room.name = copy_string(name);
    return room;
}

Room_Tile :: enum u8 {
    EMPTY;
    WALL;
    SLOPE;
    // Entities types will go here as well
}

// When baking, decompose level tiles in several steps
// 1. Greedy Mesh Walls
// 2. Create triangles for slopes
// At the end we will have an array of entites to save to the room

paint_tile_values :: () {
    room_ptr := context.current_room;
    if !context.editor_state.mouse_captured {
        if mouse_left_down {
            mouse_x, mouse_y, ok := get_mouse_cell();
            value_to_paint: Room_Tile = xx (context.editor_state.room_options.tile_type + 1);
            if ok {
                set_tile_value(room_ptr, value_to_paint, mouse_x, mouse_y);
            }
        }

        if mouse_right_down {
            mouse_x, mouse_y, ok := get_mouse_cell();
            if ok {
                set_tile_value(room_ptr, .EMPTY, mouse_x, mouse_y);
            }
        }
    }
}

get_mouse_cell :: () -> int, int, bool {
    mouse_x, mouse_y, ok := get_mouse_pointer_position();
    mouse_y = xx WINDOW_HEIGHT - mouse_y; // Flip mouse y to match grid row ordering

    mouse_x = (mouse_x - xx GRID_LEFT_BOUNDARY) / xx GRID_TILE_HEIGHT;
    mouse_y = (mouse_y - xx GRID_BOT_BOUNDARY) / xx GRID_TILE_HEIGHT;

    in_bounds := mouse_x >= 0 && mouse_x < ROOM_WIDTH && mouse_y >= 0 && mouse_y < ROOM_HEIGHT;

    return mouse_x, mouse_y, ok && in_bounds;
}

coord_to_index :: (x: int, y: int) -> int {
    return (y * ROOM_WIDTH) + x;
}

check_tile_value :: (r: *Room, x: int, y: int) -> Room_Tile {
    return r.int_grid[coord_to_index(x, y)];
}

set_tile_value :: (r: *Room, value: Room_Tile, x: int, y: int) {
    idx := coord_to_index(x, y);
    r.int_grid[idx] = value;
}

make_aabb :: (left: int, right: int, bot: int, top: int) -> AABB {
    return AABB.{
                 min = .{
                         GRID_LEFT_BOUNDARY + (GRID_TILE_HEIGHT * xx left),
                         GRID_BOT_BOUNDARY + (GRID_TILE_HEIGHT * xx bot)},

                 max = .{

                         GRID_LEFT_BOUNDARY + (GRID_TILE_HEIGHT * (xx right + 1)),
                         GRID_BOT_BOUNDARY + (GRID_TILE_HEIGHT * (xx top + 1))}};
}

parse_tiles :: (r: *Room) {
    is_valid_wall :: (x: int, y: int) -> bool #expand {
        return !`parsed[coord_to_index(x, y)] && check_tile_value(`r, x, y) == .WALL;
    }

    parsed: [ROOM_WIDTH * ROOM_HEIGHT]bool;
    for <y: 0..ROOM_HEIGHT - 1 {
        for x: 0..ROOM_WIDTH - 1 {
            if is_valid_wall(x, y) {
                left := x;
                right := x;
                top := y;
                bot := y;

                ix := x;
                iy := y;
                while is_valid_wall(ix, iy) {
                    right = ix;
                    ix += 1;
                }
                for left..right parsed[coord_to_index(it, iy)] = true;
                complete_row: bool;

                while y_loop := true {
                    iy -= 1;
                    if iy < 0 break y_loop;
                    ix := left;
                    while x_loop := ix <= right {
                        if is_valid_wall(ix, iy) {
                            ix += 1;
                        } else {
                            break y_loop;
                        }
                    }
                    for left..right parsed[coord_to_index(it, iy)] = true;
                    bot = iy;
                }
                aabb := make_aabb(left, right, bot, top);
                array_add(*colliders, aabb);
            }
        }
    }
}

rotate_around_pivot :: (value: Vector2, angle: float32, pivot: Vector2) -> Vector2 {
    rel_val := value - pivot;
    rot_val := Vector2.{
                        (rel_val.x * cos(angle)) - (rel_val.y * sin(angle)),
                        (rel_val.x * sin(angle)) + (rel_val.y * cos(angle))};
    return rot_val + pivot;
}

rotate_colliders :: () {
    center := Vector2.{(xx WINDOW_WIDTH / 2.0), (xx WINDOW_HEIGHT / 2.0)};
    for *colliders {
        it.min = rotate_around_pivot(it.min, PI / 2.0, center);
        it.max = rotate_around_pivot(it.max, PI / 2.0, center);

        print("Min: %\nMax: %\n", it.min, it.max);
    }
}
