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
    MAP_SCREEN_ROTATE;
    // Gameplay
    MOVE_LEFT;
    MOVE_RIGHT;
    MOVE_DOWN;
    MOVE_UP;
    // Debug
    GOTO_ROOM_DESIGNER;
    GOTO_MAP_PLACEMENT;
    GOTO_GAMEPLAY;
    BAKE_MAP;
}

init_input :: () {
    init_input_buffer();
    // Editor
    register_input(.EDITOR_LEFT_CLICK, .MOUSE_BUTTON_LEFT);
    register_input(.EDITOR_RIGHT_CLICK, .MOUSE_BUTTON_RIGHT);
    // Menu
    register_input(.MENU_UP, .ARROW_UP);
    register_input(.MENU_DOWN, .ARROW_DOWN);
    register_input(.MAP_SCREEN_ROTATE, #char "R");
    register_input(.CONFIRM, .ENTER);
    // Gameplay
    register_input(.MOVE_LEFT, #char "A");
    register_input(.MOVE_RIGHT, #char "D");
    register_input(.MOVE_UP, #char "W");
    register_input(.MOVE_DOWN, #char "S");
    // Debug
    register_input(.GOTO_ROOM_DESIGNER, #char "`");
    register_input(.GOTO_MAP_PLACEMENT, #char "9");
    register_input(.GOTO_GAMEPLAY, #char "0");
    register_input(.BAKE_MAP, #char "J");
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
}
