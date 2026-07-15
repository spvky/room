Coord :: struct {
    x: s8;
    y: s8;
}

Coord_Kind :: enum u8 {
    ROOM;
    MAP;
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

// When baking, decompose level tiles in several steps
// 1. Greedy Mesh Walls
// 2. Create triangles for slopes
// At the end we will have an array of entites to save to the room

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
