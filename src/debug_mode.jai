Debug_Mode_State :: struct {
    on: bool;
    dots_to_draw: [..]Dot;
}

#add_context debug_mode: *Debug_Mode_State;

init_debug_mode :: () {
    if !context.debug_mode {
        context.debug_mode = New(Debug_Mode_State);
        context.debug_mode.dots_to_draw.allocator = temp;
        array_reserve(*context.debug_mode.dots_to_draw, 4096);
    }
}

Dot :: struct {
    position: Vector2;
    radius: float;
    color: Vector4;
}

immediate_dot :: (pos: Vector2, radius: float32, color: Vector4 = .{1, 1, 1, 1}) {
    array_add(*context.debug_mode.dots_to_draw, Dot.{pos, radius, color});
}

draw_immediate_dots :: () {
    for *context.debug_mode.dots_to_draw {
        set_shader_for_images(*context.atlas.collision_circle);
        top := it.position.y + it.radius;
        bot := it.position.y - it.radius;
        left := it.position.x - it.radius;
        right := it.position.x + it.radius;

        immediate_quad(
                       .{left, top},
                       .{left, bot},
                       .{right, bot},
                       .{right, top},
                       it.color);
    }
    array_reset_keeping_memory(*context.debug_mode.dots_to_draw);
}

draw_dot :: (pos: Vector2, radius: float32, color: Vector4 = .{1, 1, 1, 1}) {
    top := pos.y + radius;
    bot := pos.y - radius;
    left := pos.x - radius;
    right := pos.x + radius;
    immediate_quad(
                   .{left, top},
                   .{left, bot},
                   .{right, bot},
                   .{right, top},
                   color);
}

draw_line :: (a: Vector2, b: Vector2, color: Vector4 = .{1, 1, 1, 1}, thickness: float = 1) {
    v := b - a;
    n := normalize(Vector2.{v.y, -v.x});

    p: [4]Vector2;

    p[0] = a + (n * thickness);
    p[1] = a - (n * thickness);
    p[2] = b - (n * thickness);
    p[3] = b + (n * thickness);

    set_shader_for_color(true);

    immediate_quad(p[0], p[1], p[2], p[3], color);
}
