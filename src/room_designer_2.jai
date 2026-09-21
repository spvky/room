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

New_Editor_State :: struct {
    editor_click_mode: New_Editor_Click_Mode;
    vec_setting_ptr: *Vector2;
    handle_setting_ptr: *Entity_Handle;
    entity_to_make: Entity_Tag;
    current_entity: Entity_Handle;
    entity_window: Subwindow_Info = .{
                                      rect = #run get_rect(cast(float)WINDOW_WIDTH - 355, cast(float)WINDOW_HEIGHT - 880, 350, 870),
                                      draw = draw_entity_window,
                                      title_text = "Entity"};
}

New_Editor_Click_Mode :: enum u8 {
    VECTOR_SET;
    HANDLE_SET;
    MAKE_ENTITY;
}

#add_context new_editor_state: New_Editor_State;

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
                context.new_editor_state.editor_click_mode = .HANDLE_SET;
                context.new_editor_state.handle_setting_ptr = field_ptr;
            }
        }
        if follow_handle && entitiy_valid(field_ptr.*) {
            button_rect := get_rect(`x + 240, `y, 80, 30);
            button_text := tprint("Goto %", field_name);
            should_goto_handle := button(button_rect, button_text);
            if should_goto_handle {
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
                context.new_editor_state.editor_click_mode = .VECTOR_SET;
                context.new_editor_state.vec_setting_ptr = field_ptr;
            }
        }
        `y -= 35;
    }
}

draw_entity_window :: (state: *Subwindow_State, r: Rect, data: *void) {
}
