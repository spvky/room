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

#add_context map: *Map;

init_map :: () {
    if !context.map {
        context.map = New(Map);
    }

    for context.room_table {
        array_add(*context.map.available_rooms, it_index);
    }
}

load_map_rooms :: () {
    for *context.room_table {
        // CHeck it.flags
    }

    // For handling rooms, add them to an array of hashes, for purposes of cycling through, and have a persistent hashmap that links loaded rooms by their hash
}

get_room_at_wrapping_index :: (req_idx: int) -> *Room {
    idx := ifx req_idx == 0 then 0 else req_idx % context.map.available_rooms.count;
    return table_find_pointer(context.room_table, context.map.available_rooms[idx]);
}

next_map_selected_idx :: () {
    new_idx := context.map.selected_idx + 1;
    if new_idx >= context.map.available_rooms.count then new_idx = 0;
    context.map.selected_idx = new_idx;
}

prev_map_selected_idx :: () {
    new_idx := context.map.selected_idx - 1;
    if new_idx <= 0 then new_idx = context.map.available_rooms.count - 1;
    context.map.selected_idx = new_idx;
}

Placed_Room :: struct {
    room_hash: u32;
    coord: Coord;
    rotation: u8;
}

render_room_and_frame :: (room: *Room, position: Vector2, size: Vector2) {
    frame_sprite := make_sprite(*context.atlas.room_frame_texture);
    render_sprite(frame_sprite, position, size);
    room_sprite := make_sprite(*room.texture);
    render_sprite(room_sprite, position, size * 0.4583);
    rune_pos := position - (size / 2) + (.{size.x * 0.18, size.y * 0.1458});
    render_rune(room.rune, rune_pos, size * 0.25, .{1, 1, 1, 1});
}
