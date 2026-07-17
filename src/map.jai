MAP_WIDTH :: 10;
MAP_HEIGHT :: 10;

Map :: struct {
    // Rooms currently placed in the map
    placed_rooms: [..]Placed_Room;
    // Grid to indicate which cells have a room placed in them
    occupied: [MAP_WIDTH * MAP_HEIGHT]bool;
    // Array of rooms available to place
    available_rooms: [..]u32;
}

#add_context map: *Map;

init_map :: () {
    if !context.map {
        context.map = New(Map);
    }
    load_map_rooms();
}

load_map_rooms :: () {
    for *context.room_table {
        // CHeck it.flags
    }

    // For handling rooms, add them to an array of hashes, for purposes of cycling through, and have a persistent hashmap that links loaded rooms by their hash
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
}
