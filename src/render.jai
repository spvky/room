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
    case .GAMEPLAY;
        render_gameplay_scene();
    case .ROOM_EDITOR;
        render_room_editor_scene();
    }

    swap_buffers(window);
}

render_grid :: () {
    grid_lines :: (height: int) #expand {
        tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary := get_tile_ui_data(height);
        line_color: Vector4;
        // if `it == height / 2 {
        if `it == 22 || `it == 23 {
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
    case .ROOM_EDITOR;
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
    room := context.room_editor_state.current_room;

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
    if context.game_state == .ROOM_DESIGNER || context.game_state == .MAP_PLACEMENT || context.game_state == .ROOM_EDITOR {
        height := ifx in_game_state(.ROOM_DESIGNER) || in_game_state(.ROOM_EDITOR) then ROOM_HEIGHT else MAP_HEIGHT;
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

render_boundaries_from_rect :: (start: Coord, width: s16, height: s16) -> float32, float32, float32, float32 {
    if context.game_state == .ROOM_DESIGNER || context.game_state == .MAP_PLACEMENT {
        grid_display_height := ifx in_game_state(.ROOM_DESIGNER) then ROOM_HEIGHT else MAP_HEIGHT;
        tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary := get_tile_ui_data(grid_display_height);

        left := left_boundary + (tile_height * xx start.x);
        right := left_boundary + (tile_height * (xx start.x + width));
        bot := bot_boundary + (tile_height * xx start.y);
        top := bot_boundary + (tile_height * (xx start.y + height));
        return left, right, bot, top;
    } else {
        return 0, 0, 0, 0;
    }
}

// #MAP_PLACEMENT_RENDERING

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
    if context.debug_mode.on {
        clear_render_target(0.3, 0.1, 0.5, 1);
    } else {
        clear_render_target(0, 0.4, 0.6, 1);
    }
    render_entities();
    // debug_render_colliders();
    set_render_target(window);
    set_shader_for_images(context.gameplay_texture);
    sv: [4]Vector2;
    sv[0] = .{0, 0};
    sv[1] = .{xx WINDOW_WIDTH, 0};
    sv[2] = .{xx WINDOW_WIDTH, xx WINDOW_WIDTH};
    sv[3] = .{0, xx WINDOW_WIDTH};
    immediate_quad(sv[0], sv[1], sv[2], sv[3], .{1, 1, 1, 1});
    render_floating_text();
    debug_inspector_ui();
    // draw_dot(.{960, 540}, 10, .{0, 0, 0, 1});
}

render_entities :: () {
    for *context.entities {
        if !entity_has_props(it, .RENDERABLE) || entity_has_props(it, .FOREGROUND) continue;
        pos, extents := cam_relative_pos_extents(it.position, it.render_extents);
        sprite: Sprite;
        if it.render_kind == {
        case .SPRITE;
            sprite = it.sprite;
        case .SPRITE_SHEET;
            sprite = get_current_sprite_sheet_frame(*it.sprite_sheet);
        case .ANIMATION_PLAYER;
            sprite = get_current_animation_frame(*it.animation_player);
        }
        if it.tag == .ROOM_PICKUP {
            pos.y += context.camera.zoom * 4.0 * cast(float32)sin(last_time * 4);
        }
        render_sprite(*sprite, pos, extents, rotation = it.rotation);
    }
    for *context.entities {
        if !entity_has_props(it, .RENDERABLE) || !entity_has_props(it, .FOREGROUND) continue;
        pos, extents := cam_relative_pos_extents(it.position, it.render_extents);
        sprite: Sprite;
        if it.render_kind == {
        case .SPRITE;
            sprite = it.sprite;
        case .SPRITE_SHEET;
            sprite = get_current_sprite_sheet_frame(*it.sprite_sheet);
        case .ANIMATION_PLAYER;
            sprite = get_current_animation_frame(*it.animation_player);
        }
        render_sprite(*sprite, pos, extents, rotation = it.rotation);
    }
}

draw_entity_collider :: inline (e: *Entity, color: Vector4) {
    p: [4]Vector2;
    pos, extents := cam_relative_pos_extents(e.position, e.render_extents);
    half := extents / 2;
    p[0] = pos + .{-half.x, half.y};
    p[1] = pos + .{-half.x, -half.y};
    p[2] = pos + .{half.x, -half.y};
    p[3] = pos + .{half.x, half.y};
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
