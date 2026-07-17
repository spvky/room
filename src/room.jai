ROOM_WIDTH :: 22;
ROOM_HEIGHT :: 22;

Room :: struct {
    // May want to store these seperately in a meta data file
    flags: Room_Flags;
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Room_Tile;
    rune: Rune;
    name: string;
    extra_data: [..]Extra_Entity_Data;
    texture: Texture;
}

Room_Tile :: enum u8 {
    EMPTY;
    WALL;
    SLOPE;
}

Extra_Entity_Data :: struct {
    subjet_idx: int;
    subject_pos: Coord;
    path_start: Coord;
    path_end: Coord;
    parent_pos: Coord;
    child_pos: Coord;
}

Room_Flags :: enum_flags u16 {
    DISCOVERED :: 1 << 0;
    ENTERED_NORTH :: 1 << 1;
    ENTERED_SOUTH :: 1 << 2;
    ENTERED_EAST :: 1 << 3;
    ENTERED_WEST :: 1 << 4;
    NO_ROTATE :: 1 << 5;
    NO_MOVE_X :: 1 << 6;
    NO_MOVE_Y :: 1 << 7;
    NO_PICKUP :: 1 << 8;
    MUST_BE_PLACED :: 1 << 9;
}

#add_context current_editor_room: *Room;
#add_context room_table: *Table(u32, Room);

init_rooms :: () {
    if !context.current_editor_room {
        context.current_editor_room = New(Room);
        context.current_editor_room.* = make_editor_room("New Room");
    }

    if !context.room_table {
        context.room_table = New(Table(u32, Room));
    }

    load_all_rooms();
}

make_editor_room :: (name: string) -> Room {
    room: Room;
    room.name = copy_string(name);
    return room;
}

paint_tile_values :: () {
    room_ptr := context.current_editor_room;
    if !context.editor_state.mouse_captured {
        if mouse_left_down {
            cell, ok := get_mouse_cell();
            value_to_paint: Room_Tile = xx (context.editor_state.room_options.tile_type + 1);
            if ok {
                set_tile_value(room_ptr, value_to_paint, cell);
            }
        }

        if mouse_right_down {
            cell, ok := get_mouse_cell();
            if ok {
                set_tile_value(room_ptr, .EMPTY, cell);
            }
        }
    }
}

get_mouse_cell :: () -> Coord, bool {
    width := ifx context.editor_state.editor_type == 0 then ROOM_WIDTH else MAP_WIDTH;
    height := ifx context.editor_state.editor_type == 0 then ROOM_HEIGHT else MAP_HEIGHT;
    tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary := get_tile_ui_data(height);
    mouse_x, mouse_y, ok := get_mouse_pointer_position();

    mouse_y = WINDOW_HEIGHT - mouse_y; // Flip mouse y to match grid row ordering
    in_bounds: bool;

    mouse_x = (mouse_x - xx left_boundary) / xx tile_height;
    mouse_y = (mouse_y - xx bot_boundary) / xx tile_height;

    in_bounds = mouse_x >= 0 && mouse_x < width && mouse_y >= 0 && mouse_y < height;

    return .{xx mouse_x, xx mouse_y}, ok && in_bounds;
}

check_room_tile_value :: (r: *Room, c: Coord) -> Room_Tile {
    return r.int_grid[coord_to_index(c)];
}

// Might make more sense to remove these and rotate the int grid itself
// rotate_around_pivot :: (value: Vector2, angle: float32, pivot: Vector2) -> Vector2 {
//     rel_val := value - pivot;
//     rot_val := Vector2.{
//                         (rel_val.x * cos(angle)) - (rel_val.y * sin(angle)),
//                         (rel_val.x * sin(angle)) + (rel_val.y * cos(angle))};
//     return rot_val + pivot;
// }
// 
// rotate_colliders :: () {
//     center := Vector2.{(xx WINDOW_WIDTH / 2.0), (xx WINDOW_HEIGHT / 2.0)};
//     for *colliders {
//         it.min = rotate_around_pivot(it.min, PI / 2.0, center);
//         it.max = rotate_around_pivot(it.max, PI / 2.0, center);
// 
//         print("Min: %\nMax: %\n", it.min, it.max);
//     }
// }
