// 
Editor_Room :: struct {
    name: string;
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Room_Tile;
    extra_data: [..]Extra_Entity_Data;
    // entities: [..]Editor_Entity;
    // colliders: [..]Editor_Collider;
    flags: Room_Flags;
    rune: Rune;
}

#add_context current_editor_room: *Editor_Room;

Editor_Entity :: struct {
    position: Grid_Vec2;
    tag: Entity_Tag; // Tags will probably not be present at runtime, but can be used for prefabs, essentially corresponding to bundles of props/sprite/and collision data
}

Extra_Entity_Data :: struct {
    subjet_idx: int;
    subject_pos: Grid_Vec2;
    path_start: Grid_Vec2;
    path_end: Grid_Vec2;
    parent_pos: Grid_Vec2;
    child_pos: Grid_Vec2;
}

Editor_Collider :: struct {
    tag: Collider_Tag;
    min: Grid_Vec2;
    max: Grid_Vec2;
}

Collider_Tag :: enum u8 {
    WALL;
    ONEWAY;
}

Entity_Tag :: enum u8 {
    STATIC_COLLIDER;
    CRATE;
    BUTTON;
    LEVER;
}

Grid_Vec2 :: struct {
    x: u8;
    y: u8;
}

init_editor_room :: () {
    if !context.current_editor_room {
        context.current_editor_room = New(Editor_Room);
        context.current_editor_room.* = make_editor_room("New Room");
    }
}

make_editor_room :: (name: string) -> Editor_Room {
    room: Editor_Room;
    room.name = copy_string(name);
    return room;
}

Room_Tile :: enum u8 {
    EMPTY;
    WALL;
    SLOPE;
}

// When baking, decompose level tiles in several steps
// 1. Greedy Mesh Walls
// 2. Create triangles for slopes
// At the end we will have an array of entites to save to the room

paint_tile_values :: () {
    room_ptr := context.current_editor_room;
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

check_tile_value :: (r: *Editor_Room, x: int, y: int) -> Room_Tile {
    return r.int_grid[coord_to_index(x, y)];
}

set_tile_value :: (r: *Editor_Room, value: Room_Tile, x: int, y: int) {
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

parse_tiles :: (r: *Editor_Room) {
    is_valid_wall :: (x: int, y: int) -> bool #expand {
        return !`parsed[coord_to_index(x, y)] && check_tile_value(`r, x, y) == .WALL;
    }

    array_reset(*r.colliders);

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
                wall := make_wall_from_grid(left, right, bot, top);
                array_add(*r.colliders, wall);
            }
        }
    }

    // Start a second loop for non wall entities
    for <y: 0..ROOM_HEIGHT - 1 {
        for x: 0..ROOM_WIDTH - 1 {
            if check_tile_value(r, x, y) == {
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

rotate_coord :: (c: Grid_Vec2) -> Grid_Vec2 #expand {
    return .{x = ROOM_WIDTH - c.y - 1, y = c.x};
}

rotate_room :: (r: Editor_Room) -> Editor_Room {
    out: Editor_Room;
    for x: 0..ROOM_WIDTH - 1 {
        for y: 0..ROOM_HEIGHT - 1 {
            new_index := coord_to_index(ROOM_WIDTH - y - 1, x);
            old_index := coord_to_index(x, y);
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
    return out;
}

make_wall_from_grid :: (left: int, right: int, bot: int, top: int) -> Editor_Collider {
    collider: Editor_Collider;
    collider.tag = .WALL;
    collider.min = .{cast(u8)left, cast(u8)bot};
    collider.max = .{cast(u8)(right + 1), cast(u8)(top + 1)};
    return collider;
}
