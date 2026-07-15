MAP_WIDTH :: 10;
MAP_HEIGHT :: 10;

Map :: struct {
    placed_rooms: [..]Placed_Room;
    occupied: [MAP_WIDTH * MAP_HEIGHT]bool;
}

// For handling rooms, add them to an array of hashes, for purposes of cycling through, and have a persistent hashmap that links loaded rooms by their hash

Placed_Room :: struct {
    room_hash: u32;
    coord: Coord;
    rotation: u8;
}
