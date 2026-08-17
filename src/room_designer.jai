EDITOR_MODES: [2]string: .["Collision", "Entities"];
COLLISION_TILE_TYPES: [1]string: .["Wall"];
COLLISION_TILE_ICONS: [1]Ui_Icon;
ENTITY_TILE_TYPES: [2]string: .["Crate", "Player Spawn"];
ENTITY_TILE_ICONS: [2]Ui_Icon;

Ui_Icon :: struct {
    sprite: *Sprite;
    color: Vector4 = .{1, 1, 1, 1};
}

ROOM_VIEW :: 0;
MAP_VIEW :: 1;
GAME_VIEW :: 2;

Editor_State :: struct {
    editor_theme: Overall_Theme;
    editor_type: s32;
    collision_tile_type: s32;
    entity_tile_type: s32;
    show_file_load_window: bool;
    load_window_scroll_value: float32;
    kb_captured: bool;
    mouse_captured: bool;
    map_cursor_position: Coord;
    map_cursor_rotation: u8;
    load_static_rooms: bool;
    primary_window: Subwindow_Info = .{
                                       rect = #run get_rect(5, cast(float32)WINDOW_HEIGHT - 880, 350, 870),
                                       draw = draw_primary_window,
                                       title_text = "Editor"};
    file_load_window: Subwindow_Info = .{
                                         rect = #run get_rect((cast(float32)WINDOW_WIDTH / 2) - 400, cast(float32)WINDOW_HEIGHT - 800, 800, 600),
                                         open = false,
                                         draw = draw_file_load_window,
                                         title_text = "Load Room"};
}

#add_context editor_state: *Editor_State;

init_editor :: () {
    if !context.editor_state {
        context.editor_state = New(Editor_State);
    }
    ui_init();
    proc := default_theme_procs[0];
    context.editor_state.editor_theme = proc();
    set_default_theme(context.editor_state.editor_theme);
    init_ui_icons();
}

init_ui_icons :: () {
    // Wall
    COLLISION_TILE_ICONS[0] = .{color = .{1, 1, 1, 1}};
    // Crate
    ENTITY_TILE_ICONS[0] = .{sprite = *context.atlas.crate};
    // Player Spawn
    ENTITY_TILE_ICONS[1] = .{color = .{0.6, 0.5, 0, 1}};
}

render_room_designer_ui :: () {
    editor_state := context.editor_state;

    current_time := to_float64_seconds(current_time_monotonic());
    w, h := get_render_dimensions(window);
    editor_state.mouse_captured, editor_state.kb_captured = ui_per_frame_update(window, w, h, current_time);

    add_subwindow(*editor_state.primary_window, *editor_state.editor_theme.subwindow_theme);
    if editor_state.file_load_window.open add_subwindow(*editor_state.file_load_window, *editor_state.editor_theme.subwindow_theme);
    draw_popups();
}

draw_file_load_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    editor_state := context.editor_state;
    toggle_rect := get_rect(r.x + 20, r.y + r.h - 60, 200, 50);
    toggle_pressed := base_checkbox(toggle_rect, "Static", editor_state.load_static_rooms, *editor_state.editor_theme.checkbox_theme);
    if toggle_pressed {
        if editor_state.load_static_rooms {
            context.editor_state.load_static_rooms = false;
        } else {
            context.editor_state.load_static_rooms = true;
        }
    }

    button_extents := Vector2.{200, 60};
    room_files_rect := get_rect(r.x + 20, r.y + 20, r.w - 40, r.h - 80);
    scroll_region, inside := begin_scrollable_region(room_files_rect, *editor_state.editor_theme.scrollable_region_theme);
    s := inside;
    s.y = s.y + s.h - button_extents.y;
    s.h = button_extents.y;
    s.y += editor_state.load_window_scroll_value;
    subdir := ifx editor_state.load_static_rooms "static" else "placeable";
    dir_path := tprint("assets/rooms/%", subdir);

    for file_list(dir_path,, temp) {
        _, _, extension, filename := path_decomp(it);
        if equal(extension, "room") {
            pressed := button(s, filename, identifier = it_index);
            s.y -= 60;
            if pressed {
                context.current_editor_room.* = load_room(filename, context.editor_state.load_static_rooms);
                editor_state.file_load_window.open = false;
            }
        }
    }
    end_scrollable_region(scroll_region, s.x + s.w, s.y, *editor_state.load_window_scroll_value);
}

draw_primary_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    editor_state := context.editor_state;
    room_ptr := context.current_editor_room;
    rune_ptr := *room_ptr.rune;
    dropdown_rect := get_rect(r.x, r.y + r.h - 50, r.w, 50);
    y_pos := dropdown_rect.y - dropdown_rect.h - 10;
    x_pos := dropdown_rect.x + 5;

    // Tile painting
    tile_type_rect := get_rect(x_pos, y_pos, 200, 50);
    y_pos -= 50;
    dropdown(dropdown_rect, EDITOR_MODES, *editor_state.editor_type);
    if editor_state.editor_type == {
    case 0;
        dropdown(tile_type_rect, COLLISION_TILE_TYPES, *editor_state.collision_tile_type);
    case 1;
        dropdown(tile_type_rect, ENTITY_TILE_TYPES, *editor_state.entity_tile_type);
    }

    left := tile_type_rect.x + tile_type_rect.w;
    right := left + 50;
    top := tile_type_rect.y + tile_type_rect.h;
    bot := tile_type_rect.y;

    if editor_state.editor_type == {
    case 0;
        // Tile Display Index
        tdi := context.editor_state.collision_tile_type;

        if COLLISION_TILE_ICONS[tdi].sprite {
            s := COLLISION_TILE_ICONS[tdi].sprite;
            set_shader_for_images(s.texture);
            immediate_quad(.{left, top}, .{left, bot}, .{right, bot}, .{right, top}, COLLISION_TILE_ICONS[tdi].color, s.uvs[0], s.uvs[1], s.uvs[2], s.uvs[3]);
        } else {
            set_shader_for_color();
            immediate_quad(.{left, top}, .{left, bot}, .{right, bot}, .{right, top}, COLLISION_TILE_ICONS[tdi].color);
        }
    case 1;
        tdi := context.editor_state.entity_tile_type;

        if ENTITY_TILE_ICONS[tdi].sprite {
            s := ENTITY_TILE_ICONS[tdi].sprite;
            set_shader_for_images(s.texture);
            immediate_quad(.{left, top}, .{left, bot}, .{right, bot}, .{right, top}, ENTITY_TILE_ICONS[tdi].color, s.uvs[0], s.uvs[1], s.uvs[2], s.uvs[3]);
        } else {
            set_shader_for_color();
            immediate_quad(.{left, top}, .{left, bot}, .{right, bot}, .{right, top}, ENTITY_TILE_ICONS[tdi].color);
        }
    }

    // Name
    name_rect := get_rect(x_pos, y_pos, 300, 40);
    name_action, new_name := text_input(name_rect, context.current_editor_room.name, *editor_state.editor_theme.text_input_theme);
    if name_action & .ENTERED || name_action & .TEXT_MODIFIED modify_string(*context.current_editor_room.name, new_name);
    y_pos -= 45;

    // Runes
    // Crescents
    rune_label_rect := get_rect(x_pos - 110, y_pos, 300, 30);
    label(rune_label_rect, "Rune", *editor_state.editor_theme.label_theme);
    y_pos -= 30;
    render_rune(rune_ptr.*, .{x_pos + 290, y_pos - 20}, .{100, 100}, .{1, 1, 1, 1});
    base_marking_x := x_pos + 20;
    marking_x := base_marking_x;
    // Crescents
    room_marking_display("Do", .DO);
    room_marking_display("So", .SO);
    room_marking_display("Ko", .KO);
    room_marking_display("Lo", .LO);
    y_pos -= 30;
    marking_x = base_marking_x;
    // Slants
    room_marking_display("El", .EL);
    room_marking_display("En", .EN);
    room_marking_display("Ek", .EK);
    room_marking_display("Et", .ET);
    y_pos -= 30;
    marking_x = base_marking_x;
    // Tears
    room_marking_display("Ti", .TI);
    room_marking_display("Li", .LI);
    room_marking_display("Ki", .KI);
    room_marking_display("Di", .DI);
    y_pos -= 30;
    marking_x = base_marking_x;
    // Orbs
    room_marking_display("Ta", .TA);
    room_marking_display("Da", .DA);
    room_marking_display("La", .LA);
    room_marking_display("Ka", .KA);
    y_pos -= 30;
    marking_x = base_marking_x;
    // Sun
    su_rect := get_rect(marking_x, y_pos, 50, 30);
    y_pos -= 70;
    su_pressed := base_checkbox(su_rect, "Su", rune_ptr.encircled, *editor_state.editor_theme.checkbox_theme);
    if su_pressed {
        if rune_ptr.encircled {
            rune_ptr.encircled = false;
        } else {
            rune_ptr.encircled = true;
        }
    }
    // Flags
    flags_margin := x_pos + 20;
    flag_label_rect := get_rect(flags_margin - 130, y_pos + 30, 300, 30);
    label(flag_label_rect, "Flags", *editor_state.editor_theme.label_theme);
    enum_flag_display(*room_ptr.flags, flags_margin, y_pos);

    // Exits
    exits_margin := x_pos + 195;
    exit_label_rect := get_rect(exits_margin - 130, y_pos + 30, 300, 30);
    label(exit_label_rect, "Exits", *editor_state.editor_theme.label_theme);
    enum_flag_display(*room_ptr.exits, exits_margin, y_pos);

    y_pos -= 400;
    save_button_rect := get_rect(x_pos, y_pos, 110, 30);
    save_pressed := button(save_button_rect, "Save Room");
    if save_pressed {
        parse_tiles(room_ptr);
        // print("% Colliders added to %\n", room_ptr.colliders.count, room_ptr.name);
        save_room(room_ptr.*);
    }

    load_button_rect := get_rect(x_pos + 120, y_pos, 110, 30);
    load_pressed := button(load_button_rect, "Load Room");
    if load_pressed editor_state.file_load_window.open = true;
}

paint_tile_values :: () {
    room_ptr := context.current_editor_room;
    if !context.editor_state.mouse_captured {
        if is_action_held(.EDITOR_LEFT_CLICK) {
            cell, ok := get_mouse_cell();
            if context.editor_state.editor_type == {
            case 0;
                value_to_paint: Collision_Tile = xx (context.editor_state.collision_tile_type + 1);
                if ok {
                    set_collision_tile_value(room_ptr, value_to_paint, cell);
                }
            case 1;
                value_to_paint: Entity_Tile = xx (context.editor_state.entity_tile_type + 1);
                if ok {
                    set_entity_tile_value(room_ptr, value_to_paint, cell);
                }
            }
        }

        if is_action_held(.EDITOR_RIGHT_CLICK) {
            cell, ok := get_mouse_cell();
            if context.editor_state.editor_type == {
            case 0;
                if ok {
                    set_collision_tile_value(room_ptr, .EMPTY, cell);
                }
            case 1;
                if ok {
                    set_entity_tile_value(room_ptr, .EMPTY, cell);
                }
            }
        }
    }
}

get_mouse_cell :: () -> Coord, bool {
    width := ROOM_WIDTH;
    height := ROOM_HEIGHT;
    tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary := get_tile_ui_data(height);
    mouse_x, mouse_y, ok := get_mouse_pointer_position();

    mouse_y = WINDOW_HEIGHT - mouse_y; // Flip mouse y to match grid row ordering
    in_bounds: bool;

    mouse_x = (mouse_x - xx left_boundary) / xx tile_height;
    mouse_y = (mouse_y - xx bot_boundary) / xx tile_height;

    in_bounds = mouse_x >= 0 && mouse_x < width && mouse_y >= 0 && mouse_y < height;

    return .{xx mouse_x, xx mouse_y}, ok && in_bounds;
}

#import "GetRect";
#import "File_Utilities";

#scope_file
room_marking_display :: (label: string, marking: Markings, loc := #caller_location) #expand {
    m_rect := get_rect(`marking_x, `y_pos, 50, 30);
    `marking_x += 55;
    m_pressed := base_checkbox(m_rect, label, rune_contains(`rune_ptr, marking), *`editor_state.editor_theme.checkbox_theme, loc = loc);
    if m_pressed {
        if rune_contains(`rune_ptr, marking) {
            `rune_ptr.markings &= ~marking;
        } else {
            `rune_ptr.markings |= marking;
        }
    }
}

enum_flag_display :: (ptr_to_enum: *$T, left_margin: float32, top_margin: float32, loc := #caller_location) #expand {
    enum_type_info := cast(*Type_Info_Enum)T;
    y_pos := top_margin;
    for 0..enum_type_info.names.count - 1 {
        m_rect := get_rect(left_margin, y_pos, 140, 22);
        y_pos -= 30;
        name := enum_type_info.names[it];
        value := cast(T)enum_type_info.values[it];
        has_flag := ptr_to_enum.* & value == value;
        m_pressed := base_checkbox(m_rect, name, has_flag, *`editor_state.editor_theme.checkbox_theme, identifier = it, loc = loc);
        if m_pressed {
            if has_flag {
                ptr_to_enum.* &= ~value;
            } else {
                ptr_to_enum.* |= value;
            }
        }
    }
}

modify_string :: (ps: *string, new_value: string) {
    free(ps.*);
    ps.* = copy_string(new_value);
}
