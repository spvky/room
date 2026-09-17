Inspector_State :: struct {
    current_handle: Entity_Handle;
    inspector_window: Subwindow_Info = .{
                                         rect = #run get_rect(cast(float32)WINDOW_WIDTH - 405, cast(float32)WINDOW_HEIGHT - 880, 400, 870),
                                         draw = draw_inspector_window,
                                         open = false,
                                         title_text = "Inspector"};
}

#add_context inspector_state: *Inspector_State;

init_inspector :: () {
    if !context.inspector_state {
        context.inspector_state = New(Inspector_State);
    }
}

draw_inspector_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    label_margin := r.x;
    y_pos := r.y + r.h - 50;
    handle_label_rect := get_rect(label_margin, y_pos, 200, 40);
    base_theme := context.editor_state.editor_theme;
    if !entity_valid(context.inspector_state.current_handle) {
        label(handle_label_rect, "NONE", *base_theme.label_theme);
        return;
    }
    handle := *context.inspector_state.current_handle;
    handle_text := sprint("[% | %]", handle.index, handle.generation);
    label(handle_label_rect, handle_text, *base_theme.label_theme);

    entity := entity_get(handle.*);
    tag_label_rect := get_rect(label_margin + 150, y_pos, 700, 50);
    tag_text := sprint("Tag: %", entity.tag);
    label(tag_label_rect, tag_text, *base_theme.label_theme);
    y_pos -= 30;

    inspector_vec2_display("Pos", *entity.position);
    inspector_vec2_display("Velo", *entity.velocity);
    inspector_vec2_display("Inh Velocity", *entity.inherited_velocity);
    inspector_relation_handle_display("Parent", *entity.parent);
    inspector_relation_handle_display("First Child", *entity.first_child);
    inspector_relation_handle_display("Last Child", *entity.last_child);
    inspector_relation_handle_display("Prev Sib", *entity.prev_sibling);
    inspector_relation_handle_display("Next Sib", *entity.next_sibling);
}

debug_inspector_ui :: () {
    if is_action_buffered(.TOGGLE_INSPECTOR) {
        consume_action(.TOGGLE_INSPECTOR);
        if context.inspector_state.inspector_window.open {
            context.inspector_state.inspector_window.open = false;
        } else {
            context.inspector_state.inspector_window.open = true;
        }
    }

    current_time := to_float64_seconds(current_time_monotonic());
    w, h := get_render_dimensions(window);
    ui_per_frame_update(window, w, h, current_time);

    if context.inspector_state.inspector_window.open {
        add_subwindow(*context.inspector_state.inspector_window, *context.editor_state.editor_theme.subwindow_theme);
    }

    draw_popups();
}

inspector_vec2_display :: (field_name: string, ptr: *Vector2) #expand {
    label_rect := get_rect(`label_margin, `y_pos, 700, 25);
    label(label_rect, field_name, *`base_theme.label_theme);
    `y_pos -= 27;
    text := sprint("{% , %}", formatFloat(ptr.x, width = 1, trailing_width = 2, zero_removal = .NO), formatFloat(ptr.y, width = 1, trailing_width = 2, zero_removal = .NO));
    text_rect := get_rect(`label_margin + 20, `y_pos, 700, 25);
    label(text_rect, text, *`base_theme.label_theme);
    `y_pos -= 27;
}

inspector_relation_handle_display :: (handle_name: string, ptr: *Entity_Handle, loc := #caller_location) #expand {
    label_rect := get_rect(`label_margin, `y_pos, 90, 25);
    label(label_rect, handle_name, *`base_theme.label_theme);

    handle_display_rect: Rect;
    if entity_valid(ptr.*) {
        handle_display_rect := get_rect(`label_margin + 110, `y_pos, 60, 25);
        handle_button_text := sprint("[%|%]", ptr.*.index, ptr.*.generation);
        handle_pressed := button(handle_display_rect, handle_button_text, loc = loc);
        if handle_pressed {
            context.inspector_state.current_handle = ptr.*;
        }
    } else {
        handle_label_text := sprint("[NULL]");
        handle_display_rect := get_rect(`label_margin + 100, `y_pos, 60, 25);
        label(handle_display_rect, handle_label_text, *`base_theme.label_theme);
    }
    `y_pos -= 27;
}

inspector_entity_picking :: () {
    mouse_pos, ok := mouse_pointer_to_gameplay_pos();
    // print("Mouse Pos: {% , %}\n", mouse_pos.x, mouse_pos.y);
    if is_action_buffered(.EDITOR_LEFT_CLICK) {
        consume_action(.EDITOR_LEFT_CLICK);
        for *context.entities {
            if distance(mouse_pos, it.position) < TILE_SIZE {
                context.inspector_state.current_handle = it.handle;
                return;
            }
        }
    }
}
