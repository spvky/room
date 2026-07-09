MAP_WIDTH :: 25;
MAP_HEIGHT :: 25;

Map :: struct {
    placed_rooms: [..]Placed_Room;
    occupied: [MAP_WIDTH * MAP_HEIGHT]bool;
}

// For handling rooms, add them to an array of hashes, for purposes of cycling through, and have a persistent hashmap that links loaded rooms by their hash

Placed_Room :: struct {
    room_hash: u16;
    coord: Room_Coord;
    rotation: u8;
}

Room_Coord :: struct {
    x: u8;
    y: u8;
}

hash_room_name :: (name: string) -> u16 {
    hash: u32 = 2166136261;
    for name {
        hash ^= cast(u32)it;
        // Need to find out how to do a wrapping multiply here
        // hash = wrapping_overflow_mul(16777619);
    }
    return cast(u16)((hash >> 16) ^ (hash & 0xFFFF));
}
