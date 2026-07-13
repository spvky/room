MAP_WIDTH :: 25;
MAP_HEIGHT :: 25;

Map :: struct {
    placed_rooms: [..]Placed_Room;
    occupied: [MAP_WIDTH * MAP_HEIGHT]bool;
}

Room_Table :: Table(u32, Editor_Room);

// For handling rooms, add them to an array of hashes, for purposes of cycling through, and have a persistent hashmap that links loaded rooms by their hash

Placed_Room :: struct {
    room_hash: u32;
    coord: Room_Coord;
    rotation: u8;
}

Room_Coord :: struct {
    x: u8;
    y: u8;
}

/*
hashing room name
djb2_hash(room_name);

#import "Hash";
*/
