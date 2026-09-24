Map_Screen_State :: struct {
    selected_idx: int;
    cursor_position: Coord;
    cursor_rotation: u8;
    available_rooms: [..]u32;
    cursor_state: Map_Cursor_State;
}

Map_Cursor_State :: enum {
    SELECT;
    PLACE;
}

Map_Direction :: enum {
    EAST;
    SOUTH;
    WEST;
    NORTH;
}

#add_context room_table: *Table(u32, Room);
#add_context map: *Map;
#add_context map_screen_state: *Map_Screen_State;
#add_context world: *World;

init_rooms :: () {
    if !context.room_table {
        context.room_table = New(Table(u32, Room));
    }
    rooms_refresh();
}

render_map_placement_scene :: () {
    render_grid();
    render_map_placed_room_cards();
    render_map_placement_cursor();
    render_map_placement_ui();
    render_map_screen_controls();
}

render_map_placement_cursor :: () {
    sprite_to_render: Sprite;
    color: Vector4;
    if context.map_screen_state.cursor_state == {
    case .PLACE;
        coord_idx := coord_to_index(context.map_screen_state.cursor_position, .MAP);
        if context.map.occupied[coord_idx] {
            color = .{1, 0, 0, 0.5};
        } else {
            color = .{1, 1, 1, 0.5};
        }
        room := get_room_at_wrapping_index(context.map_screen_state.selected_idx);
        sprite_to_render = make_sprite(*room.texture);
    case .SELECT;
        sprite_to_render = make_sprite(*context.atlas.map_cursor);
        color = .{1, 1, 1, 1};
    }

    left, right, bot, top := render_boundaries_from_cell(context.map_screen_state.cursor_position);
    rot := cast(float32)context.map_screen_state.cursor_rotation * (PI / 2);
    pos := Vector2.{(left + right) / 2, (top + bot) / 2};
    size := Vector2.{right - left, top - bot};
    render_sprite(*sprite_to_render, pos, size, rotation = rot, color = color);
}

render_map_placed_room_cards :: () {
    for context.map.placed_room_cards {
        room := get_room_from_hash(it.room_hash);
        room_sprite := make_sprite(*room.texture);

        left, right, bot, top := render_boundaries_from_cell(it.coord);
        rot := cast(float32)it.rotation * (PI / 2);
        pos := Vector2.{(left + right) / 2, (top + bot) / 2};
        size := Vector2.{right - left, top - bot};
        render_sprite(*room_sprite, pos, size, rotation = rot, color = .{1, 1, 1, 1});
    }
}

rooms_refresh :: () {
    if context.room_table.count > 0 {
        table_reset(context.room_table);
    }
    load_all_rooms();
}

init_map :: () {
    if !context.map_screen_state {
        context.map_screen_state = New(Map_Screen_State);
    }

    if !context.map {
        context.map = New(Map);
    }
    map_refresh();
}

map_refresh :: () {
    if context.map_screen_state.available_rooms.count > 0 {
        array_reset_keeping_memory(*context.map_screen_state.available_rooms);
    }
    if context.map.placed_room_cards.count > 0 {
        array_reset_keeping_memory(*context.map.placed_room_cards);
    }
    memset(*context.map.occupied, 0, MAP_WIDTH * MAP_HEIGHT);

    for context.room_table {
        if it.flags & .STATIC == 0 {
            // array_add(*context.map_screen_state.available_rooms, it_index);
        } else {
            room_card: Room_Card;
            room_card.room_hash = it_index;
            room_card.coord = it.static_position;
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

rotate_room :: (r: Room) -> Room {
    out: Room;
    for x: 0..ROOM_WIDTH - 1 {
        for y: 0..ROOM_HEIGHT - 1 {
            new_index := coord_to_index(.{xx (ROOM_WIDTH - y - 1), xx x});
            old_index := coord_to_index(.{xx x, xx y});
            out.int_grid[new_index] = rotate_collision_tile(r.int_grid[old_index]);
        }
    }
    // Need to rotate_entities here
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

// Map Placement and editing
get_room_at_wrapping_index :: (req_idx: int) -> *Room {
    idx := ifx req_idx == 0 then 0 else req_idx % context.map_screen_state.available_rooms.count;
    return table_find_pointer(context.room_table, context.map_screen_state.available_rooms[idx]);
}

next_map_selected_idx :: () {
    new_idx := context.map_screen_state.selected_idx + 1;
    if new_idx >= context.map_screen_state.available_rooms.count then new_idx = 0;
    context.map_screen_state.selected_idx = new_idx;
}

prev_map_selected_idx :: () {
    new_idx := context.map_screen_state.selected_idx - 1;
    if new_idx < 0 then new_idx = context.map_screen_state.available_rooms.count - 1;
    context.map_screen_state.selected_idx = new_idx;
}

rotate_map_selected_room :: () {
    new_rot := context.map_screen_state.cursor_rotation + 1;
    if new_rot > 3 then new_rot = 0;
    context.map_screen_state.cursor_rotation = new_rot;
}

map_tile_occupied :: inline (c: Coord) -> bool {
    return context.map.occupied[coord_to_index(c, .MAP)];
}

place_or_select_room_at_position :: () {
    coord_idx := coord_to_index(context.map_screen_state.cursor_position, .MAP);
    if context.map_screen_state.cursor_state == {
    case .PLACE;
        avail_idx := context.map_screen_state.selected_idx;

        if context.map.occupied[coord_idx] {
            print("TRIED TO PLACE MAP IN OCCUPIED SPACE BECAUSE IM INCONSIDERATE\n");
            // play sound and trigger some juice
        } else {
            context.map.occupied[coord_idx] = true;
            room_card: Room_Card;
            room_card.room_hash = context.map_screen_state.available_rooms[avail_idx];
            room_card.coord = context.map_screen_state.cursor_position;
            room_card.rotation = context.map_screen_state.cursor_rotation;

            array_add(*context.map.placed_room_cards, room_card);
            array_ordered_remove_by_index(*context.map_screen_state.available_rooms, avail_idx);

            if context.map_screen_state.available_rooms.count > 0 {
                next_map_selected_idx();
            } else {
                context.map_screen_state.cursor_state = .SELECT;
            }
        }
    case .SELECT;
        if context.map.occupied[coord_idx] {
            pos := context.map_screen_state.cursor_position;
            idx_of_room: int;
            for context.map.placed_room_cards {
                if it.coord == pos {
                    idx_of_room = it_index;
                    break;
                }
            }

            placed_card := context.map.placed_room_cards[idx_of_room];
            hash := placed_card.room_hash;
            room_to_grab := table_find_pointer(context.room_table, hash);
            room_is_occupied := placed_card.coord == context.game_data.player_current_room;
            if !room_to_grab {
                print("Tried to grab a room with an invalid ptr\n");
            }

            if room_to_grab.flags & .STATIC == .STATIC || room_is_occupied {
                if room_is_occupied print("Can't move the room you are currently in\n");
                // Add screen shake and play a sound
            } else {
                context.map_screen_state.cursor_rotation = context.map.placed_room_cards[idx_of_room].rotation;
                context.map.occupied[coord_idx] = false;
                array_unordered_remove_by_index(*context.map.placed_room_cards, idx_of_room);
                array_add(*context.map_screen_state.available_rooms, hash);

                returned_room_idx: int;
                for context.map_screen_state.available_rooms {
                    if it == hash {
                        returned_room_idx = it_index;
                        break;
                    }
                }
                context.map_screen_state.selected_idx = returned_room_idx;
                context.map_screen_state.cursor_state = .PLACE;
            }
        }
    }
}

move_map_cursor :: () {
    if is_action_buffered(.MOVE_LEFT) {
        consume_action(.MOVE_LEFT);
        new_x := context.map_screen_state.cursor_position.x - 1;
        if new_x < 0 {
            new_x = 0;
        }
        context.map_screen_state.cursor_position.x = new_x;
    }

    if is_action_buffered(.MOVE_RIGHT) {
        consume_action(.MOVE_RIGHT);
        new_x := context.map_screen_state.cursor_position.x + 1;
        if new_x > MAP_WIDTH - 1 {
            new_x = MAP_WIDTH - 1;
        }
        context.map_screen_state.cursor_position.x = new_x;
    }

    if is_action_buffered(.MOVE_UP) {
        consume_action(.MOVE_UP);
        new_y := context.map_screen_state.cursor_position.y + 1;
        if new_y > MAP_HEIGHT - 1 {
            new_y = MAP_HEIGHT - 1;
        }
        context.map_screen_state.cursor_position.y = new_y;
    }

    if is_action_buffered(.MOVE_DOWN) {
        consume_action(.MOVE_DOWN);
        new_y := context.map_screen_state.cursor_position.y - 1;
        if new_y < 0 {
            new_y = 0;
        }
        context.map_screen_state.cursor_position.y = new_y;
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

    if is_action_buffered(.CONFIRM) {
        consume_action(.CONFIRM);
        place_or_select_room_at_position();
    }

    if is_action_buffered(.CANCEL) {
        consume_action(.CANCEL);

        if context.map_screen_state.cursor_state == .PLACE {
            context.map_screen_state.cursor_state = .SELECT;
        } else if context.map_screen_state.cursor_state == .SELECT && context.map_screen_state.available_rooms.count > 0 {
            context.map_screen_state.cursor_state = .PLACE;
        }
    }

    if is_action_buffered(.BAKE_MAP) {
        consume_action(.BAKE_MAP);
        bake_world();
    }

    if is_action_buffered(.INTERACT) {
        consume_action(.INTERACT);
        exit_map_placement_screen();
    }
}

render_map_screen_controls :: () {
    screen_x := 15;
    screen_y := (cast(int)WINDOW_HEIGHT) - 50;
    draw_text(context.atlas.font, screen_x, screen_y, "WASD - MOVE");
    screen_y -= 100;
    if context.map_screen_state.cursor_state == {
    case .SELECT;
        draw_text(context.atlas.font, screen_x, screen_y, "RTRN - PICK_UP");
    case .PLACE;
        draw_text(context.atlas.font, screen_x, screen_y, "RTRN - PLACE");
    }
    screen_y -= 100;
    draw_text(context.atlas.font, screen_x, screen_y, "BCK_SPCE - MODE");
    screen_y -= 100;
    draw_text(context.atlas.font, screen_x, screen_y, "R - ROTATE");
    screen_y -= 100;
    if context.map_screen_state.cursor_state == .PLACE && context.map_screen_state.available_rooms.count > 1 {
        draw_text(context.atlas.font, screen_x, screen_y, "UP/DOWN - SELECT");
    }
}

calculate_map_coord_from_position :: (position: Vector2) -> Coord, bool {
    raw_conversion := Vector2.{position.x / TILE_SIZE, position.y / TILE_SIZE};
    c := Coord.{xx raw_conversion.x, xx raw_conversion.y};
    if c.x == 0 && c.y == 0 return c, false;
    if c.x % (ROOM_WIDTH + COLUMN_WIDTH) == 0 || c.y % (ROOM_HEIGHT + COLUMN_WIDTH) == 0 return c, false;
    c.x = c.x / (ROOM_WIDTH + COLUMN_WIDTH);
    c.y = c.y / (ROOM_HEIGHT + COLUMN_WIDTH);
    return c, true;
}
