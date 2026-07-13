ROOM_WIDTH :: 22;
ROOM_HEIGHT :: 22;

tile_atlas: Sprite_Atlas;

Room_Flags :: enum_flags u8 {
    NO_ROTATE :: 1 << 0;
    NO_MOVE_X :: 1 << 1;
    NO_MOVE_Y :: 1 << 2;
    NO_PICKUP :: 1 << 3;
    MUST_BE_PLACED :: 1 << 4;
}

Room :: struct {
    name: string;
    entities: [..]Entity;
    flags: Room_Flags;
    rune: Rune;
}

// Might make more sense to remove these and rotate the int grid itself
// rotate_around_pivot :: (value: Vector2, angle: float32, pivot: Vector2) -> Vector2 {
//     rel_val := value - pivot;
//     rot_val := Vector2.{
//                         (rel_val.x * cos(angle)) - (rel_val.y * sin(angle)),
//                         (rel_val.x * sin(angle)) + (rel_val.y * cos(angle))};
//     return rot_val + pivot;
// }
// 
// rotate_colliders :: () {
//     center := Vector2.{(xx WINDOW_WIDTH / 2.0), (xx WINDOW_HEIGHT / 2.0)};
//     for *colliders {
//         it.min = rotate_around_pivot(it.min, PI / 2.0, center);
//         it.max = rotate_around_pivot(it.max, PI / 2.0, center);
// 
//         print("Min: %\nMax: %\n", it.min, it.max);
//     }
// }
