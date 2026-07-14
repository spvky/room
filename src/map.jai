MAP_WIDTH :: 10;
MAP_HEIGHT :: 10;

Map :: struct {
    placed_rooms: [..]Placed_Room;
    occupied: [MAP_WIDTH * MAP_HEIGHT]bool;
}

Room_Table :: Table(u32, Editor_Room);

// For handling rooms, add them to an array of hashes, for purposes of cycling through, and have a persistent hashmap that links loaded rooms by their hash

Placed_Room :: struct {
    room_hash: u32;
    coord: Map_Coord;
    rotation: u8;
    flags: Placed_Room_Flags;
}

Map_Coord :: struct {
    raw: [2]u8;
    #overlay (raw) x: u8;
    #overlay (raw[1]) y: u8;
}

Placed_Room_Flags :: enum_flags u8 {
    DISCOVERED :: 1 << 0;
    ENTERED_NORTH :: 1 << 1;
    ENTERED_SOUTH :: 1 << 2;
    ENTERED_EAST :: 1 << 3;
    ENTERED_WEST :: 1 << 4;
}

/*
hashing room name
djb2_hash(room_name);

#import "Hash";
*/
