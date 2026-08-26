COLUMN_WIDTH :: 1;
ROOM_WIDTH :: 44;
ROOM_HEIGHT :: 44;
HALF_ROOM_SIZE :: ROOM_WIDTH / 2;
MAP_WIDTH :: 10;
MAP_HEIGHT :: 10;
WORLD_WIDTH :: #run ROOM_WIDTH * MAP_WIDTH + (MAP_WIDTH + COLUMN_WIDTH);
WORLD_HEIGHT :: #run ROOM_HEIGHT * MAP_HEIGHT + (MAP_HEIGHT + COLUMN_WIDTH);
TILE_SIZE: float32: 16;

World :: struct {
    collision: [WORLD_WIDTH * WORLD_HEIGHT]Collision_Tile;
    entities: [WORLD_WIDTH * WORLD_HEIGHT]Entity_Tile;
    rooms: [MAP_WIDTH * MAP_HEIGHT]Map_Room;
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
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Collision_Tile;
    entity_grid: [ROOM_WIDTH * ROOM_HEIGHT]Entity_Tile;
    rune: Rune;
    map_position: Coord;
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
    rune: Rune;
    exits: Room_Exits;
    exists: bool;
}

Collision_Tile :: enum u8 {
    EMPTY;
    WALL;
    TOP_HALF;
    BOT_HALF;
    LEFT_HALF;
    RIGHT_HALF;
    BLANK;
}

Entity_Tile :: enum u16 {
    EMPTY;
    CRATE;
    PLAYER_SPAWN;
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

Map_Direction :: enum {
    EAST;
    SOUTH;
    WEST;
    NORTH;
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

operator == :: (a: Coord, b: Coord) -> bool {
    return a.x == b.x && a.y == b.y;
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
        } else {
            room_card: Room_Card;
            room_card.room_hash = it_index;
            room_card.coord = it.map_position;
            room_card.rotation = 0;
            array_add(*context.map.placed_room_cards, room_card);
            context.map.occupied[coord_to_index(room_card.coord, .MAP)] = true;
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
            world.collision[idx] = .BLANK;
            world.entities[idx] = .EMPTY;
        }
    }
}

make_editor_room :: (name: string) -> Room {
    room: Room;
    room.name = copy_string(name);
    return room;
}

rotate_room :: (r: Room) -> Room {
    out: Room;
    for x: 0..ROOM_WIDTH - 1 {
        for y: 0..ROOM_HEIGHT - 1 {
            new_index := coord_to_index(.{xx (ROOM_WIDTH - y - 1), xx x});
            old_index := coord_to_index(.{xx x, xx y});
            out.int_grid[new_index] = rotate_collision_tile(r.int_grid[old_index]);
            out.entity_grid[new_index] = r.entity_grid[old_index];
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
    out.exits = rotate_room_exits(r.exits, 1);
    return out;
}

rotate_collision_tile :: (t: Collision_Tile) -> Collision_Tile {
    tile := t;
    if t == {
    case .TOP_HALF;
        tile = .LEFT_HALF;
    case .LEFT_HALF;
        tile = .BOT_HALF;
    case .BOT_HALF;
        tile = .RIGHT_HALF;
    case .RIGHT_HALF;
        tile = .TOP_HALF;
    }
    return tile;
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

check_collision_tile_value :: (r: *Room, c: Coord) -> Collision_Tile {
    return r.int_grid[coord_to_index(c)];
}
check_entity_tile_value :: (r: *Room, c: Coord) -> Entity_Tile {
    return r.entity_grid[coord_to_index(c)];
}

check_world_collision_tile_value :: (c: Coord) -> Collision_Tile {
    return context.world.collision[coord_to_index(c, .WORLD)];
}

check_world_entity_tile_value :: (c: Coord) -> Entity_Tile {
    return context.world.entities[coord_to_index(c, .WORLD)];
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

set_collision_tile_value :: (r: *Room, value: Collision_Tile, c: Coord) {
    idx := coord_to_index(c);
    r.int_grid[idx] = value;
}

set_entity_tile_value :: (r: *Room, value: Entity_Tile, c: Coord) {
    idx := coord_to_index(c);
    r.entity_grid[idx] = value;
}

set_world_collision_tile_value :: (value: Collision_Tile, c: Coord) {
    idx := coord_to_index(c, .WORLD);
    context.world.collision[idx] = value;
}

set_world_entity_tile_value :: (value: Entity_Tile, c: Coord) {
    idx := coord_to_index(c, .WORLD);
    context.world.entities[idx] = value;
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

map_tile_occupied :: inline (c: Coord) -> bool {
    return context.map.occupied[coord_to_index(c, .MAP)];
}

place_room_at_position :: () {
    if is_action_buffered(.CONFIRM) {
        consume_action(.CONFIRM);
        avail_idx := context.map.selected_idx;
        coord_idx := coord_to_index(context.editor_state.map_cursor_position, .MAP);

        if context.map.occupied[coord_idx] {
            print("TRIED TO PLACE MAP IN OCCUPIED SPACE BECAUSE IM INCONSIDERATE\n");
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
        coord := Coord.{xx x, xx y};
        return !`parsed[coord_to_index(coord)] && check_world_collision_tile_value(coord) == .WALL;
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
}

bake_world :: () {
    write_room_cards_to_world();
    open_map_exits();
    generate_world_map_png("assets/world.png");
    parse_entities_from_tiles();
    rebuild_static_collision_table();
    print("Found % static entities while re-building the static collision table!\n", context.static_collision_table.count);
}

write_room_cards_to_world :: () {
    world := context.world;
    map := context.map;
    for map.placed_room_cards {
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

        // Write Room exits and rune to the world map
        room_to_place := Map_Room.{room_copy.rune, room_copy.exits, true};
        placed_idx := coord_to_index(it.coord, .MAP);
        world.rooms[placed_idx] = room_to_place;

        for y: 0..ROOM_HEIGHT - 1 {
            for x: 0..ROOM_WIDTH - 1 {
                room_coord := Coord.{xx x, xx y};
                world_coord := room_coord + Coord.{start_x, start_y};
                collision_tile := check_collision_tile_value(*room_copy, room_coord);
                entity_tile := check_entity_tile_value(*room_copy, room_coord);
                world_idx := coord_to_index(world_coord, .WORLD);
                world.collision[world_idx] = collision_tile;
                world.entities[world_idx] = entity_tile;
            }
        }
    }
}

open_map_exits :: () {
    _Late_Tile_Update :: struct {
        idx: int;
        tile: Collision_Tile;
    }
    _contains :: (e: Room_Exits, ce: Room_Exits) -> bool {
        return e & ce == ce;
    }
    world := context.world;
    late_tile_updates: [..]_Late_Tile_Update;
    late_tile_updates.allocator = temp;
    for <y: 0..MAP_HEIGHT - 1 {
        for x: 0..MAP_WIDTH - 1 {
            current_coord := Coord.{xx x, xx y};
            origin_tile := Coord.{current_coord.x * xx (ROOM_WIDTH + 1), current_coord.y * xx (ROOM_HEIGHT + 1)};
            current_room := world.rooms[coord_to_index(current_coord, .MAP)];
            if !current_room.exists continue;
            // Place the maps border
            for by: 0..ROOM_HEIGHT + 1 {
                for bx: 0..ROOM_WIDTH + 1 {
                    if bx == 0 || bx == ROOM_WIDTH + 1 || by == 0 || by == ROOM_HEIGHT + 1 {
                        world.collision[coord_to_index(origin_tile + .{xx bx, xx by}, .WORLD)] = .WALL;
                    }
                }
            }
            east_exits: Room_Exits;
            south_exits: Room_Exits;
            if x < MAP_WIDTH - 1 {
                east_neighbor := world.rooms[coord_to_index(current_coord + .{1, 0}, .MAP)];
                if east_neighbor.exists {
                    east_exits = exits_match(current_room.exits, east_neighbor.exits, .EAST);
                }
            }
            if y > 0 {
                south_neighbor := world.rooms[coord_to_index(current_coord + .{0, -1}, .MAP)];
                if south_neighbor.exists {
                    south_exits = exits_match(current_room.exits, south_neighbor.exits, .SOUTH);
                }
            }
            // Set the tiles corresponding to the exits to empty
            if east_exits != 0 {
                if _contains(east_exits, .EAST_NORTH) {
                    id1 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, ROOM_HEIGHT}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, ROOM_HEIGHT - 1}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                }
                if _contains(east_exits, .EAST) {
                    id1 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, ROOM_HEIGHT / 2}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, (ROOM_HEIGHT / 2) + 1}, .WORLD);
                    id3 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, (ROOM_HEIGHT / 2) + 2}, .WORLD);
                    id4 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, (ROOM_HEIGHT / 2) - 1}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                    array_add(*late_tile_updates, .{id3, .EMPTY});
                    array_add(*late_tile_updates, .{id4, .EMPTY});
                }
                if _contains(east_exits, .EAST_SOUTH) {
                    id1 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, 1}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, 2}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                }
            }

            if south_exits != 0 {
                if _contains(south_exits, .SOUTH_EAST) {
                    id1 := coord_to_index(origin_tile + .{ROOM_WIDTH, 0}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{ROOM_WIDTH - 1, 0}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                }
                if _contains(south_exits, .SOUTH) {
                    id1 := coord_to_index(origin_tile + .{ROOM_WIDTH / 2, 0}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{(ROOM_WIDTH / 2) + 1, 0}, .WORLD);
                    id3 := coord_to_index(origin_tile + .{(ROOM_WIDTH / 2) + 2, 0}, .WORLD);
                    id4 := coord_to_index(origin_tile + .{(ROOM_WIDTH / 2) - 1, 0}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                }
                if _contains(south_exits, .SOUTH_WEST) {
                    id1 := coord_to_index(origin_tile + .{2, 0}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{1, 0}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                }
            }
        }
    }

    // Final tile updates, right now it's just punching exit holes while still allowing each room to create it's border
    for late_tile_updates {
        world.collision[it.idx] = it.tile;
    }
    array_free(late_tile_updates);
}

// Takes 2 rooms and a coord relative to the first and returns which of the first rooms exits are clear
exits_match :: (a: Room_Exits, b: Room_Exits, direction: Map_Direction) -> Room_Exits {
    contains :: (e: Room_Exits, ce: Room_Exits) -> bool {
        return e & ce == ce;
    }
    matches: Room_Exits;
    if direction == {
    case .EAST;
        if contains(a, .EAST_NORTH) && contains(b, .WEST_NORTH) then matches |= .EAST_NORTH;
        if contains(a, .EAST) && contains(b, .WEST) then matches |= .EAST;
        if contains(a, .EAST_SOUTH) && contains(b, .WEST_SOUTH) then matches |= .EAST_SOUTH;
    case .SOUTH;
        if contains(a, .SOUTH_EAST) && contains(b, .NORTH_EAST) then matches |= .SOUTH_EAST;
        if contains(a, .SOUTH) && contains(b, .NORTH) then matches |= .SOUTH;
        if contains(a, .SOUTH_WEST) && contains(b, .NORTH_WEST) then matches |= .SOUTH_WEST;
    }
    return matches;
}

parse_entities_from_tiles :: () {
    is_valid_wall :: (x: int, y: int) -> bool #expand {
        coord := Coord.{xx x, xx y};
        return !`parsed[coord_to_index(coord, .WORLD)] && check_world_collision_tile_value(coord) == .WALL;
    }

    // Calculate the collision layer
    parsed: [WORLD_WIDTH * WORLD_HEIGHT]bool;
    for <y: 0..WORLD_HEIGHT - 1 {
        for x: 0..WORLD_WIDTH - 1 {
            coord := Coord.{xx x, xx y};
            if !parsed[coord_to_index(coord, .WORLD)] {
                tile := check_world_collision_tile_value(coord);
                if tile == {
                case .WALL;
                    left := x;
                    right := x;
                    top := y;
                    bot := y;

                    ix := x;
                    iy := y;
                    while is_valid_wall(ix, iy) {
                        right = ix;
                        if ix == WORLD_WIDTH - 1 break;
                        ix += 1;
                    }
                    for left..right parsed[coord_to_index(.{xx it, xx iy}, .WORLD)] = true;
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
                        for left..right parsed[coord_to_index(.{xx it, xx iy}, .WORLD)] = true;
                        bot = iy;
                    }
                    make_wall(left, right, top, bot);
                case .TOP_HALF;
                    left := x;
                    right := x;
                    ix := x;
                    while !parsed[coord_to_index(.{xx ix, xx y})] && check_world_collision_tile_value(.{xx ix, xx y}) == .TOP_HALF {
                        right = ix;
                        if ix == WORLD_WIDTH - 1 break;
                        ix += 1;
                    }

                    for left..right parsed[coord_to_index(.{xx it, xx y}, .WORLD)] = true;
                    make_top_wall(left, right, y);
                case .BOT_HALF;
                    left := x;
                    right := x;
                    ix := x;
                    while !parsed[coord_to_index(.{xx ix, xx y})] && check_world_collision_tile_value(.{xx ix, xx y}) == .BOT_HALF {
                        right = ix;
                        if ix == WORLD_WIDTH - 1 break;
                        ix += 1;
                    }
                    for left..right parsed[coord_to_index(.{xx it, xx y}, .WORLD)] = true;
                    make_bot_wall(left, right, y);
                case .LEFT_HALF;
                    top := y;
                    bot := y;
                    iy := y;
                    while !parsed[coord_to_index(.{xx x, xx iy})] && check_world_collision_tile_value(.{xx x, xx iy}) == .LEFT_HALF {
                        bot = iy;
                        if iy == 0 break;
                        iy -= 1;
                    }
                    for bot..top parsed[coord_to_index(.{xx x, xx it}, .WORLD)] = true;
                    make_left_wall(top, bot, x);
                case .RIGHT_HALF;
                    top := y;
                    bot := y;
                    iy := y;
                    while !parsed[coord_to_index(.{xx x, xx iy})] && check_world_collision_tile_value(.{xx x, xx iy}) == .RIGHT_HALF {
                        bot = iy;
                        if iy == 0 break;
                        iy -= 1;
                    }
                    for bot..top parsed[coord_to_index(.{xx x, xx it}, .WORLD)] = true;
                    make_right_wall(top, bot, x);
                }
            }
        }
    }

    for *parsed {
        it.* = false;
    }

    for y: 0..WORLD_HEIGHT - 1 {
        for x: 0..WORLD_WIDTH - 1 {
            coord := Coord.{xx x, xx y};
            if !parsed[coord_to_index(coord, .WORLD)] {
                entity := check_world_entity_tile_value(coord);
                if entity == {
                case .CRATE;
                    print("Started Parsing a crate at %,%\n", x, y);
                    // travelling coord
                    t_coord := coord;
                    t_coord.y -= 1;
                    if t_coord.y < 0 {
                        make_crate(coord);
                        parsed[coord_to_index(coord, .WORLD)] = true;
                        continue;
                    }
                    col_bellow: Collision_Tile;
                    ent_bellow: Entity_Tile;
                    while t_coord.y > 0 {
                        col_bellow = check_world_collision_tile_value(t_coord);
                        ent_bellow = check_world_entity_tile_value(t_coord);
                        if col_bellow == .EMPTY && ent_bellow == .EMPTY {
                            parsed[coord_to_index(t_coord, .WORLD)] = true;
                            print("Crate Falling: % --> %\n", coord, t_coord);
                            t_coord.y -= 1;
                            continue;
                        }

                        if col_bellow == {
                        case .WALL;
                            print("Crate Hit Wall: % --> %\n", coord, t_coord);
                            break;
                        case .BLANK;
                            print("CRATE FELL INTO A BLANK TILE, SOMETHING IS WRONG!\n");
                            break;
                        }

                        if ent_bellow == {
                        case .CRATE;
                            print("Crate Hit a Crate: % --> %\n", coord, t_coord);
                            break;
                        }
                        t_coord.y -= 1;
                    }
                    if t_coord != coord {
                        parsed[coord_to_index(coord, .WORLD)] = true;
                        set_world_entity_tile_value(.EMPTY, coord);
                        new_coord := t_coord + .{0, 1};

                        parsed[coord_to_index(new_coord, .WORLD)] = true;
                        set_world_entity_tile_value(.CRATE, new_coord);
                        make_crate(new_coord);
                    }
                case .PLAYER_SPAWN;
                    if !player_is_valid() then make_player(coord);
                case .EMPTY;
                    parsed[coord_to_index(coord, .WORLD)] = true;
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

    if is_action_buffered(.BAKE_MAP) {
        consume_action(.BAKE_MAP);
        bake_world();
    }
}

calculate_map_coord_from_position :: (position: Vector2) -> Coord, bool {
    raw_conversion := Vector2.{position.x / TILE_SIZE, position.y / TILE_SIZE};
    c := Coord.{xx raw_conversion.x, xx raw_conversion.y};
    if c.x == 0 && c.y == 0 return c, false;
    if c.x % 23 == 0 || c.y % 23 == 0 return c, false;
    c.x = c.x / 23;
    c.y = c.y / 23;
    return c, true;
}
