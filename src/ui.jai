/* I think there is a way to generate a lot of this comp time, should probably look at a named enum and for each one
1. Add name into the Tile Types array
2. 
*/
EDITOR_MODES: [2]string: .["Room", "Map"];
TILE_TYPES: [4]string: .["Wall", "Crate", "Moving Block", "Button"];
TILE_ICONS: [4]Ui_Icon;

Ui_Icon :: struct {
    sprite: *Sprite;
    color: Vector4 = .{1, 1, 1, 1};
}

ROOM_VIEW :: 0;
MAP_VIEW :: 1;
GAME_VIEW :: 2;

Editor_State :: struct {
    editor_type: s32;
    editor_theme: Overall_Theme;
    room_options: Room_Editor_Options;
    show_file_load_window: bool;
    load_window_scroll_value: float32;
    kb_captured: bool;
    mouse_captured: bool;
    map_cursor_position: Coord;
    primary_window: Subwindow_Info = .{
                                       rect = #run get_rect(20, cast(float32)WINDOW_HEIGHT - 510, 400, 500),
                                       draw = draw_primary_window,
                                       title_text = "Editor"};
    file_load_window: Subwindow_Info = .{
                                         rect = #run get_rect((cast(float32)WINDOW_WIDTH / 2) - 400, cast(float32)WINDOW_HEIGHT - 800, 800, 600),
                                         open = false,
                                         draw = draw_file_load_window,
                                         title_text = "Load Room"};
}

Room_Editor_Options :: struct {
    tile_type: s32;
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
    TILE_ICONS[0] = .{color = .{0, 0, 1, 1}};
    // Crate
    TILE_ICONS[1] = .{sprite = *context.atlas.crate};
}

render_editor_ui :: () {
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
    button_extents := Vector2.{200, 60};
    room_files_rect := get_rect(r.x + 20, r.y + 20, r.w - 40, r.h - 40);
    scroll_region, inside := begin_scrollable_region(room_files_rect, *editor_state.editor_theme.scrollable_region_theme);
    s := inside;
    s.y = s.y + s.h - button_extents.y;
    s.h = button_extents.y;
    s.y += editor_state.load_window_scroll_value;

    for file_list("assets/rooms",, temp) {
        _, _, extension, filename := path_decomp(it);
        if equal(extension, "room") {
            pressed := button(s, filename, identifier = it_index);
            s.y -= 60;
            if pressed {
                context.current_editor_room.* = load_room(filename);
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

    dropdown(dropdown_rect, EDITOR_MODES, *editor_state.editor_type);
    if context.editor_state.editor_type == {
    case 0;
        // Tile painting
        room_options := *editor_state.room_options;
        tile_type_rect := get_rect(x_pos, y_pos, 200, 50);
        y_pos -= 50;
        dropdown(tile_type_rect, TILE_TYPES, *room_options.tile_type);

        left := tile_type_rect.x + tile_type_rect.w;
        right := left + 50;
        top := tile_type_rect.y + tile_type_rect.h;
        bot := tile_type_rect.y;

        // Tile Display Index
        tdi := context.editor_state.room_options.tile_type;

        if TILE_ICONS[tdi].sprite {
            s := TILE_ICONS[tdi].sprite;
            set_shader_for_images(s.texture);
            immediate_quad(.{left, top}, .{left, bot}, .{right, bot}, .{right, top}, TILE_ICONS[tdi].color, s.uvs[0], s.uvs[1], s.uvs[2], s.uvs[3]);
        } else {
            set_shader_for_color();
            immediate_quad(.{left, top}, .{left, bot}, .{right, bot}, .{right, top}, TILE_ICONS[tdi].color);
        }

        // Name
        name_rect := get_rect(x_pos, y_pos, 300, 40);
        name_action, new_name := text_input(name_rect, context.current_editor_room.name, *editor_state.editor_theme.text_input_theme);
        if name_action & .ENTERED || name_action & .TEXT_MODIFIED modify_string(*context.current_editor_room.name, new_name);
        y_pos -= 45;

        // Runes
        // Crescents
        crescent_rect := get_rect(x_pos - 100, y_pos, 300, 30);
        label(crescent_rect, "Rune", *editor_state.editor_theme.label_theme);
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

modify_string :: (ps: *string, new_value: string) {
    free(ps.*);
    ps.* = copy_string(new_value);
}
