Camera :: struct {
    target_position: Vector2;
    position: Vector2;
    zoom: float32;
    room_offset := Vector2.{-74, 12};
}

#add_context camera: *Camera;

init_camera :: () {
    if !context.camera {
        context.camera = New(Camera);
    }
}

cam_relative_position :: (pos: Vector2) -> Vector2 {
    return pos - context.camera.position;
}
