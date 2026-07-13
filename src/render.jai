GRID_TILE_HEIGHT: float32: (cast(float32)(WINDOW_HEIGHT - 50) / cast(float32)ROOM_HEIGHT);
GRID_HEIGHT: float32: GRID_TILE_HEIGHT * cast(float32)ROOM_HEIGHT;
GRID_LEFT_BOUNDARY: float32: (cast(float32)WINDOW_WIDTH - GRID_HEIGHT) / 2;
GRID_RIGHT_BOUNDARY: float32: GRID_LEFT_BOUNDARY + GRID_HEIGHT;
GRID_BOT_BOUNDARY: float32: 25.0;
GRID_TOP_BOUNDARY: float32: GRID_BOT_BOUNDARY + GRID_HEIGHT;

render :: () {
    clear_render_target(0.2, 0.1, 0.5, 1);
    render_grid();
    render_room_tiles(context.current_editor_room);
    #if OS == .WINDOWS render_selection();
    // render_colliders();
    // render_sprite(player_sprite, .{500, 500}, .{200, 200});
    // render_rune(context.current_editor_room.rune, .{700, 500}, .{300, 300}, .{1, 1, 1, 1});
    render_editor_ui();
    swap_buffers(window);
}

render_grid :: () {
    set_shader_for_color();

    for 0..ROOM_HEIGHT {
        y_pos: float32 = (xx it * GRID_TILE_HEIGHT) + GRID_BOT_BOUNDARY;
        immediate_quad(
                       .{GRID_LEFT_BOUNDARY, y_pos + 2.5},
                       .{GRID_LEFT_BOUNDARY, y_pos - 2.5},
                       .{GRID_RIGHT_BOUNDARY, y_pos - 2.5},
                       .{GRID_RIGHT_BOUNDARY, y_pos + 2.5},
                       .{0, 0, 0, 1});

        x_pos: float32 = (xx it * GRID_TILE_HEIGHT) + GRID_LEFT_BOUNDARY;
        immediate_quad(
                       .{x_pos - 2.5, GRID_TOP_BOUNDARY},
                       .{x_pos - 2.5, GRID_BOT_BOUNDARY},
                       .{x_pos + 2.5, GRID_BOT_BOUNDARY},
                       .{x_pos + 2.5, GRID_TOP_BOUNDARY},
                       .{0, 0, 0, 1});
    }
}

render_boundaries_from_cell :: (x: int, y: int) -> float32, float32, float32, float32 {
    left := GRID_LEFT_BOUNDARY + (GRID_TILE_HEIGHT * xx x);
    right := GRID_LEFT_BOUNDARY + (GRID_TILE_HEIGHT * (xx x + 1));
    bot := GRID_BOT_BOUNDARY + (GRID_TILE_HEIGHT * xx y);
    top := GRID_BOT_BOUNDARY + (GRID_TILE_HEIGHT * (xx y + 1));
    return left, right, bot, top;
}

render_selection :: () {
    set_shader_for_color(true);
    x, y, ok := get_mouse_cell();

    if ok {
        left, right, bot, top := render_boundaries_from_cell(x, y);

        immediate_quad(
                       .{left, top},
                       .{left, bot},
                       .{right, bot},
                       .{right, top},
                       .{1, 1, 1, 0.3});
    }
}

render_room_tiles :: (r: *Editor_Room) {
    for <y: 0..ROOM_HEIGHT - 1 {
        for x: 0..ROOM_WIDTH - 1 {
            val := check_tile_value(r, x, y);
            left, right, bot, top := render_boundaries_from_cell(x, y);
            if val == {
            case .WALL;
                immediate_quad(
                               .{left, top},
                               .{left, bot},
                               .{right, bot},
                               .{right, top},
                               .{0, 0, 1, 1});
            case .SLOPE;
                immediate_quad(
                               .{left, top},
                               .{left, bot},
                               .{right, bot},
                               .{right, top},
                               .{0, 1, 0, 1});
            }
        }
    }
}
// 
// render_colliders :: () {
//     for colliders {
//         p0 := Vector2.{it.min.x, it.max.y};
//         p1 := Vector2.{it.min.x, it.min.y};
//         p2 := Vector2.{it.max.x, it.min.y};
//         p3 := Vector2.{it.max.x, it.max.y};
//         immediate_quad(p0, p1, p2, p3, .{0, 1, 0, 1});
//     }
// }
