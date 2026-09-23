COLUMN_WIDTH :: 1;
ROOM_WIDTH :: 45;
ROOM_HEIGHT :: 45;
HALF_ROOM_SIZE :: ROOM_WIDTH / 2;
MAP_WIDTH :: 10;
MAP_HEIGHT :: 10;
WORLD_WIDTH :: #run ROOM_WIDTH * MAP_WIDTH + (MAP_WIDTH + COLUMN_WIDTH);
WORLD_HEIGHT :: #run ROOM_HEIGHT * MAP_HEIGHT + (MAP_HEIGHT + COLUMN_WIDTH);
TILE_SIZE: float32: 16;

Coord :: struct {
    x: s16;
    y: s16;
}

operator * :: (c: Coord, v: Vector2) -> Vector2 {
    return Vector2.{cast(float32)c.x * v.x, cast(float32)c.y * v.y};
}

operator == :: (a: Coord, b: Coord) -> bool {
    return a.x == b.x && a.y == b.y;
}

operator + :: (a: Coord, b: Coord) -> Coord {
    c: Coord;
    c.x = a.x + b.x;
    c.y = a.y + b.y;
    return c;
}

operator - :: (a: Coord, b: Coord) -> Coord {
    c: Coord;
    c.x = a.x - b.x;
    c.y = a.y - b.y;
    return c;
}

Coord_Kind :: enum u8 {
    ROOM;
    MAP;
    WORLD;
}

Room :: struct {
    name: string;
    flags: Room_Flags;
    exits: Room_Exits;
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Collision_Tile;
    rune: Rune;
    texture: Texture;
    entities: Entity_Manager;
    static_position: Coord;
}

Room_Exits :: enum_flags u16 {
    NORTH_EAST :: 1 << 0;
    NORTH :: 1 << 1;
    NORTH_WEST :: 1 << 2;
    WEST_NORTH :: 1 << 3;
    WEST :: 1 << 4;
    WEST_SOUTH :: 1 << 5;
    SOUTH_WEST :: 1 << 6;
    SOUTH :: 1 << 7;
    SOUTH_EAST :: 1 << 8;
    EAST_SOUTH :: 1 << 9;
    EAST :: 1 << 10;
    EAST_NORTH :: 1 << 11;
}

Room_Flags :: enum_flags u16 {
    DISCOVERED :: 1 << 0;
    STATIC :: 1 << 1;
    ENTERED_NORTH :: 1 << 2;
    ENTERED_SOUTH :: 1 << 3;
    ENTERED_EAST :: 1 << 4;
    ENTERED_WEST :: 1 << 5;
    NO_ROTATE :: 1 << 6;
    NO_MOVE_X :: 1 << 7;
    NO_MOVE_Y :: 1 << 8;
    NO_PICKUP :: 1 << 9;
    MUST_BE_PLACED :: 1 << 10;
    PICKED_UP :: 1 << 11;
}

Room_Effect :: struct {
    effect: Effect_Rune;
    rooms: [..]Coord;
}

Room_Modifier :: enum {
    RAIN;
}

Room_Card :: struct {
    room_hash: u32;
    coord: Coord;
    rotation: u8;
}

Map_Room :: struct {
    rune: Rune;
    exits: Room_Exits;
    exists: bool;
    rune_parsed_x: bool;
    rune_parsed_y: bool;
}

Collision_Tile :: enum u8 {
    EMPTY;
    WALL;
    TOP_HALF;
    BOT_HALF;
    LEFT_HALF;
    RIGHT_HALF;
    BLANK;
}

World :: struct {
    collision: [WORLD_WIDTH * WORLD_HEIGHT]Collision_Tile;
    rooms: [MAP_WIDTH * MAP_HEIGHT]Map_Room;
    room_effects: [..]Room_Effect;
}

Map :: struct {
    // Rooms currently placed in the map
    placed_room_cards: [..]Room_Card;
    // Grid to indicate which cells have a room placed in them
    occupied: [MAP_WIDTH * MAP_HEIGHT]bool;
}
