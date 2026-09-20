EDITOR_MODES: [2]string: .["Collision", "Entities"];
COLLISION_TILE_TYPES: [5]string: .["Wall", "Top Half", "Bot Half", "Left Half", "Right Half"];
COLLISION_TILE_ICONS: [5]Ui_Icon;
ENTITY_TILE_TYPES: [4]string: .["Crate", "Player Spawn", "Gear", "Assembler"];
ENTITY_TILE_ICONS: [4]Ui_Icon;
TRIGGER_TYPES: [8]string: .["LEVER_0", "LEVER_1", "LEVER_3", "LEVER_3", "BUTTON_0", "BUTTON_1", "BUTTON_2", "BUTTON_3"];

Ui_Icon :: struct {
    sprite: Sprite;
    color: Vector4 = .{1, 1, 1, 1};
}

ROOM_VIEW :: 0;
MAP_VIEW :: 1;
GAME_VIEW :: 2;

Room :: struct {
    flags: Room_Flags;
    exits: Room_Exits;
    int_grid: [ROOM_WIDTH * ROOM_HEIGHT]Collision_Tile;
    entity_grid: [ROOM_WIDTH * ROOM_HEIGHT]Entity_Tile;
    rune: Rune;
    map_position: Coord;
    name: string;
    extra_data: [..]Extra_Entity_Data;
    texture: Texture;
}

Extra_Entity_Data :: struct {
    kind: Extra_Entity_Kind;
    switch_block_data: Switch_Block_Data;
    #overlay (switch_block_data) room_pickup_data: Room_Pickup_Data;
}

Extra_Entity_Kind :: enum {
    SWITCH_BLOCK;
    ROOM_PICKUP;
}

Trigger_Type :: enum {
    LEVER_0;
    LEVER_1;
    LEVER_2;
    LEVER_3;
    BUTTON_0;
    BUTTON_1;
    BUTTON_2;
    BUTTON_3;
}

rotate_trigger_type :: (a: Trigger_Type) -> Trigger_Type {
    out: Trigger_Type;
    if a == {
    case .LEVER_0;
        out = .LEVER_1;
    case .LEVER_1;
        out = .LEVER_2;
    case .LEVER_2;
        out = .LEVER_3;
    case .LEVER_3;
        out = .LEVER_0;
    case .BUTTON_0;
        out = .BUTTON_1;
    case .BUTTON_1;
        out = .BUTTON_2;
    case .BUTTON_2;
        out = .BUTTON_3;
    case .BUTTON_3;
        out = .BUTTON_0;
    }
    return out;
}

Switch_Block_Data :: struct {
    start: Coord = .{2, 16};
    width: s16;
    height: s16;
    active_start: Coord = .{100, 0};
    trigger_position: Coord = .{100, 0};
    trigger_type: Trigger_Type;
}

Room_Pickup_Data :: struct {
    position: Coord = .{2, 16};
    hash: u32;
}

Room_Exits :: enum_flags u16 {
    NORTH_EAST :: 1 << 0;
    NORTH :: 1 << 1;
    NORTH_WEST :: 1 << 2;
    WEST_NORTH :: 1 << 3;
    WEST :: 1 << 4;
    WEST_SOUTH :: 1 << 5;
    SOUTH_WEST :: 1 << 6;
    SOUTH :: 1 << 7;
    SOUTH_EAST :: 1 << 8;
    EAST_SOUTH :: 1 << 9;
    EAST :: 1 << 10;
    EAST_NORTH :: 1 << 11;
}

Room_Flags :: enum_flags u16 {
    DISCOVERED :: 1 << 0;
    STATIC :: 1 << 1;
    ENTERED_NORTH :: 1 << 2;
    ENTERED_SOUTH :: 1 << 3;
    ENTERED_EAST :: 1 << 4;
    ENTERED_WEST :: 1 << 5;
    NO_ROTATE :: 1 << 6;
    NO_MOVE_X :: 1 << 7;
    NO_MOVE_Y :: 1 << 8;
    NO_PICKUP :: 1 << 9;
    MUST_BE_PLACED :: 1 << 10;
    PICKED_UP :: 1 << 11;
}

Editor_State :: struct {
    editor_theme: Overall_Theme;
    editor_type: s32;
    collision_tile_type: s32;
    entity_tile_type: s32;
    show_file_load_window: bool;
    load_window_scroll_value: float32;
    kb_captured: bool;
    mouse_captured: bool;
    load_static_rooms: bool;
    selected_entity_idx: int;
    current_hash_idx: s32;
    editor_click_mode: Editor_Click_Mode;
    primary_window: Subwindow_Info = .{
                                       rect = #run get_rect(5, cast(float32)WINDOW_HEIGHT - 880, 350, 870),
                                       draw = draw_primary_window,
                                       title_text = "Editor"};

    file_load_window: Subwindow_Info = .{
                                         rect = #run get_rect((cast(float32)WINDOW_WIDTH / 2) - 400, cast(float32)WINDOW_HEIGHT - 800, 800, 600),
                                         open = false,
                                         draw = draw_file_load_window,
                                         title_text = "Load Room"};

    entity_editor_window: Subwindow_Info = .{
                                             rect = #run get_rect(cast(float32)WINDOW_WIDTH - 355, cast(float32)WINDOW_HEIGHT - 880, 350, 870),
                                             draw = draw_entity_editor_window,
                                             title_text = "Entity Editor"};
}

Editor_Click_Mode :: enum {
    NORMAL;
    SET_ENTITY_START_THEN_WIDTH;
    SET_ENTITY_START;
    SET_ENTITY_WIDTH;
    SET_ENTITY_ACTIVE_START;
    SET_ENTITY_TRIGGER;
    SET_ROOM_PICKUP_START;
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
    context.editor_state.editor_theme.label_theme.alignment = .Left;
    init_ui_icons();
}

init_ui_icons :: () {
    // Wall
    atlas := context.atlas;
    COLLISION_TILE_ICONS[0] = .{color = .{1, 1, 1, 1}};
    COLLISION_TILE_ICONS[1] = .{sprite = sprite_from_atlas(*atlas.tile_atlas, 2)};
    COLLISION_TILE_ICONS[2] = .{sprite = sprite_from_atlas(*atlas.tile_atlas, 3)};
    COLLISION_TILE_ICONS[3] = .{sprite = sprite_from_atlas(*atlas.tile_atlas, 4)};
    COLLISION_TILE_ICONS[4] = .{sprite = sprite_from_atlas(*atlas.tile_atlas, 5)};
    // Crate
    ENTITY_TILE_ICONS[0] = .{sprite = sprite_from_atlas(*atlas.tile_atlas, 0)};
    // Player Spawn
    ENTITY_TILE_ICONS[1] = .{color = .{0.6, 0.5, 0, 1}};
    // Gear
    ENTITY_TILE_ICONS[2] = .{sprite = sprite_from_atlas(*atlas.tile_atlas, 17)};
    // Assembler
    ENTITY_TILE_ICONS[3] = .{color = .{0.6, 0.9, 0.31, 1}};
}

render_room_designer_ui :: () {
    editor_state := context.editor_state;

    current_time := to_float64_seconds(current_time_monotonic());
    w, h := get_render_dimensions(window);
    editor_state.mouse_captured, editor_state.kb_captured = ui_per_frame_update(window, w, h, current_time);

    add_subwindow(*editor_state.primary_window, *editor_state.editor_theme.subwindow_theme);
    if editor_state.file_load_window.open add_subwindow(*editor_state.file_load_window, *editor_state.editor_theme.subwindow_theme);
    if editor_state.editor_type == 1 {
        add_subwindow(*editor_state.entity_editor_window, *editor_state.editor_theme.subwindow_theme);
    }
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

        if COLLISION_TILE_ICONS[tdi].sprite.texture {
            s := COLLISION_TILE_ICONS[tdi].sprite;
            set_shader_for_images(s.texture);
            immediate_quad(.{left, top}, .{left, bot}, .{right, bot}, .{right, top}, COLLISION_TILE_ICONS[tdi].color, s.uvs[0], s.uvs[1], s.uvs[2], s.uvs[3]);
        } else {
            set_shader_for_color();
            immediate_quad(.{left, top}, .{left, bot}, .{right, bot}, .{right, top}, COLLISION_TILE_ICONS[tdi].color);
        }
    case 1;
        tdi := context.editor_state.entity_tile_type;

        if ENTITY_TILE_ICONS[tdi].sprite.texture {
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
    if save_pressed then save_room(room_ptr.*);

    load_button_rect := get_rect(x_pos + 120, y_pos, 110, 30);
    load_pressed := button(load_button_rect, "Load Room");
    if load_pressed editor_state.file_load_window.open = true;

    y_pos -= 40;

    if context.current_editor_room.flags & .STATIC == .STATIC {
        map_position_display(x_pos + 350, x_pos + 650, y_pos + 600, y_pos + 300);
    }
}

draw_entity_editor_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    editor_state := context.editor_state;
    room_ptr := context.current_editor_room;
    y_pos := r.y + r.h - 50;
    x_pos := r.x + 5;

    for room_ptr.extra_data {
        entity_button_rect := get_rect(x_pos, y_pos, 150, 30);
        delete_entity_button_rect := get_rect(x_pos + 190, y_pos, 150, 30);
        if editor_state.selected_entity_idx == it_index {
            set_shader_for_color();
            immediate_quad(
                           .{x_pos + 155, y_pos + 20},
                           .{x_pos + 155, y_pos + 10},
                           .{x_pos + 185, y_pos + 10},
                           .{x_pos + 185, y_pos + 20},
                           .{1, 0, 0, 1});
        }
        button_text := tprint("%", it.kind);
        entity_selected := button(entity_button_rect, button_text, identifier = it_index);
        entity_deleted := button(delete_entity_button_rect, "Delete", identifier = it_index * 50);
        if entity_selected {
            editor_state.selected_entity_idx = it_index;
        }
        if entity_deleted {
            array_ordered_remove_by_index(*room_ptr.extra_data, it_index);
        }
        y_pos -= 35;
    }

    create_block_button_rect := get_rect(x_pos + 100, y_pos, 100, 30);
    create_pickup_button_rect := get_rect(x_pos + 205, y_pos, 100, 30);
    create_block_pressed := button(create_block_button_rect, "Block");
    create_pickup_pressed := button(create_pickup_button_rect, "Pickup");
    if create_block_pressed {
        array_add(*room_ptr.extra_data, .{kind = .SWITCH_BLOCK});
        editor_state.selected_entity_idx = room_ptr.extra_data.count - 1;
    }
    if create_pickup_pressed {
        array_add(*room_ptr.extra_data, .{kind = .ROOM_PICKUP});
        editor_state.selected_entity_idx = room_ptr.extra_data.count - 1;
    }
    y_pos -= 35;
    // But the actual box for editing here
    if room_ptr.extra_data.count > 0 {
        data_ptr := *room_ptr.extra_data[editor_state.selected_entity_idx];

        if data_ptr.kind == {
        case .SWITCH_BLOCK;
            using data_ptr.switch_block_data;
            start_label_rect := get_rect(x_pos, y_pos, 300, 30);
            label(start_label_rect, "Start", *editor_state.editor_theme.label_theme);
            y_pos -= 32;
            start_rect := get_rect(x_pos + 10, y_pos, 70, 30);
            start_string := tprint("%,%", start.x, start.y);
            label(start_rect, start_string, *editor_state.editor_theme.label_theme);

            set_both_rect := get_rect(x_pos + 95, y_pos, 60, 30);
            set_both_pressed := button(set_both_rect, "Both");
            if set_both_pressed {
                editor_state.editor_click_mode = .SET_ENTITY_START_THEN_WIDTH;
            }

            set_start_rect := get_rect(x_pos + 160, y_pos, 60, 30);
            set_start_pressed := button(set_start_rect, "Start");
            if set_start_pressed {
                editor_state.editor_click_mode = .SET_ENTITY_START;
            }

            set_width_rect := get_rect(x_pos + 225, y_pos, 60, 30);
            set_width_pressed := button(set_width_rect, "Width");
            if set_width_pressed {
                editor_state.editor_click_mode = .SET_ENTITY_WIDTH;
            }
            y_pos -= 32;

            width_height_label_rect := get_rect(x_pos, y_pos, 300, 30);
            label(width_height_label_rect, "Width, Height", *editor_state.editor_theme.label_theme);
            y_pos -= 32;
            width_height_rect := get_rect(x_pos + 10, y_pos, 200, 30);
            width_height_string := tprint("%,%", width, height);
            label(width_height_rect, width_height_string, *editor_state.editor_theme.label_theme);
            y_pos -= 32;

            active_start_label_rect := get_rect(x_pos, y_pos, 300, 30);
            label(active_start_label_rect, "Active Start", *editor_state.editor_theme.label_theme);
            y_pos -= 32;
            active_start_rect := get_rect(x_pos + 10, y_pos, 70, 30);
            active_start_string := tprint("%,%", active_start.x, active_start.y);
            label(active_start_rect, active_start_string, *editor_state.editor_theme.label_theme);

            set_active_rect := get_rect(x_pos + 95, y_pos, 70, 30);
            set_active_pressed := button(set_active_rect, "Set");
            if set_active_pressed {
                editor_state.editor_click_mode = .SET_ENTITY_ACTIVE_START;
            }
            y_pos -= 32;

            trigger_type_label_rect := get_rect(x_pos, y_pos, 150, 30);
            label(trigger_type_label_rect, "Trigger Type", *editor_state.editor_theme.label_theme);
            trigger_type_dropdown_rect := get_rect(x_pos + 160, y_pos, 150, 30);
            dropdown(trigger_type_dropdown_rect, TRIGGER_TYPES, cast(*s32)*data_ptr.switch_block_data.trigger_type);
            y_pos -= 32;

            trigger_label_rect := get_rect(x_pos, y_pos, 300, 30);
            label(trigger_label_rect, "Trigger Position", *editor_state.editor_theme.label_theme);
            y_pos -= 32;
            trigger_rect := get_rect(x_pos + 10, y_pos, 70, 30);
            trigger_string := tprint("%,%", trigger_position.x, trigger_position.y);
            label(trigger_rect, trigger_string, *editor_state.editor_theme.label_theme);

            set_trigger_rect := get_rect(x_pos + 95, y_pos, 70, 30);
            set_trigger_pressed := button(set_trigger_rect, "Set");
            if set_trigger_pressed {
                editor_state.editor_click_mode = .SET_ENTITY_TRIGGER;
            }
            y_pos -= 32;
        case .ROOM_PICKUP;
            using data_ptr.room_pickup_data;
            position_label_rect := get_rect(x_pos, y_pos, 300, 30);
            label(position_label_rect, "Position", *editor_state.editor_theme.label_theme);
            y_pos -= 32;
            position_rect := get_rect(x_pos + 10, y_pos, 70, 30);
            position_string := tprint("%,%", position.x, position.y);
            label(position_rect, position_string, *editor_state.editor_theme.label_theme);

            set_position_rect := get_rect(x_pos + 90, y_pos, 90, 30);
            set_position_pressed := button(set_position_rect, "Position");
            if set_position_pressed {
                editor_state.editor_click_mode = .SET_ENTITY_START;
            }
            y_pos -= 32;

            room_label_rect := get_rect(x_pos, y_pos, 300, 30);
            label(room_label_rect, "Room", *editor_state.editor_theme.label_theme);
            y_pos -= 32;

            room_name_string: string;

            pickup_room_ptr := table_find_pointer(context.room_table, hash);
            if pickup_room_ptr {
                room_name_string = tprint("%", pickup_room_ptr.name);
            } else {
                room_name_string = "NULL";
            }

            room_name_rect := get_rect(x_pos + 10, y_pos, 70, 30);
            label(room_name_rect, room_name_string, *editor_state.editor_theme.label_theme);

            room_dropdown_rect := get_rect(x_pos + 85, y_pos, 200, 30);
            hash_idx: s32;
            rooms := build_rooms_array();
            y_pos -= 32;

            for rooms {
                rect := get_rect(x_pos + 10, y_pos, 300, 30);
                pressed := button(rect, it.name, identifier = it_index);
                if pressed {
                    data_ptr.room_pickup_data.hash = djb2_hash(it.name);
                }

                y_pos -= 32;
            }
        }
    }
}

build_rooms_array :: () -> [..]*Room {
    rooms: [..]*Room;
    rooms.allocator = temp;

    for *context.room_table {
        if it.flags & .STATIC != .STATIC {
            array_add(*rooms, it);
        }
    }
    return rooms;
}

paint_tile_values :: () {
    room_ptr := context.current_editor_room;
    if !context.editor_state.mouse_captured {
        cell, ok := get_mouse_cell();
        if context.editor_state.editor_type == {
        case 0;
            if is_action_held(.EDITOR_LEFT_CLICK) {
                value_to_paint: Collision_Tile = xx (context.editor_state.collision_tile_type + 1);
                if ok {
                    set_collision_tile_value(room_ptr, value_to_paint, cell);
                }
            }
        case 1;
            if context.editor_state.editor_click_mode == {
            case .NORMAL;
                if is_action_buffered(.EDITOR_LEFT_CLICK) {
                    value_to_paint: Entity_Tile = xx (context.editor_state.entity_tile_type + 1);
                    if ok {
                        consume_action(.EDITOR_LEFT_CLICK);
                        set_entity_tile_value(room_ptr, value_to_paint, cell);
                    }
                }
            case .SET_ENTITY_START_THEN_WIDTH;
                if ok {
                    room_ptr.extra_data[context.editor_state.selected_entity_idx].switch_block_data.start = cell;
                    if is_action_buffered(.EDITOR_LEFT_CLICK) {
                        consume_action(.EDITOR_LEFT_CLICK);
                        context.editor_state.editor_click_mode = .SET_ENTITY_WIDTH;
                    }
                }
            case .SET_ENTITY_START;
                if ok {
                    room_ptr.extra_data[context.editor_state.selected_entity_idx].switch_block_data.start = cell;
                    if is_action_buffered(.EDITOR_LEFT_CLICK) {
                        consume_action(.EDITOR_LEFT_CLICK);
                        context.editor_state.editor_click_mode = .NORMAL;
                    }
                }

            case .SET_ENTITY_WIDTH;
                if ok {
                    start := room_ptr.extra_data[context.editor_state.selected_entity_idx].switch_block_data.start;
                    if cell.x >= start.x && cell.y >= start.y {
                        width := (cell.x - start.x) + 1;
                        height := (cell.y - start.y) + 1;
                        room_ptr.extra_data[context.editor_state.selected_entity_idx].switch_block_data.width = width;
                        room_ptr.extra_data[context.editor_state.selected_entity_idx].switch_block_data.height = height;
                        if is_action_buffered(.EDITOR_LEFT_CLICK) {
                            consume_action(.EDITOR_LEFT_CLICK);
                            context.editor_state.editor_click_mode = .NORMAL;
                        }
                    }
                }
            case .SET_ENTITY_ACTIVE_START;
                if ok {
                    room_ptr.extra_data[context.editor_state.selected_entity_idx].switch_block_data.active_start = cell;
                    if is_action_buffered(.EDITOR_LEFT_CLICK) {
                        consume_action(.EDITOR_LEFT_CLICK);
                        context.editor_state.editor_click_mode = .NORMAL;
                    }
                }
            case .SET_ENTITY_TRIGGER;
                if ok {
                    room_ptr.extra_data[context.editor_state.selected_entity_idx].switch_block_data.trigger_position = cell;
                    if is_action_buffered(.EDITOR_LEFT_CLICK) {
                        consume_action(.EDITOR_LEFT_CLICK);
                        context.editor_state.editor_click_mode = .NORMAL;
                    }
                }
            case .SET_ROOM_PICKUP_START;
                if ok {
                    room_ptr.extra_data[context.editor_state.selected_entity_idx].room_pickup_data.position = cell;
                    if is_action_buffered(.EDITOR_LEFT_CLICK) {
                        consume_action(.EDITOR_LEFT_CLICK);
                        context.editor_state.editor_click_mode = .NORMAL;
                    }
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

map_position_display :: (left: float32, right: float32, top: float32, bot: float32) {
    display_width: float32 = right - left;
    total_margin_width := display_width * 0.1;
    total_tile_width := display_width * 0.9;
    margin_width := total_margin_width * 0.1;
    tile_width := total_tile_width * 0.1;

    display_height: float32 = top - bot;
    total_margin_height := display_height * 0.1;
    total_tile_height := display_height * 0.9;
    margin_height := total_margin_height * 0.1;
    tile_height := total_tile_height * 0.1;

    // immediate_quad(.{left, bot}, .{right, bot}, .{right, top}, .{left, top}, .{0.2, 0, 0.2, 1});

    for y: 0..MAP_HEIGHT - 1 {
        for x: 0..MAP_WIDTH - 1 {
            c := Coord.{xx x, xx y};

            min := Vector2.{
                            left + (xx x * (margin_width + tile_width)),
                            bot + (xx y * (margin_height + tile_height))};

            max := min + .{tile_width, tile_height};

            color := ifx context.current_editor_room.map_position == c then Vector4.{0, 0.4, 0.15, 1} else Vector4.{1, 1, 1, 1};

            immediate_quad(min, Vector2.{max.x, min.y}, max, Vector2.{min.x, max.y}, color);

            raw_x, raw_y, ok := get_mouse_pointer_position();
            raw_y = WINDOW_HEIGHT - raw_y;

            if ok {
                mouse_x := cast(float32)raw_x;
                mouse_y := cast(float32)raw_y;

                if mouse_x > min.x && mouse_x < max.x && mouse_y > min.y && mouse_y < max.y {
                    if is_action_buffered(.EDITOR_LEFT_CLICK) && context.editor_state.mouse_captured {
                        consume_action(.EDITOR_LEFT_CLICK);
                        context.current_editor_room.map_position = c;
                    }
                }
            }
        }
    }
}

modify_string :: (ps: *string, new_value: string) {
    free(ps.*);
    ps.* = copy_string(new_value);
}

/* What would a perfect room designer look like?

 1. Use tilemap for walls
 2. Vector2 for everything else
 3. Use per room handle collections, and then dump everything into the main collection on hydrate


*/

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
