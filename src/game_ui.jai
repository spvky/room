LEFT_BOUND_PCT: float32: 0.21875;
RIGHT_BOUNT_PCT: float32: 0.78125;
LEFT_CHANNEL_MID_PCT: float32: #run LEFT_BOUND_PCT / 2;
RIGHT_CHANNEL_MID_PCT: float32: #run RIGHT_BOUNT_PCT + (LEFT_BOUND_PCT / 2);

render_gameplay_ui :: () {
    x: float32 = RIGHT_CHANNEL_MID_PCT * xx WINDOW_WIDTH;
    y: float32 = 950;
    element: int;
    size := Vector2.{300, 300};
    for *context.room_table {
        if element == 0 {
            render_room_and_frame(it, .{x, y}, size);
        } else {
            sprite := make_sprite(*it.texture);
            render_sprite(sprite, .{x, y}, size * 0.4583);
        }
        y -= 220;
        element += 1;
    }
}
