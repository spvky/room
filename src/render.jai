get_tile_ui_data :: (height: int) -> float32, float32, float32, float32, float32, float32 {
    tile_height: float32 = (cast(float32)(WINDOW_HEIGHT - 50) / cast(float32)height);
    grid_height: float32 = tile_height * cast(float32)height;
    left_boundary: float32 = (cast(float32)WINDOW_WIDTH - grid_height) / 2;
    right_boundary: float32 = left_boundary + grid_height;
    bot_boundary: float32 = 25.0;
    top_boundary: float32 = bot_boundary + grid_height;

    return tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary;
}

render :: () {
    clear_render_target(0.2, 0.1, 0.5, 1);
    render_grid();
    render_room_tiles(context.current_editor_room);
    #if OS == .WINDOWS render_selection();
    // render_colliders();
    // render_sprite(player_sprite, .{500, 500}, .{200, 200});
    // render_rune(context.current_editor_room.rune, .{700, 500}, .{300, 300}, .{1, 1, 1, 1});

    x: float32 = 200;
    for *context.room_table {
        sprite := make_sprite(*it.texture);
        x += 310;
        // render_sprite(sprite, .{x, 500}, .{300, 300});
        render_room_and_frame(it, .{x, 500}, .{300, 300});
    }

    render_editor_ui();
    swap_buffers(window);
}

render_grid :: () {
    grid_lines :: (height: int) #expand {
        tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary := get_tile_ui_data(height);
        y_pos: float32 = (xx `it * tile_height) + bot_boundary;
        immediate_quad(
                       .{left_boundary, y_pos + 2.5},
                       .{left_boundary, y_pos - 2.5},
                       .{right_boundary, y_pos - 2.5},
                       .{right_boundary, y_pos + 2.5},
                       .{0, 0, 0, 1});

        x_pos: float32 = (xx `it * tile_height) + left_boundary;
        immediate_quad(
                       .{x_pos - 2.5, top_boundary},
                       .{x_pos - 2.5, bot_boundary},
                       .{x_pos + 2.5, bot_boundary},
                       .{x_pos + 2.5, top_boundary},
                       .{0, 0, 0, 1});
    }

    set_shader_for_color();

    if context.editor_state.editor_type == {
        // Room
    case 0;
        for 0..ROOM_HEIGHT {
            grid_lines(ROOM_HEIGHT);
        }
        // Map
    case 1;
        for 0..MAP_HEIGHT {
            grid_lines(MAP_HEIGHT);
        }
    }
}

render_boundaries_from_cell :: (c: Coord) -> float32, float32, float32, float32 {
    height := ifx context.editor_state.editor_type == 0 then ROOM_HEIGHT else MAP_HEIGHT;
    tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary := get_tile_ui_data(height);

    left := left_boundary + (tile_height * xx c.x);
    right := left_boundary + (tile_height * (xx c.x + 1));
    bot := bot_boundary + (tile_height * xx c.y);
    top := bot_boundary + (tile_height * (xx c.y + 1));
    return left, right, bot, top;
}

render_selection :: () {
    set_shader_for_color(true);
    cell, ok := get_mouse_cell();

    if ok {
        left, right, bot, top := render_boundaries_from_cell(cell);

        immediate_quad(
                       .{left, top},
                       .{left, bot},
                       .{right, bot},
                       .{right, top},
                       .{1, 1, 1, 0.3});
    }
}

render_room_tiles :: (r: *Room) {
    for <y: 0..ROOM_HEIGHT - 1 {
        for x: 0..ROOM_WIDTH - 1 {
            coord := Coord.{xx x, xx y};
            val := check_tile_value(r, coord);
            left, right, bot, top := render_boundaries_from_cell(coord);
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
