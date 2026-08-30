benchmark_code :: ($name: string, $body: Code) {
    start := current_time_monotonic();
    #insert body;
    end := current_time_monotonic();
    total_ms := to_float64_seconds(end - start) * 1000.0;
    print("%:\ntook %ms to complete!\n", name, total_ms);
}

draw_dot :: (pos: Vector2, radius: float32, color: Vector4 = .{1, 1, 1, 1}) {
    top := pos.y + radius;
    bot := pos.y - radius;
    left := pos.x - radius;
    right := pos.x + radius;
    set_shader_for_images(*context.atlas.collision_circle);
    immediate_quad(
                   .{left, top},
                   .{left, bot},
                   .{right, bot},
                   .{right, top},
                   color);
}
