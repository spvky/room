Camera :: struct {
    target_position: Vector2;
    position: Vector2;
    zoom: float32;
    smoothing: float32 = 10;
    target_room: Coord;
    room_offset := Vector2.{0, 12};
    BASE_PLAYER_OFFSET := Vector2.{320, 75};
}

#add_context camera: *Camera;

init_camera :: () {
    if !context.camera {
        context.camera = New(Camera);
    }
}

camera_smoothing :: (delta: float32) {
    if is_action_held(.MENU_UP) {
        context.camera.BASE_PLAYER_OFFSET.y -= delta * 25;
    }
    if is_action_held(.MENU_DOWN) {
        context.camera.BASE_PLAYER_OFFSET.y += delta * 25;
    }
    if is_action_held(.MENU_RIGHT) {
        context.camera.BASE_PLAYER_OFFSET.x -= delta * 25;
    }
    if is_action_held(.MENU_LEFT) {
        context.camera.BASE_PLAYER_OFFSET.x += delta * 25;
    }
    if distance(context.camera.target_position, context.camera.position) > 1 {
        context.camera.position = lerp(context.camera.position, context.camera.target_position, delta * context.camera.smoothing);
    }
}

camera_follow :: () {
    player := player_get();
    raw_pos := player.position - context.camera.BASE_PLAYER_OFFSET;
    min, max := camera_bounds_from_room(context.camera.target_room);
    true_pos: Vector2;
    true_pos.x = clamp(raw_pos.x, min.x, max.x);
    true_pos.y = clamp(raw_pos.y, min.y, max.y);

    context.camera.target_position = true_pos;
}

camera_bounds_from_room :: (c: Coord) -> Vector2, Vector2 {
    x_divisor: float32 = xx (ROOM_WIDTH + COLUMN_WIDTH);
    y_divisor: float32 = xx (ROOM_HEIGHT + COLUMN_WIDTH);

    x := cast(float32)c.x * TILE_SIZE * cast(float32)(ROOM_WIDTH + COLUMN_WIDTH);
    y := cast(float32)c.y * TILE_SIZE * cast(float32)(ROOM_HEIGHT + COLUMN_WIDTH);
    min := Vector2.{x + 6, y + 6};
    max := Vector2.{x + 90, y + 368};
    return min, max;
}

cam_relative_position :: (pos: Vector2) -> Vector2 {
    return pos - context.camera.position;
}
