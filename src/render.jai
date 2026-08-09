DISPLAY_WIDTH :: 320;
DISPLAY_HEIGHT :: 180;

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
    if context.game_state == {
    case .MAP_PLACEMENT;
        render_map_placement();
    case .ROOM_DESIGNER;
        render_room_designer();
    case .GAMEPLAY;
    }

    swap_buffers(window);
}

render_grid :: () {
    grid_lines :: (height: int) #expand {
        tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary := get_tile_ui_data(height);
        line_color: Vector4;
        if `it == height / 2 {
            line_color = .{1, 0, 0, 0.3};
        } else {
            line_color = .{0, 0, 0, 1};
        }
        y_pos: float32 = (xx `it * tile_height) + bot_boundary;
        immediate_quad(
                       .{left_boundary, y_pos + 2.5},
                       .{left_boundary, y_pos - 2.5},
                       .{right_boundary, y_pos - 2.5},
                       .{right_boundary, y_pos + 2.5},
                       line_color);

        x_pos: float32 = (xx `it * tile_height) + left_boundary;
        immediate_quad(
                       .{x_pos - 2.5, top_boundary},
                       .{x_pos - 2.5, bot_boundary},
                       .{x_pos + 2.5, bot_boundary},
                       .{x_pos + 2.5, top_boundary},
                       line_color);
    }

    set_shader_for_color(true);
    if context.game_state == {
    case .ROOM_DESIGNER;
        for 0..ROOM_HEIGHT {
            grid_lines(ROOM_HEIGHT);
            draw_current_room_exits(ROOM_HEIGHT);
        }
    case .MAP_PLACEMENT;
        for 0..MAP_HEIGHT {
            grid_lines(MAP_HEIGHT);
        }
    }
}

draw_current_room_exits :: (height: int) {
    _has_exit :: (exit: Room_Exits) -> bool #expand {
        return `room.exits & exit == exit;
    }
    room := context.current_editor_room;

    h_west_start: float32 = 445;
    h_west_end: float32 = 538.636;
    h_east_start: float32 = 1381.363;
    h_east_end: float32 = 1475;
    h_center_start: float32 = 913.181;
    h_center_end: float32 = 1006.818;

    v_north_start: float32 = 1055;
    v_north_end: float32 = 961.363;
    v_south_start: float32 = 118.636;
    v_south_end: float32 = 25;
    v_center_start: float32 = 586.818;
    v_center_end: float32 = 493.181;

    tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary := get_tile_ui_data(height);

    color := Vector4.{0.7, 0.7, 0, 1};

    if _has_exit(.NORTH_EAST) {
        immediate_quad(
                       .{h_east_start, top_boundary + 2.5},
                       .{h_east_start, top_boundary - 2.5},
                       .{h_east_end, top_boundary - 2.5},
                       .{h_east_end, top_boundary + 2.5}, color);
    }
    if _has_exit(.NORTH) {
        immediate_quad(
                       .{h_center_start, top_boundary + 2.5},
                       .{h_center_start, top_boundary - 2.5},
                       .{h_center_end, top_boundary - 2.5},
                       .{h_center_end, top_boundary + 2.5}, color);
    }
    if _has_exit(.NORTH_WEST) {
        immediate_quad(
                       .{h_west_start, top_boundary + 2.5},
                       .{h_west_start, top_boundary - 2.5},
                       .{h_west_end, top_boundary - 2.5},
                       .{h_west_end, top_boundary + 2.5}, color);
    }
    if _has_exit(.SOUTH_EAST) {
        immediate_quad(
                       .{h_east_start, bot_boundary + 2.5},
                       .{h_east_start, bot_boundary - 2.5},
                       .{h_east_end, bot_boundary - 2.5},
                       .{h_east_end, bot_boundary + 2.5}, color);
    }
    if _has_exit(.SOUTH) {
        immediate_quad(
                       .{h_center_start, bot_boundary + 2.5},
                       .{h_center_start, bot_boundary - 2.5},
                       .{h_center_end, bot_boundary - 2.5},
                       .{h_center_end, bot_boundary + 2.5}, color);
    }
    if _has_exit(.SOUTH_WEST) {
        immediate_quad(
                       .{h_west_start, bot_boundary + 2.5},
                       .{h_west_start, bot_boundary - 2.5},
                       .{h_west_end, bot_boundary - 2.5},
                       .{h_west_end, bot_boundary + 2.5}, color);
    }
    if _has_exit(.EAST_SOUTH) {
        immediate_quad(
                       .{right_boundary - 2.5, v_south_start},
                       .{right_boundary - 2.5, v_south_end},
                       .{right_boundary + 2.5, v_south_end},
                       .{right_boundary + 2.5, v_south_start},
                       color);
    }
    if _has_exit(.EAST) {
        immediate_quad(
                       .{right_boundary - 2.5, v_center_start},
                       .{right_boundary - 2.5, v_center_end},
                       .{right_boundary + 2.5, v_center_end},
                       .{right_boundary + 2.5, v_center_start},
                       color);
    }
    if _has_exit(.EAST_NORTH) {
        immediate_quad(
                       .{right_boundary - 2.5, v_north_start},
                       .{right_boundary - 2.5, v_north_end},
                       .{right_boundary + 2.5, v_north_end},
                       .{right_boundary + 2.5, v_north_start},
                       color);
    }
    if _has_exit(.WEST_SOUTH) {
        immediate_quad(
                       .{left_boundary - 2.5, v_south_start},
                       .{left_boundary - 2.5, v_south_end},
                       .{left_boundary + 2.5, v_south_end},
                       .{left_boundary + 2.5, v_south_start},
                       color);
    }
    if _has_exit(.WEST) {
        immediate_quad(
                       .{left_boundary - 2.5, v_center_start},
                       .{left_boundary - 2.5, v_center_end},
                       .{left_boundary + 2.5, v_center_end},
                       .{left_boundary + 2.5, v_center_start},
                       color);
    }
    if _has_exit(.WEST_NORTH) {
        immediate_quad(
                       .{left_boundary - 2.5, v_north_start},
                       .{left_boundary - 2.5, v_north_end},
                       .{left_boundary + 2.5, v_north_end},
                       .{left_boundary + 2.5, v_north_start},
                       color);
    }
}

render_boundaries_from_cell :: (c: Coord) -> float32, float32, float32, float32 {
    if context.game_state == .ROOM_DESIGNER || context.game_state == .MAP_PLACEMENT {
        height := ifx in_game_state(.ROOM_DESIGNER) then ROOM_HEIGHT else MAP_HEIGHT;
        tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary := get_tile_ui_data(height);

        left := left_boundary + (tile_height * xx c.x);
        right := left_boundary + (tile_height * (xx c.x + 1));
        bot := bot_boundary + (tile_height * xx c.y);
        top := bot_boundary + (tile_height * (xx c.y + 1));
        return left, right, bot, top;
    } else {
        return 0, 0, 0, 0;
    }
}

// #ROOM_DESIGNER_RENDERING
render_room_designer :: () {
    render_grid();
    #if OS == .WINDOWS render_room_designer_mouse_selection();
    render_room_tiles(context.current_editor_room);
    render_room_designer_ui();
}

render_room_designer_mouse_selection :: () {
    set_shader_for_color(true);
    cell, ok := get_mouse_cell();
    if ok {
        left, right, bot, top := render_boundaries_from_cell(cell);
        immediate_quad(
                       .{left, bot},
                       .{right, bot},
                       .{right, top},
                       .{left, top},
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

// #MAP_PLACEMENT_RENDERING
render_map_placement :: () {
    render_grid();
    render_map_placement_selected_room();
    render_map_placed_room_cards();
    render_map_placement_ui();
}
render_map_placement_selected_room :: () {
    if context.map.available_rooms.count > 0 {
        room := get_room_at_wrapping_index(context.map.selected_idx);
        room_sprite := make_sprite(*room.texture);

        left, right, bot, top := render_boundaries_from_cell(context.editor_state.map_cursor_position);
        rot := cast(float32)context.editor_state.map_cursor_rotation * (PI / 2);
        pos := Vector2.{(left + right) / 2, (top + bot) / 2};
        size := Vector2.{right - left, top - bot};
        render_sprite(room_sprite, pos, size, rotation = rot, color = .{1, 1, 1, 0.3});
    }
}

render_map_placed_room_cards :: () {
    for context.map.placed_room_cards {
        room := get_room_from_hash(it.room_hash);
        room_sprite := make_sprite(*room.texture);

        left, right, bot, top := render_boundaries_from_cell(it.coord);
        rot := cast(float32)it.rotation * (PI / 2);
        pos := Vector2.{(left + right) / 2, (top + bot) / 2};
        size := Vector2.{right - left, top - bot};
        render_sprite(room_sprite, pos, size, rotation = rot, color = .{1, 1, 1, 1});
    }
}

render_room_and_frame :: (room: *Room, position: Vector2, size: Vector2) {
    frame_sprite := make_sprite(*context.atlas.room_frame_texture);
    render_sprite(frame_sprite, position, size);
    room_sprite := make_sprite(*room.texture);
    render_sprite(room_sprite, position, size * 0.4583);
    rune_pos := position - (size / 2) + (.{size.x * 0.18, size.y * 0.1458});
    render_rune(room.rune, rune_pos, size * 0.25, .{1, 1, 1, 1});
}
