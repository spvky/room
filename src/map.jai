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
        if it.flags
    }

    // For handling rooms, add them to an array of hashes, for purposes of cycling through, and have a persistent hashmap that links loaded rooms by their hash

    Placed_Room :: struct {
        room_hash: u32;
        coord: Coord;
        rotation: u8;
    }

    place_room :: (hash: u32) {
    }
}
