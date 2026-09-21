Room_V2 :: struct {
    name: string;
    flags: Room_Flags;
    exits: Room_Exits;
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Collision_Tile;
    rune: Rune;
    texture: Texture;
    entities: Entity_Manager;
    static_position: Coord;
}

Mouse_Capture :: struct {
    building_wall: bool;
    wall_start: Coord;
}

// Use local tile size for the editor to make translating positions easier on hydration
Room_Editor_State :: struct {
    theme: Overall_Theme;
    current_room: *Room_V2;
    editor_click_mode: room_editor_Click_Mode;
    vec_setting_ptr: *Vector2;
    handle_setting_ptr: *Entity_Handle;
    entity_to_make: Entity_Tag;
    current_entity_handle: Entity_Handle;

    core_window: Subwindow_Info = .{
                                    rect = #run get_rect(5, cast(float32)WINDOW_HEIGHT - 880, 350, 870),
                                    draw = draw_core_room_window,
                                    title_text = "Room"};
    entity_window: Subwindow_Info = .{
                                      rect = #run get_rect(cast(float)WINDOW_WIDTH - 355, cast(float)WINDOW_HEIGHT - 880, 350, 870),
                                      draw = draw_entity_window,
                                      title_text = "Entity"};
}

Room_Editor_Click_Mode :: enum u8 {
    SELECT;
    SET_WALL_START;
    SET_WALL_END;
    SET_TOP_WALL_START;
    SET_TOP_WALL_END;
    SET_BOT_WALL_START;
    SET_BOT_WALL_END;
    SET_RIGHT_WALL_START;
    SET_RIGHT_WALL_END;
    SET_LEFT_WALL_START;
    SET_LEFT_WALL_END;
    VECTOR_SET;
    HANDLE_SET;
    MAKE_ENTITY;
}

#add_context room_editor_state: Room_Editor_State;

init_room_editor :: () {
    if !context.room_editor_state {
        context.room_editor_state = New(Room_Editor_State);
        context.room_editor_state.current_room = New(Room_V2);

        proc := default_theme_procs[0];
        context.room_editor_state.theme = proc();
        set_default_theme(context.room_editor_state.theme);
        context.room_editor_state.theme.label_theme.alignment = .Left;
    }
}

label_and_field :: (field_name: string, field_ptr: *$T, loc := #caller_location, set_button := true, follow_handle := true) #expand {
    label_rect := get_rect(`x, `y, 150, 30);
    label(label_rect, field_name);

    if T == Entity_Handle {
        field_rect := get_rect(`x + 155, `y, 80, 30);
        field_string: string;
        if entity_valid(field_ptr.*) {
            field_string = tprint("idx: %, gen: %", field_ptr.index, field_ptr.generation);
        } else {
            field_string = "NULL";
        }
        label(field_rect, field_string);
        if set_button {
            button_rect := get_rect(`x + 240, `y, 80, 30);
            button_text := tprint("Set", field_name);
            should_set_handle := button(button_rect, button_text);
            if should_set_handle {
                context.room_editor_state.editor_click_mode = .HANDLE_SET;
                context.room_editor_state.handle_setting_ptr = field_ptr;
            }
        }
        if follow_handle && entitiy_valid(field_ptr.*) {
            button_rect := get_rect(`x + 240, `y, 80, 30);
            button_text := tprint("Goto %", field_name);
            should_goto_handle := button(button_rect, button_text);
            if should_goto_handle {
                context.room_editor_state.current_entity_handle = field_ptr.*;
            }
        }
        `y -= 35;
    }

    if T == Vector2 {
        field_rect := get_rect(`x + 155, `y, 80, 30);
        field_string := tprint("{% , %}",
                               formatFloat(field_ptr.x, width = 1, trailing_width = 1, zero_removal = .NO),
                               formatFloat(field_ptr.x, width = 1, trailing_width = 1, zero_removal = .NO));
        label(field_rect, field_string);
        if set_button {
            button_rect := get_rect(`x + 240, `y, 80, 30);
            button_text := tprint("Set %", field_name);
            should_set_vector := button(button_rect, button_text);
            if should_set_vector {
                context.room_editor_state.editor_click_mode = .VECTOR_SET;
                context.room_editor_state.vec_setting_ptr = field_ptr;
            }
        }
        `y -= 35;
    }
}

draw_core_room_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    editor_state := context.room_editor_state;
    room_ptr := editor_state.current_room;
    rune_ptr := *room_ptr.rune;
    x := r.x;
    y := r.y + r.h;
    theme := context.room_editor_state.theme;

    // Name
    name_rect := get_rect(x_pos, y_pos, 300, 40);
    name_action, new_name := text_input(name_rect, context.current_editor_room.name, *theme.text_input_theme);
    if name_action & .ENTERED || name_action & .TEXT_MODIFIED modify_string(*context.current_editor_room.name, new_name);
    y -= 45;

    // Runes
    // Crescents
    rune_label_rect := get_rect(x, y, 300, 30);
    label(rune_label_rect, "Rune", *theme.label_theme);
    y -= 30;
    render_rune(rune_ptr.*, .{x + 290, y - 20}, .{100, 100}, .{1, 1, 1, 1});
    base_marking_x := x + 20;
    marking_x := base_marking_x;
    // Crescents
    room_marking_display("Do", .DO);
    room_marking_display("So", .SO);
    room_marking_display("Ko", .KO);
    room_marking_display("Lo", .LO);
    y -= 30;
    marking_x = base_marking_x;
    // Slants
    room_marking_display("El", .EL);
    room_marking_display("En", .EN);
    room_marking_display("Ek", .EK);
    room_marking_display("Et", .ET);
    y -= 30;
    marking_x = base_marking_x;
    // Tears
    room_marking_display("Ti", .TI);
    room_marking_display("Li", .LI);
    room_marking_display("Ki", .KI);
    room_marking_display("Di", .DI);
    y -= 30;
    marking_x = base_marking_x;
    // Orbs
    room_marking_display("Ta", .TA);
    room_marking_display("Da", .DA);
    room_marking_display("La", .LA);
    room_marking_display("Ka", .KA);
    y -= 30;
    marking_x = base_marking_x;
    // Sun
    su_rect := get_rect(marking_x, y_pos, 50, 30);
    y -= 70;
    su_pressed := base_checkbox(su_rect, "Su", rune_ptr.encircled, *theme.checkbox_theme);
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
    label(flag_label_rect, "Flags", *theme.label_theme);
    enum_flag_display(*room_ptr.flags, flags_margin, y_pos);

    // Exits
    exits_margin := x_pos + 195;
    exit_label_rect := get_rect(exits_margin - 130, y_pos + 30, 300, 30);
    label(exit_label_rect, "Exits", *theme.label_theme);
    enum_flag_display(*room_ptr.exits, exits_margin, y_pos);

    y_pos -= 400;
    save_button_rect := get_rect(x_pos, y_pos, 110, 30);
    save_pressed := button(save_button_rect, "Save Room");
    if save_pressed then save_room(room_ptr.*);

    load_button_rect := get_rect(x_pos + 120, y_pos, 110, 30);
    load_pressed := button(load_button_rect, "Load Room");
    if load_pressed editor_state.file_load_window.open = true;

    y_pos -= 40;

    if context.current_editor_room.flags & .STATIC == .STATIC {
        map_position_display(x_pos + 350, x_pos + 650, y_pos + 600, y_pos + 300);
    }
}

draw_entity_window :: (state: *Subwindow_State, r: Rect, data: *void) {
}

#scope_file
room_marking_display :: (label: string, marking: Markings, loc := #caller_location) #expand {
    m_rect := get_rect(`marking_x, `y, 50, 30);
    `marking_x += 55;
    m_pressed := base_checkbox(m_rect, label, rune_contains(`rune_ptr, marking), *`theme.checkbox_theme, loc = loc);
    if m_pressed {
        if rune_contains(`rune_ptr, marking) {
            `rune_ptr.markings &= ~marking;
        } else {
            `rune_ptr.markings |= marking;
        }
    }
}
