Camera :: struct {
    target: Vector2;
    zoom: float32;
}

#add_context camera: *Camera;

init_camera :: () {
    if !context.camera {
        context.camera = New(Camera);
        context.camera.target = .{-54, 12};
    }
}

cam_relative_position :: (pos: Vector2) -> Vector2 {
    return pos - context.camera.target;
}
