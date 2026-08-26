DISPLAY_WIDTH :: #run cast(s32)(TILE_SIZE * 40); // 320;
DISPLAY_HEIGHT :: #run cast(s32)((cast(float32)TILE_SIZE * 22.5)); // 180;

#add_context gameplay_texture: *Texture;

init_rendering :: () {
    if !context.gameplay_texture {
        context.gameplay_texture = New(Texture);
        context.gameplay_texture.* = texture_create_render_target(DISPLAY_WIDTH, DISPLAY_WIDTH, xx 4, .No_Skip_Mipmaps);
    }
}

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
        render_map_placement_scene();
    case .ROOM_DESIGNER;
        render_room_designer_scene();
    case .GAMEPLAY;
        render_gameplay_scene();
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
                       .{left_boundary, y_pos + 1.5},
                       .{left_boundary, y_pos - 1.5},
                       .{right_boundary, y_pos - 1.5},
                       .{right_boundary, y_pos + 1.5},
                       line_color);

        x_pos: float32 = (xx `it * tile_height) + left_boundary;
        immediate_quad(
                       .{x_pos - 1.5, top_boundary},
                       .{x_pos - 1.5, bot_boundary},
                       .{x_pos + 1.5, bot_boundary},
                       .{x_pos + 1.5, top_boundary},
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
render_room_designer_scene :: () {
    if context.editor_state.editor_type == {
    case 0;
        render_room_entities(context.current_editor_room, true);
        render_grid();
        #if OS == .WINDOWS render_room_designer_mouse_selection();
        render_room_collision(context.current_editor_room);
    case 1;
        render_room_collision(context.current_editor_room, true);
        render_grid();
        #if OS == .WINDOWS render_room_designer_mouse_selection();
        render_room_entities(context.current_editor_room);
    }
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

render_room_collision :: (r: *Room, faded := false) {
    for <y: 0..ROOM_HEIGHT - 1 {
        for x: 0..ROOM_WIDTH - 1 {
            coord := Coord.{xx x, xx y};
            val := check_collision_tile_value(r, coord);
            left, right, bot, top := render_boundaries_from_cell(coord);
            v_mid := (top + bot) / 2;
            h_mid := (right + left) / 2;
            color: Vector4;
            alpha: float32 = ifx faded then 0.3 else 1;
            if val == {
            case .WALL;
                immediate_quad(
                               .{left, top},
                               .{left, bot},
                               .{right, bot},
                               .{right, top},
                               .{1, 1, 1, alpha});
            case .TOP_HALF;
                immediate_quad(
                               .{left, top},
                               .{left, v_mid},
                               .{right, v_mid},
                               .{right, top},
                               .{1, 1, 1, alpha});
            case .BOT_HALF;
                immediate_quad(
                               .{left, v_mid},
                               .{left, bot},
                               .{right, bot},
                               .{right, v_mid},
                               .{1, 1, 1, alpha});
            case .LEFT_HALF;
                immediate_quad(
                               .{left, top},
                               .{left, bot},
                               .{h_mid, bot},
                               .{h_mid, top},
                               .{1, 1, 1, alpha});
            case .RIGHT_HALF;
                immediate_quad(
                               .{h_mid, top},
                               .{h_mid, bot},
                               .{right, bot},
                               .{right, top},
                               .{1, 1, 1, alpha});
            }
        }
    }
}

render_room_entities :: (r: *Room, faded := false) {
    for <y: 0..ROOM_HEIGHT - 1 {
        for x: 0..ROOM_WIDTH - 1 {
            coord := Coord.{xx x, xx y};
            val := check_entity_tile_value(r, coord);
            left, right, bot, top := render_boundaries_from_cell(coord);
            color: Vector4;
            alpha: float32 = ifx faded then 0.3 else 1;
            if val == {
            case .CRATE;
                set_shader_for_images(context.atlas.crate.texture);
                immediate_quad(
                               .{left, top},
                               .{left, bot},
                               .{right, bot},
                               .{right, top},
                               .{1, 1, 1, alpha},
                               .{0, 1 - 0.03125},
                               .{0.03125, 1 - 0.03125},
                               .{0.03125, 1},
                               .{0, 1});
            case .PLAYER_SPAWN;
                set_shader_for_color(true);
                immediate_quad(
                               .{left, top},
                               .{left, bot},
                               .{right, bot},
                               .{right, top},
                               .{0.6, 0.5, 0, alpha});
            }
        }
    }
}

// #MAP_PLACEMENT_RENDERING
render_map_placement_scene :: () {
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
        render_sprite(*room_sprite, pos, size, rotation = rot, color = .{1, 1, 1, 0.3});
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
        render_sprite(*room_sprite, pos, size, rotation = rot, color = .{1, 1, 1, 1});
    }
}

render_room_and_frame :: (room: *Room, position: Vector2, size: Vector2) {
    frame_sprite := make_sprite(*context.atlas.room_frame_texture);
    render_sprite(*frame_sprite, position, size);
    room_sprite := make_sprite(*room.texture);
    render_sprite(*room_sprite, position, size * 0.4583);
    rune_pos := position - (size / 2) + (.{size.x * 0.18, size.y * 0.1458});
    render_rune(room.rune, rune_pos, size * 0.25, .{1, 1, 1, 1});
}

// #GAMEPLAY_RENDERING
render_gameplay_scene :: () {
    set_render_target(context.gameplay_texture);
    // Set the GL_Nearest flag to remove antialiasing
    GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
    GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
    clear_render_target(0.5, 0.5, 0.5, 1);
    render_entities();
    debug_render_colliders();
    set_render_target(window);
    set_shader_for_images(context.gameplay_texture);
    sv: [4]Vector2;
    sv[0] = .{0, 0};
    sv[1] = .{xx WINDOW_WIDTH, 0};
    sv[2] = .{xx WINDOW_WIDTH, xx WINDOW_WIDTH};
    sv[3] = .{0, xx WINDOW_WIDTH};
    immediate_quad(sv[0], sv[1], sv[2], sv[3], .{1, 1, 1, 1});
}

player_pos := Vector2.{64, 32};
player_colliding: bool;

render_entities :: () {
    if is_action_held(.MOVE_RIGHT) {
        player_pos.x += 0.01;
    }
    if is_action_held(.MOVE_LEFT) {
        player_pos.x -= 0.01;
    }
    for *context.entities {
        if !entity_has_props(it, .RENDERABLE) continue;
        pos := cam_relative_position(it.position);
        if it.shape_kind == {
        case .RECTANGLE;
            render_sprite(it.sprite, pos, it.extents);
        case .CIRCLE;
            render_sprite(it.sprite, pos, .{it.radius * 2, it.radius * 2});
        }
    }
}

draw_entity_collider :: inline (e: *Entity, color: Vector4) {
    p: [4]Vector2;
    half := e.extents / 2;
    pos := cam_relative_position(e.position);
    if e.shape_kind == {
    case .RECTANGLE;
        p[0] = pos + .{-half.x, half.y};
        p[1] = pos + .{-half.x, -half.y};
        p[2] = pos + .{half.x, -half.y};
        p[3] = pos + .{half.x, half.y};
    case .CIRCLE;
        p[0] = pos + .{e.radius, e.radius};
        p[1] = pos + .{-e.radius, -e.radius};
        p[2] = pos + .{e.radius, -e.radius};
        p[3] = pos + .{e.radius, e.radius};
    }
    immediate_quad(p[0], p[1], p[2], p[3], color);
}

debug_render_colliders :: () {
    for *context.entities {
        // if !entity_has_props(it, .SENSOR) continue;
        if it.shape_kind == {
        case .RECTANGLE;
            set_shader_for_color(true);
        case .CIRCLE;
            set_shader_for_images(*context.atlas.collision_circle);
        }
        color := Vector4.{0, 0, 1, 0.3};
        if entity_has_props(it, .SENSOR) color = .{0.98, 0.95, 0.21, 0.3};
        draw_entity_collider(it, color);
    }
}
