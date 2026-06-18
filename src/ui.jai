EDITOR_MODES: [2]string: .["Room", "Map"];
TILE_TYPES: [2]string: .["Wall", "Slope"];

Editor_State :: struct {
    editor_type: s32;
    editor_theme: Overall_Theme;
    room_options: Room_Editor_Options;
    kb_captured: bool;
    mouse_captured: bool;
    primary_window: Subwindow_Info = .{
                                       rect = #run get_rect(20, cast(float32)WINDOW_HEIGHT - 360, 400, 350),
                                       draw = draw_primary_window,
                                       title_text = "Editor"};
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
}

render_editor_ui :: () {
    editor_state := context.editor_state;

    current_time := to_float64_seconds(current_time_monotonic());
    w, h := get_render_dimensions(window);
    editor_state.mouse_captured, editor_state.kb_captured = ui_per_frame_update(window, w, h, current_time);

    add_subwindow(*editor_state.primary_window, *editor_state.editor_theme.subwindow_theme);
    draw_popups();
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
        tile_color: Vector4;
        if context.editor_state.room_options.tile_type == {
        case 0;
            tile_color = .{0, 0, 1, 1};
        case 1;
            tile_color = .{0, 1, 0, 1};
        }
        left := tile_type_rect.x + tile_type_rect.w;
        right := left + 50;
        top := tile_type_rect.y + tile_type_rect.h;
        bot := tile_type_rect.y;
        immediate_quad(.{left, top}, .{left, bot}, .{right, bot}, .{right, top}, tile_color);
        // Name
        name_rect := get_rect(x_pos, y_pos, 300, 40);
        name_action, new_name := text_input(name_rect, context.current_editor_room.name, *editor_state.editor_theme.text_input_theme);
        if name_action & .ENTERED modify_string(*context.current_editor_room.name, new_name);
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
        su_pressed := base_checkbox(su_rect, "Su", rune_ptr.encircled, *editor_state.editor_theme.checkbox_theme);
        if su_pressed {
            if rune_ptr.encircled {
                rune_ptr.encircled = false;
            } else {
                rune_ptr.encircled = true;
            }
        }
    }
}

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

#import "GetRect";
