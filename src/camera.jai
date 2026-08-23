Camera :: struct {
    target_position: Vector2;
    position: Vector2;
    zoom: float32;
    smoothing: float32 = 10;
    room_offset := Vector2.{-104, 12};
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

cam_relative_position :: (pos: Vector2) -> Vector2 {
    return pos - context.camera.position;
}
