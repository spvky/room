mouse_left_down: bool;
mouse_right_down: bool;

process_input :: () {
    room_ptr := context.current_editor_room;
    for event: events_this_frame {
        if event.key_code == .ESCAPE && event.key_pressed {
            should_close = true;
            break;
        }

        if event.key_code == .MOUSE_BUTTON_LEFT {
            if event.key_pressed {
                mouse_left_down = true;
            } else {
                mouse_left_down = false;
            }
        }

        if event.key_code == .MOUSE_BUTTON_RIGHT {
            if event.key_pressed {
                mouse_right_down = true;
            } else {
                mouse_right_down = false;
            }
        }

        if event.key_code == xx #char "S" {
            parse_tiles(room_ptr);
            print("% Colliders added to %\n", room_ptr.collision_entities.count, room_ptr.name);
        }

        if event.key_code == xx #char "R" {
            rotate_colliders();
        }
    }
}
