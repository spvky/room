ROOM_WIDTH :: 22;
ROOM_HEIGHT :: 22;
MAP_WIDTH :: 10;
MAP_HEIGHT :: 10;

Map :: struct {
    // Rooms currently placed in the map
    placed_rooms: [..]Placed_Room;
    // Grid to indicate which cells have a room placed in them
    occupied: [MAP_WIDTH * MAP_HEIGHT]bool;
    // Array of rooms available to place
    available_rooms: [..]u32;
    selected_idx: int;
}

Room :: struct {
    // May want to store these seperately in a meta data file
    flags: Room_Flags;
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Room_Tile;
    rune: Rune;
    name: string;
    extra_data: [..]Extra_Entity_Data;
    texture: Texture;
}

Placed_Room :: struct {
    room_hash: u32;
    coord: Coord;
    rotation: u8;
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

Coord :: struct {
    x: s8;
    y: s8;
}

Coord_Kind :: enum u8 {
    ROOM;
    MAP;
}

#add_context current_editor_room: *Room;
#add_context room_table: *Table(u32, Room);
#add_context map: *Map;

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

init_map :: () {
    if !context.map {
        context.map = New(Map);
    }

    for context.room_table {
        array_add(*context.map.available_rooms, it_index);
    }
}

make_editor_room :: (name: string) -> Room {
    room: Room;
    room.name = copy_string(name);
    return room;
}

// Room Editing

paint_tile_values :: () {
    room_ptr := context.current_editor_room;
    if !context.editor_state.mouse_captured {
        if is_action_held(.EDITOR_LEFT_CLICK) {
            cell, ok := get_mouse_cell();
            value_to_paint: Room_Tile = xx (context.editor_state.room_options.tile_type + 1);
            if ok {
                set_tile_value(room_ptr, value_to_paint, cell);
            }
        }

        if is_action_held(.EDITOR_RIGHT_CLICK) {
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

rotate_room :: (r: Room) -> Room {
    out: Room;
    for x: 0..ROOM_WIDTH - 1 {
        for y: 0..ROOM_HEIGHT - 1 {
            new_index := coord_to_index(.{xx (ROOM_WIDTH - y - 1), xx x});
            old_index := coord_to_index(.{xx x, xx y});
            out.int_grid[new_index] = r.int_grid[old_index];
        }
    }

    array_reserve(*out.extra_data, r.extra_data.count);
    for r.extra_data {
        array_add(*out.extra_data, Extra_Entity_Data.{
                                                      subject_pos = rotate_coord(it.subject_pos),
                                                      path_start = rotate_coord(it.path_start),
                                                      path_end = rotate_coord(it.path_end),
                                                      parent_pos = rotate_coord(it.parent_pos),
                                                      child_pos = rotate_coord(it.child_pos)});
    }
    out.rune = rotate_rune(r.rune, 1);
    return out;
}

check_room_tile_value :: (r: *Room, c: Coord) -> Room_Tile {
    return r.int_grid[coord_to_index(c)];
}

coord_to_index :: (c: Coord, kind: Coord_Kind = .ROOM) -> int {
    width := ifx kind == .ROOM then ROOM_WIDTH else MAP_WIDTH;
    return (c.y * width) + c.x;
}

check_tile_value :: (r: *Room, c: Coord) -> Room_Tile {
    return r.int_grid[coord_to_index(c)];
}

rotate_coord :: (c: Coord, kind: Coord_Kind = .ROOM) -> Coord #expand {
    width := ifx kind == .ROOM then ROOM_WIDTH else MAP_WIDTH;
    return .{xx width - c.y - 1, c.x};
}

set_tile_value :: (r: *Room, value: Room_Tile, c: Coord) {
    idx := coord_to_index(c);
    r.int_grid[idx] = value;
}

// Map Placement and editing
get_room_at_wrapping_index :: (req_idx: int) -> *Room {
    idx := ifx req_idx == 0 then 0 else req_idx % context.map.available_rooms.count;
    return table_find_pointer(context.room_table, context.map.available_rooms[idx]);
}

get_room_from_hash :: (hash: u32) -> *Room {
    return table_find_pointer(context.room_table, hash);
}

next_map_selected_idx :: () {
    new_idx := context.map.selected_idx + 1;
    if new_idx >= context.map.available_rooms.count then new_idx = 0;
    context.map.selected_idx = new_idx;
}

prev_map_selected_idx :: () {
    new_idx := context.map.selected_idx - 1;
    if new_idx < 0 then new_idx = context.map.available_rooms.count - 1;
    context.map.selected_idx = new_idx;
}

rotate_map_selected_room :: () {
    new_rot := context.editor_state.map_cursor_rotation + 1;
    if new_rot > 3 then new_rot = 0;
    context.editor_state.map_cursor_rotation = new_rot;
}

place_room_at_position :: () {
    if is_action_buffered(.CONFIRM) {
        avail_idx := context.map.selected_idx;
        coord_idx := coord_to_index(context.editor_state.map_cursor_position, .MAP);

        if context.map.occupied[coord_idx] {
            // play sound and trigger some juice
        } else {
            context.map.occupied[coord_idx] = true;
            placed_room: Placed_Room;
            placed_room.room_hash = context.map.available_rooms[avail_idx];
            placed_room.coord = context.editor_state.map_cursor_position;
            placed_room.rotation = context.editor_state.map_cursor_rotation;

            array_add(*context.map.placed_rooms, placed_room);
            array_ordered_remove_by_index(*context.map.available_rooms, avail_idx);

            next_map_selected_idx();
        }
    }
}

move_map_cursor :: () {
    if is_action_buffered(.MOVE_LEFT) {
        consume_action(.MOVE_LEFT);
        new_x := context.editor_state.map_cursor_position.x - 1;
        if new_x < 0 {
            new_x = 0;
        }
        context.editor_state.map_cursor_position.x = new_x;
    }

    if is_action_buffered(.MOVE_RIGHT) {
        consume_action(.MOVE_RIGHT);
        new_x := context.editor_state.map_cursor_position.x + 1;
        if new_x > MAP_WIDTH - 1 {
            new_x = MAP_WIDTH - 1;
        }
        context.editor_state.map_cursor_position.x = new_x;
    }

    if is_action_buffered(.MOVE_UP) {
        consume_action(.MOVE_UP);
        new_y := context.editor_state.map_cursor_position.y + 1;
        if new_y > MAP_HEIGHT - 1 {
            new_y = MAP_HEIGHT - 1;
        }
        context.editor_state.map_cursor_position.y = new_y;
    }

    if is_action_buffered(.MOVE_DOWN) {
        consume_action(.MOVE_DOWN);
        new_y := context.editor_state.map_cursor_position.y - 1;
        if new_y < 0 {
            new_y = 0;
        }
        context.editor_state.map_cursor_position.y = new_y;
    }
}

parse_tiles :: (r: *Room) {
    is_valid_wall :: (x: int, y: int) -> bool #expand {
        return !`parsed[coord_to_index(.{xx x, xx y})] && check_tile_value(`r, .{xx x, xx y}) == .WALL;
    }

    // Calculate all walls first
    parsed: [ROOM_WIDTH * ROOM_HEIGHT]bool;
    for <y: 0..ROOM_HEIGHT - 1 {
        for x: 0..ROOM_WIDTH - 1 {
            if is_valid_wall(x, y) {
                print("Found a wall at: %,% | %!\n", x, y, coord_to_index(.{xx x, xx y}));
                left := x;
                right := x;
                top := y;
                bot := y;

                ix := x;
                iy := y;
                while is_valid_wall(ix, iy) {
                    right = ix;
                    if ix == ROOM_WIDTH - 1 break;
                    ix += 1;
                }
                for left..right parsed[coord_to_index(.{xx it, xx iy})] = true;
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
                    for left..right parsed[coord_to_index(.{xx it, xx iy})] = true;
                    bot = iy;
                }
            }
        }
    }

    // Start a second loop for non wall entities
    for <y: 0..ROOM_HEIGHT - 1 {
        for x: 0..ROOM_WIDTH - 1 {
            if check_tile_value(r, .{xx x, xx y}) == {
            case 2;
                // Crate
            case 3;
                // Moving Block - These will get greedy meshed together to make them look nice but move as one big complex collider
            case 4;
                // Button triggers an attached moving block
            }
        }
    }
}

map_screen_update :: () {
    move_map_cursor();
    if is_action_buffered(.MENU_UP) {
        consume_action(.MENU_UP);
        prev_map_selected_idx();
    }

    if is_action_buffered(.MENU_DOWN) {
        consume_action(.MENU_DOWN);
        next_map_selected_idx();
    }

    if is_action_buffered(.MAP_SCREEN_ROTATE) {
        consume_action(.MAP_SCREEN_ROTATE);
        rotate_map_selected_room();
    }

    place_room_at_position();
}
