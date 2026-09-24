Camera :: struct {
    target_position: Vector2;
    position: Vector2;
    zoom: float32 = 1;
    smoothing: float32 = 10;
    target_room: Coord;
    room_offset := Vector2.{0, 12};
    camera_look: Vector2;
    BASE_PLAYER_OFFSET := Vector2.{320, 75};
}

#add_context camera: *Camera;

init_camera :: () {
    if !context.camera {
        context.camera = New(Camera);
    }
}

camera_smoothing :: (delta: float32) {
    if distance(context.camera.target_position, context.camera.position) > 1 {
        context.camera.position = lerp(context.camera.position, context.camera.target_position, delta * context.camera.smoothing);
    }
}

camera_look :: () {
    look_delta: float32;
    if is_action_held(.MOVE_UP) look_delta += 196;
    if is_action_held(.MOVE_DOWN) look_delta -= 160;

    context.camera.camera_look.y = look_delta + 24;
}

camera_follow :: () {
    player := player_get();
    if player {
        raw_pos := player.position + context.camera.camera_look;

        min, max := camera_bounds_from_room(context.camera.target_room);
        true_pos: Vector2;
        true_pos.x = clamp(raw_pos.x, min.x, max.x);
        true_pos.y = clamp(raw_pos.y, min.y, max.y);
        context.camera.target_position = true_pos;
    }
}

camera_bounds_from_room :: (c: Coord) -> Vector2, Vector2 {
    x_units: float32 = xx (ROOM_WIDTH + COLUMN_WIDTH);
    y_units: float32 = xx (ROOM_HEIGHT + COLUMN_WIDTH);

    x := cast(float32)c.x * TILE_SIZE * x_units;
    y := cast(float32)c.y * TILE_SIZE * y_units;
    room_bottom_left := Vector2.{x, y};
    // print("Camera: %\nRoom_Bottom_Left: %\n", context.camera.position, room_bottom_left);
    min := Vector2.{x + (TILE_SIZE * 20.5), y + (TILE_SIZE * 11.75 * context.camera.zoom)};
    max := Vector2.{x + (TILE_SIZE * 26.5), y + (TILE_SIZE * 35.25 * context.camera.zoom)};
    return min, max;
}

snap_camera_pos :: () {
    player := player_get();
    if player {
        raw_pos := player.position + context.camera.camera_look;

        min, max := camera_bounds_from_room(context.camera.target_room);
        true_pos: Vector2;
        true_pos.x = clamp(raw_pos.x, min.x, max.x);
        true_pos.y = clamp(raw_pos.y, min.y, max.y);
        context.camera.target_position = true_pos;
        context.camera.position = true_pos;
    }
}

zoom_camera :: (delta: float) {
    if is_action_held(.CAMERA_ZOOM_IN) context.camera.zoom += 1 * delta;
    if is_action_held(.CAMERA_ZOOM_OUT) context.camera.zoom -= 1 * delta;
}

cam_relative_pos_extents :: (p: Vector2, e: Vector2) -> Vector2, Vector2 {
    center := context.camera.position;

    // position := ((p - center) * context.camera.zoom) + center;
    position := ((p - center) * context.camera.zoom) + Vector2.{(cast(float)DISPLAY_WIDTH) / 2, (cast(float)DISPLAY_HEIGHT) / 2};
    extents := e * context.camera.zoom;
    return position, extents;
}
