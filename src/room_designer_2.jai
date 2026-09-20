Room_V2 :: struct {
    name: string;
    flags: Room_Flags;
    exits: Room_Exits;
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Collision_Tile;
    rune: Rune;
    texture: Texture;
    entities: Entity_Manager;
    static_position: Coord;
}

Mouse_Capture :: struct {
}

label_and_field :: (field_name: string, field_ptr: *$T, set_button := false) #expand {
    label_rect := get_rect(`x, `y, 150, 30);
    label(label_rect, field_name);

    if T == Vector2 {
        field_rect := get_rect(`x + 155, `y, 50, 30);
        field_string := tprint("{% , %}",
                               formatFloat(field_ptr.x, width = 1, trailing_width = 1, zero_removal = .NO),
                               formatFloat(field_ptr.x, width = 1, trailing_width = 1, zero_removal = .NO));
        label(field_rect, field_string);
        if set_button {
        }
    }
}
