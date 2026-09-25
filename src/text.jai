Display_Message :: enum u8 {
    NONE;
    ASSEMBLER;
    SWITCH;
    ROOM_PICKUP;
}

string_from_message :: (msg: Display_Message) -> string {
    out: string;
    if msg == {
    case .ASSEMBLER; out = "E - re-Assemble mAp";
    case .SWITCH; out = "E - Flip";
    case .ROOM_PICKUP; out = "E - tAke room";
    case .NONE; out = "";
    }
    return out;
}

manage_floating_text :: (delta: float32) {
    player := player_get();
    for *context.entities {
        if !entity_has_props(it, .TEXT_DISPLAY) continue;
        if distance(player.position, it.position) < TILE_SIZE {
            it.flags |= .TEXT_ACTIVE;
        } else {
            it.flags &= ~.TEXT_ACTIVE;
        }
    }
}

render_floating_text :: () {
    for *context.entities {
        if !entity_has_props(it, .TEXT_DISPLAY) || !entity_has_flags(it, .TEXT_ACTIVE) continue;
        screen_x, screen_y, ok := gameplay_pos_to_screen_position(it.position);
        if !ok continue;
        screen_y += 80;
        screen_x -= 30;
        if screen_x > 1750 screen_x = 1750;
        if it.tag == .ROOM_PICKUP {
            room_ptr := table_find_pointer(context.room_table, it.room_pickup_hash);
            has_been_picked_up := room_ptr.flags & .PICKED_UP == .PICKED_UP;
            if !has_been_picked_up {
                draw_text(context.atlas.font, screen_x, screen_y, string_from_message(it.text_message));
            }
        } else {
            draw_text(context.atlas.font, screen_x, screen_y, string_from_message(it.text_message));
        }
    }
}
