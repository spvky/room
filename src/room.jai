ROOM_WIDTH :: 25;
ROOM_HEIGHT :: 25;

Room :: struct {
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Room_Tile;
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
    if mouse_left_down {
        mouse_x, mouse_y, ok := get_mouse_cell();
        if ok {
            set_tile_value(*room, .WALL, mouse_x, mouse_y);
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
    r.int_grid[coord_to_index(x, y)] = value;
}

parse_tiles :: (r: *Room) {
    // Wall_Segment :: struct {start: int; end: int; y: int; initialized: bool; parsed: bool;}
    // 
    // wall_segment: Wall_Segment;
    // wall_segment_collection: [..]Wall_Segment;
    // wall_segment_collection.allocator = temp;

    Wall_Block :: struct {start_x: int; end_x: int; start_y: int; end_y: int; initialized: bool;}

    wall_block: Wall_Block;
    wall_block_collection: [..]Wall_Block;
    wall_block_collection.allocator = temp;

    parsed: [ROOM_WIDTH * ROOM_HEIGHT]bool;

    for <y: 0..ROOM_HEIGHT - 1 {
        for x: 0..ROOM_WIDTH - 1 {
            if !parsed[coord_to_index(x, y)] {
                if check_tile_value(r, x, y) == .WALL {
                    start := x;
                    end := x;
                    start_y := y;
                    end_y := y;

                    moving_x := true;
                    moving_y := true;
                    iy := y;

                    while moving_y {
                        moving_x = true;
                        ix := start;
                        while moving_x {
                            if parsed[coord_to_index(ix, iy)] {
                                // if we hit an already parsed tile, terminate x
                                moving_x = false;
                            } else {
                                print("Have we already parsed %,% | %\n", ix, iy, parsed[coord_to_index(ix, iy)]);
                                if check_tile_value(r, ix, iy) == .WALL {
                                    // if we hit a wall
                                    if iy == end_y {
                                        // if this is the first row, parse the tile and set end to ix
                                        parsed[coord_to_index(ix, iy)] = true;
                                        end = ix;
                                    }
                                } else {
                                    // if we hit something that is not a wall, terminate x
                                    moving_x = false;
                                }
                            }
                            ix += 1;
                            // if we hit the edge of the grid, terminate x
                            if ix >= ROOM_WIDTH then moving_x = false;
                        }
                        // If we aren't on the first row
                        if iy != end_y {
                            // Parse the the row we have just moved on from
                            print("Finished row %1,%2 to %3,%2, marking as parsed\n", start, iy, end);
                            for v: start..end {
                                parsed[coord_to_index(v, iy)] = true;
                            }
                            start_y = iy;
                        }
                        // set the y min to our current y value
                        // If we stopped before x end, and we are below the starting row, terminate y
                        if ix < end && iy < start_y then moving_y = false;

                        iy -= 1;
                        // If we hit the bottom of the grid, terminate y
                        if iy < 0 then moving_y = false;
                    }
                    aabb: AABB = .{
                                   min = .{
                                           GRID_LEFT_BOUNDARY + (GRID_TILE_HEIGHT * xx start),
                                           GRID_BOT_BOUNDARY + (GRID_TILE_HEIGHT * xx start_y)},

                                   max = .{

                                           GRID_LEFT_BOUNDARY + (GRID_TILE_HEIGHT * (xx end + 1)),
                                           GRID_BOT_BOUNDARY + (GRID_TILE_HEIGHT * (xx end_y + 1))},
                                   start_x = start,
                                   start_y = start_y,
                                   end_x = end,
                                   end_y = end_y};

                    array_add(*colliders, aabb);
                }
            }
        }
    }
    for colliders print("%\n", it);
}
