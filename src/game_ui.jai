LEFT_BOUND_PCT: float32: 0.21875;
RIGHT_BOUNT_PCT: float32: 0.78125;
LEFT_CHANNEL_MID_PCT: float32: #run LEFT_BOUND_PCT / 2;
RIGHT_CHANNEL_MID_PCT: float32: #run RIGHT_BOUNT_PCT + (LEFT_BOUND_PCT / 2);

render_gameplay_ui :: () {
    if get_editor_mode() == {
    case 0;
    case 1;
        render_room_placement_ui();
    }
}

render_room_placement_ui :: () {
    x: float32 = RIGHT_CHANNEL_MID_PCT * xx WINDOW_WIDTH;
    y: float32 = 950;
    element: int;
    size := Vector2.{300, 300};
    if context.map.available_rooms.count > 0 {
        for context.map.selected_idx..context.map.selected_idx + 6 {
            room := get_room_at_wrapping_index(it);
            if room {
                if it == context.map.selected_idx {
                    render_room_and_frame(room, .{x, y}, size);
                } else {
                    sprite := make_sprite(*room.texture);
                    render_sprite(sprite, .{x, y}, size * 0.4583);
                }
            }
            y -= 220;
        }
    }
}
