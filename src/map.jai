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

Placed_Room :: struct {
    room_hash: u32;
    coord: Coord;
    rotation: u8;
}

#add_context map: *Map;

init_map :: () {
    if !context.map {
        context.map = New(Map);
    }

    for context.room_table {
        array_add(*context.map.available_rooms, it_index);
    }
}

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

render_room_and_frame :: (room: *Room, position: Vector2, size: Vector2) {
    frame_sprite := make_sprite(*context.atlas.room_frame_texture);
    render_sprite(frame_sprite, position, size);
    room_sprite := make_sprite(*room.texture);
    render_sprite(room_sprite, position, size * 0.4583);
    rune_pos := position - (size / 2) + (.{size.x * 0.18, size.y * 0.1458});
    render_rune(room.rune, rune_pos, size * 0.25, .{1, 1, 1, 1});
}
