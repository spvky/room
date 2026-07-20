mouse_left_down: bool;
mouse_right_down: bool;

Action :: enum {
    // Editor
    EDITOR_LEFT_CLICK;
    EDITOR_RIGHT_CLICK;
    // Menus
    CONFIRM;
    CANCEL;
    MENU_LEFT;
    MENU_RIGHT;
    MENU_UP;
    MENU_DOWN;
    // Gameplay
    MOVE_LEFT;
    MOVE_RIGHT;
    MOVE_DOWN;
    MOVE_UP;
}

init_input :: () {
    init_input_buffer();
    register_input(.EDITOR_LEFT_CLICK, .MOUSE_BUTTON_LEFT);
    register_input(.EDITOR_RIGHT_CLICK, .MOUSE_BUTTON_RIGHT);
    register_input(.MENU_UP, .ARROW_UP);
    register_input(.MENU_DOWN, .ARROW_DOWN);
}

process_input :: (delta: float32) {
    update_buffer(delta);

    // Debug escape, this will eventually not do that
    for event: events_this_frame {
        if event.key_code == .ESCAPE && event.key_pressed {
            should_close = true;
            break;
        }
    }
    // /////////////////////////////////////////////////
    room_ptr := context.current_editor_room;

    if is_action_buffered(.MENU_UP) {
        consume_action(.MENU_UP);
        prev_map_selected_idx();
    }

    if is_action_buffered(.MENU_DOWN) {
        consume_action(.MENU_DOWN);
        next_map_selected_idx();
    }
}
