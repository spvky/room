ROOM_WIDTH :: 22;
ROOM_HEIGHT :: 22;
MAP_WIDTH :: 10;
MAP_HEIGHT :: 10;
WORLD_WIDTH :: #run ROOM_WIDTH * MAP_WIDTH + (MAP_WIDTH + 1);
WORLD_HEIGHT :: #run ROOM_HEIGHT * MAP_HEIGHT + (MAP_HEIGHT + 1);

World :: struct {
    tiles: [WORLD_WIDTH * WORLD_HEIGHT]Room_Tile;
    rooms: [MAP_WIDTH * MAP_HEIGHT]Map_Room;
    parsed: [WORLD_WIDTH * WORLD_HEIGHT]bool;
}

Map :: struct {
    // Rooms currently placed in the map
    placed_room_cards: [..]Room_Card;
    // Grid to indicate which cells have a room placed in them
    occupied: [MAP_WIDTH * MAP_HEIGHT]bool;
    // Array of rooms available to place
    available_rooms: [..]u32;
    selected_idx: int;
}

Room :: struct {
    flags: Room_Flags;
    exits: Room_Exits;
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Room_Tile;
    rune: Rune;
    name: string;
    extra_data: [..]Extra_Entity_Data;
    texture: Texture;
}

Room_Card :: struct {
    room_hash: u32;
    coord: Coord;
    rotation: u8;
}

Map_Room :: struct {
    flags: Room_Flags;
    exits: Room_Exits;
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

Room_Exits :: enum_flags u16 {
    NORTH_EAST :: 1 << 0;
    NORTH :: 1 << 1;
    NORTH_WEST :: 1 << 2;
    WEST_NORTH :: 1 << 3;
    WEST :: 1 << 4;
    WEST_SOUTH :: 1 << 5;
    SOUTH_WEST :: 1 << 6;
    SOUTH :: 1 << 7;
    SOUTH_EAST :: 1 << 8;
    EAST_SOUTH :: 1 << 9;
    EAST :: 1 << 10;
    EAST_NORTH :: 1 << 11;
}

Room_Flags :: enum_flags u16 {
    DISCOVERED :: 1 << 0;
    STATIC :: 1 << 1;
    ENTERED_NORTH :: 1 << 2;
    ENTERED_SOUTH :: 1 << 3;
    ENTERED_EAST :: 1 << 4;
    ENTERED_WEST :: 1 << 5;
    NO_ROTATE :: 1 << 6;
    NO_MOVE_X :: 1 << 7;
    NO_MOVE_Y :: 1 << 8;
    NO_PICKUP :: 1 << 9;
    MUST_BE_PLACED :: 1 << 10;
}

Coord :: struct {
    x: s16;
    y: s16;
}

operator + :: (a: Coord, b: Coord) -> Coord {
    c: Coord;
    c.x = a.x + b.x;
    c.y = a.y + b.y;
    return c;
}

operator - :: (a: Coord, b: Coord) -> Coord {
    c: Coord;
    c.x = a.x - b.x;
    c.y = a.y - b.y;
    return c;
}

Coord_Kind :: enum u8 {
    ROOM;
    MAP;
    WORLD;
}

#add_context current_editor_room: *Room;
#add_context room_table: *Table(u32, Room);
#add_context map: *Map;
#add_context world: *World;

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
        if it.flags & .STATIC == 0 {
            array_add(*context.map.available_rooms, it_index);
        }
    }
}

init_world :: () {
    if !context.world {
        context.world = New(World);
    }
    reset_world_tilemap();
}

reset_world_tilemap :: () {
    world := context.world;
    for x: 0..WORLD_WIDTH - 1 {
        for y: 0..WORLD_HEIGHT - 1 {
            idx := coord_to_index(.{xx x, xx y}, .WORLD);
            if x == 0 || y == 0 {
                world.tiles[idx] = .WALL;
            } else if x % 23 == 0 || y % 23 == 0 {
                world.tiles[idx] = .WALL;
            } else {
                world.tiles[idx] = .EMPTY;
            }
        }
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

rotate_room_exits :: (exits: Room_Exits, rot: int = 0) -> Room_Exits {
    // macro to write *slightly* less code
    _has_exit :: (exit: Room_Exits) -> bool #expand {
        return `n & exit == exit;
    }

    if rot == 0 then return exits;
    n := exits;
    for 1..rot {
        ir: Room_Exits;
        // North
        if _has_exit(.NORTH_EAST) then ir |= .WEST_NORTH;
        if _has_exit(.NORTH) then ir |= .WEST;
        if _has_exit(.NORTH_WEST) then ir |= .WEST_SOUTH;
        // West
        if _has_exit(.WEST_NORTH) then ir |= .SOUTH_WEST;
        if _has_exit(.WEST) then ir |= .SOUTH;
        if _has_exit(.WEST_SOUTH) then ir |= .SOUTH_EAST;
        // South
        if _has_exit(.SOUTH_EAST) then ir |= .EAST_SOUTH;
        if _has_exit(.SOUTH) then ir |= .EAST;
        if _has_exit(.SOUTH_WEST) then ir |= .EAST_NORTH;
        // East
        if _has_exit(.EAST_SOUTH) then ir |= .NORTH_EAST;
        if _has_exit(.EAST) then ir |= .NORTH;
        if _has_exit(.EAST_NORTH) then ir |= .NORTH_WEST;
        n = ir;
    }
    return n;
}

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

check_tile_value :: (r: *Room, c: Coord) -> Room_Tile {
    return r.int_grid[coord_to_index(c)];
}

rotate_coord :: (c: Coord, kind: Coord_Kind = .ROOM) -> Coord #expand {
    width: int;
    if kind == {
    case .ROOM;
        width = ROOM_WIDTH;
    case .MAP;
        width = MAP_WIDTH;
    case .WORLD;
        width = WORLD_WIDTH;
    }
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
            room_card: Room_Card;
            room_card.room_hash = context.map.available_rooms[avail_idx];
            room_card.coord = context.editor_state.map_cursor_position;
            room_card.rotation = context.editor_state.map_cursor_rotation;

            array_add(*context.map.placed_room_cards, room_card);
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

write_room_cards_to_world :: () {
    world := context.world;
    map := context.map;
    for map.placed_room_cards {
        // Write the rotated rune land exits to the world map
        r := get_room_from_hash(it.room_hash);
        assert(r != null, "Hit null room pointer while adding room tiles to tilemap.\nSkipping placed room %!\n", it.room_hash);
        start_x: s16 = it.coord.x * xx ROOM_WIDTH + (1 + it.coord.x); // Wall offset
        start_y: s16 = it.coord.y * xx ROOM_HEIGHT + (1 + it.coord.y); // Wall offset

        room_copy := r.*;

        if it.rotation > 0 {
            for 1..it.rotation {
                room_copy = rotate_room(room_copy);
            }
        }

        for x: 0..ROOM_WIDTH - 1 {
            for y: 0..ROOM_HEIGHT - 1 {
                room_coord := Coord.{xx x, xx y};
                world_coord := room_coord + Coord.{start_x, start_y};
                tile := check_tile_value(*room_copy, room_coord);
                if tile != .EMPTY {
                    world_idx := coord_to_index(world_coord, .WORLD);
                    world.tiles[world_idx] = tile;
                    // This may be all I need for placing the actual tiles, work on translating entity data once baking is done, there aren't any entities yet
                }
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
