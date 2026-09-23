// Rewriting the room designer for several reasons
/*
1. Remove inconsistencies that come from storing entities in a grid (most notably moving blocks atm)
2. Generally make the room designer easier to work with, it's a little hacky and painful to design rooms with currently
3. Remove the friction of translating entities between 2 different types
4. Design around the ability to play a room and test it while building it
5. Genrally make serialization simpler
6. Once different rune effects are implemented I imagine it will be more

Things to consider:
1. Size of data will most likely be slightly larger, but seeing as how the current build is with assets is 1MB compressed, that's probably fine
*/

/*
	9/22/2026 6:09:38 PM
	Left Todo
	1. Wall creation
	2. Room Pickups
	3. Add Gear arrows and rotation
	3b. Test room IO
	4. Adding Rooms to world
	5. Fix Room PNG's
	6. Different Map Screens

	. Playing Room
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

Mouse_Capture :: struct {
    building_wall: bool;
    wall_start: Coord;
}

// Use local tile size for the editor to make translating positions easier on hydration
Room_Editor_State :: struct {
    theme: Overall_Theme;
    current_room: *Room_V2;
    editor_click_mode: Room_Editor_Click_Mode;
    entity_to_make: Entity_Tag;
    wall_to_make: Collision_Tile;
    current_entity_handle: Entity_Handle;
    current_mouse_coord: Coord;
    wall_start_coord: Coord;
    collection_window_scroll_value: float32;
    mouse_captured: bool;
    kb_captured: bool;
    core_window: Subwindow_Info = .{
                                    rect = #run get_rect(5, cast(float32)WINDOW_HEIGHT - 750, 350, 740),
                                    draw = draw_core_room_window,
                                    title_text = "Room"};
    entity_window: Subwindow_Info = .{
                                      rect = #run get_rect(cast(float)WINDOW_WIDTH - 355, cast(float32)WINDOW_HEIGHT - 750, 350, 740),
                                      draw = draw_entity_window,
                                      title_text = "Entity"};

    actions_window: Subwindow_Info = .{
                                       rect = #run get_rect(5, 20, 350, 300),
                                       draw = draw_actions_window,
                                       title_text = "Actions"};

    collection_window: Subwindow_Info = .{
                                          rect = #run get_rect(cast(float)WINDOW_WIDTH - 355, 20, 350, 300),
                                          draw = draw_collection_window,
                                          title_text = "Collection"};

    load_window: Subwindow_Info = .{
                                    rect = #run get_rect((cast(float32)WINDOW_WIDTH / 2) - 400, cast(float32)WINDOW_HEIGHT - 800, 800, 600),
                                    open = false,
                                    draw = draw_load_window,
                                    title_text = "Load"};
}

Room_Editor_Click_Mode :: enum u8 {
    SELECT;
    SET_WALL_START;
    SET_WALL_END;
    VECTOR_SET;
    HANDLE_SET_CHILD;
    HANDLE_SET_SIB;
    HANDLE_SET_PARENT;
    MAKE_ENTITY;
}

#add_context room_editor_state: *Room_Editor_State;

init_room_editor :: () {
    if !context.room_editor_state {
        context.room_editor_state = New(Room_Editor_State);
        context.room_editor_state.current_room = New(Room_V2);

        context.room_editor_state.current_room.* = load_room_v2("a.room");
        set_atlas_for_entity_manager(*context.room_editor_state.current_room.entities);

        proc := default_theme_procs[0];
        context.room_editor_state.theme = proc();
        set_default_theme(context.room_editor_state.theme);
        context.room_editor_state.theme.label_theme.alignment = .Left;
    }
}

render_room_editor_ui :: () {
    editor_state := context.room_editor_state;

    current_time := to_float64_seconds(current_time_monotonic());
    w, h := get_render_dimensions(window);
    editor_state.mouse_captured, editor_state.kb_captured = ui_per_frame_update(window, w, h, current_time);

    add_subwindow(*editor_state.core_window, *editor_state.theme.subwindow_theme);
    add_subwindow(*editor_state.entity_window, *editor_state.theme.subwindow_theme);
    add_subwindow(*editor_state.actions_window, *editor_state.theme.subwindow_theme);
    add_subwindow(*editor_state.collection_window, *editor_state.theme.subwindow_theme);
    if editor_state.load_window.open add_subwindow(*editor_state.load_window, *editor_state.theme.subwindow_theme);
    draw_popups();
}

room_editor_update :: () {
    mouse_movement();
    click_actions();
}

mouse_movement :: () {
    cell, ok := get_mouse_editor_cell();
    if ok {
        state := context.room_editor_state;
        state.current_mouse_coord = cell;
        if state.editor_click_mode == .SET_WALL_END {
            c := state.current_mouse_coord;
            if state.wall_to_make == .TOP_HALF || state.wall_to_make == .BOT_HALF c.y = state.wall_start_coord.y;
            if state.wall_to_make == .LEFT_HALF || state.wall_to_make == .RIGHT_HALF c.x = state.wall_start_coord.x;
            state.current_room.int_grid[coord_to_index(c)] = state.wall_to_make;
        }
    }
}

click_actions :: () {
    editor_state := context.room_editor_state;
    entities := *editor_state.current_room.entities;
    handle := editor_state.current_entity_handle;
    c := editor_state.current_mouse_coord;
    if is_action_buffered(.EDITOR_LEFT_CLICK) {
        consume_action(.EDITOR_LEFT_CLICK);
        if editor_state.editor_click_mode == {
        case .SELECT;
        case .SET_WALL_START;
            editor_state.current_room.int_grid[coord_to_index(c)] = editor_state.wall_to_make;
            editor_state.wall_start_coord = c;
            editor_state.editor_click_mode = .SET_WALL_END;
        case .SET_WALL_END;
            editor_state.editor_click_mode = .SELECT;
        case .HANDLE_SET_CHILD;
            for entities {
                if c == it.relative_room_coord && entity_valid(handle, e = entities) {
                    entity := entity_get(handle, e = entities);
                    if entity_valid(entity.last_child, e = entities) {
                        last_child := entity_get(entity.last_child, e = entities);
                        last_child.next_sibling = it.handle;
                        it.prev_sibling = last_child.handle;
                    } else if entity_valid(entity.first_child, e = entities) {
                        first_child := entity_get(entity.first_child, e = entities);
                        first_child.next_sibling = it.handle;
                        it.prev_sibling = first_child.handle;
                    } else {
                        entity.first_child = it.handle;
                        entity.last_child = it.handle;
                    }
                    it.parent = handle;
                    entity.last_child = it.handle;

                    editor_state.editor_click_mode = .SELECT;
                }
            }
        case .HANDLE_SET_PARENT;
            for entities {
                if c == it.relative_room_coord && entity_valid(handle, e = entities) {
                    entity := entity_get(handle, e = entities);
                    if entity_valid(it.last_child, e = entities) {
                        last_child := entity_get(it.last_child, e = entities);
                        last_child.next_sibling = handle;
                        entity.prev_sibling = last_child.handle;
                    } else if entity_valid(it.first_child, e = entities) {
                        first_child := entity_get(it.first_child, e = entities);
                        first_child.next_sibling = handle;
                        entity.prev_sibling = first_child.handle;
                    } else {
                        it.first_child = handle;
                        it.last_child = handle;
                    }
                    entity.parent = it.handle;

                    editor_state.editor_click_mode = .SELECT;
                }
            }

            editor_state.editor_click_mode = .SELECT;
        case .HANDLE_SET_SIB;
            // Don't think this is ever necessary
            editor_state.editor_click_mode = .SELECT;
        case .VECTOR_SET;
            if entity_valid(handle, e = entities) {
                entity := entity_get(handle, e = entities);
                entity.relative_room_coord = c;
                entity.position = true_vec_from_coord(c);
            }
            editor_state.editor_click_mode = .SELECT;
        case .MAKE_ENTITY;
            tag := editor_state.entity_to_make;
            make_entity_in_room_editor(entities, c, tag);
            editor_state.editor_click_mode = .SELECT;
        }
    }

    if is_action_held(.EDITOR_RIGHT_CLICK) {
        cell, ok := get_mouse_editor_cell();
        if ok {
            context.room_editor_state.current_room.int_grid[(coord_to_index(c))] = .EMPTY;
        }
    }
}

// NOTE: When hydrating entities, all of their sprite/atlas pointers will need to be refetched as they will be invalid
make_entity_in_room_editor :: (entities: *Entity_Manager, c: Coord, tag: Entity_Tag) #expand {
    entity: Entity;
    entity.tag = tag;
    entity.relative_room_coord = c;
    entity.position = true_vec_from_coord(c);

    print("Making Entity In Room Editor:\nTag: %\nCoord: %\nPos: %\n", tag, c, entity.position);

    // Tag Specific fields
    if tag == {
    case .CRATE;
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{TILE_SIZE, TILE_SIZE};
        entity.props = .RENDERABLE | .SOLID | .GRAVITY_AFFECTED | .DYNAMIC | .PRESSES_BUTTONS;
        entity.render_kind = .SPRITE;
        entity.sprite = sprite(0);
        entity.render_extents = Vector2.{TILE_SIZE, TILE_SIZE};

        crate_handle := entity_add(entity, e = entities);

        // Ground Sensor Entity
        gse: Entity;
        gse.offset = Vector2.{0, -TILE_SIZE / 2};
        gse.extents = Vector2.{TILE_SIZE * 0.98, TILE_SIZE / 8};
        gse.shape_kind = .RECTANGLE;
        gse.tag = .GROUND_SENSOR;
        gse.props = .SENSOR | .RELATIVE_POSITION | .RELATIVE_ROTATION;
        entity_add_child(crate_handle, gse, e = entities);

        // Right Sensor
        rse: Entity;
        rse.offset = Vector2.{TILE_SIZE / 2, 0};
        rse.extents = Vector2.{TILE_SIZE / 7.5, TILE_SIZE * 0.95};
        rse.shape_kind = .RECTANGLE;
        rse.tag = .RIGHT_SENSOR;
        rse.props = .SENSOR | .RELATIVE_POSITION | .RELATIVE_ROTATION;
        entity_add_child(crate_handle, rse, e = entities);
    case .GEAR;
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{TILE_SIZE, TILE_SIZE};
        entity.tag = .GEAR;
        entity.props = .RENDERABLE | .ANIMATED | .SOLID | .STATIC | .DEATH_ZONE | .UNSTABLE;
        entity.render_kind = .ANIMATION_PLAYER;
        entity.render_extents = Vector2.{TILE_SIZE, TILE_SIZE};
        entity.animation_player = Sprite_Animation_Player.{
                                                           atlas = *context.atlas.tile_atlas,
                                                           seconds_per_frame = 0.015,
                                                           start = 17,
                                                           idx = 17,
                                                           length = 1};
        entity_add(entity, e = entities);
    case .ASSEMBLER;
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{TILE_SIZE, TILE_SIZE};
        entity.tag = .ASSEMBLER;
        entity.text_message = .ASSEMBLER;
        entity.props = .RENDERABLE | .INTERACTABLE | .TEXT_DISPLAY;
        entity.flags = .POWERED;
        entity.render_kind = .SPRITE_SHEET;
        entity.sprite_sheet = sprite_sheet(10, 2);
        entity.render_extents = Vector2.{TILE_SIZE, TILE_SIZE};
        entity_add(entity, e = entities);
    case .LEVER;
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{TILE_SIZE * 0.75, TILE_SIZE * 0.75};
        entity.text_message = .SWITCH;
        entity.render_kind = .SPRITE_SHEET;
        entity.sprite_sheet = sprite_sheet(8, 2);
        entity.render_extents = Vector2.{TILE_SIZE, TILE_SIZE};
        entity.props = .RENDERABLE | .INTERACTABLE | .FOREGROUND | .CONDUIT | .TEXT_DISPLAY;
        entity_add(entity, e = entities);
    case .BUTTON;
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{TILE_SIZE * 0.75, TILE_SIZE * 0.75};
        entity.text_message = .SWITCH;
        entity.render_kind = .SPRITE_SHEET;
        entity.sprite_sheet = sprite_sheet(12, 2);
        entity.render_extents = Vector2.{TILE_SIZE, TILE_SIZE};
        entity.props = .RENDERABLE | .CONDUIT | .SENSOR | .FOREGROUND;
        entity_add(entity, e = entities);
    case .SWITCH_BLOCK;
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{TILE_SIZE, TILE_SIZE};
        entity.render_kind = .SPRITE;
        entity.sprite = sprite(7);
        entity.render_extents = Vector2.{TILE_SIZE, TILE_SIZE};
        entity.props = .RENDERABLE | .DYNAMIC | .SOLID | .KINEMATIC | .UNSTABLE | .PRESSES_BUTTONS;
        block_handle := entity_add(entity, e = entities);
        on_position_entity: Entity;
        on_position_entity.position = entity.position;
        on_position_entity.tag = .SWITCH_BLOCK_ON_TARGET;
        entity_add_child(block_handle, on_position_entity, e = entities);
    }
}

draw_core_room_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    editor_state := context.room_editor_state;
    room_ptr := editor_state.current_room;
    rune_ptr := *room_ptr.rune;
    x := r.x;
    y := r.y + r.h - 60;
    theme := context.room_editor_state.theme;

    // // Name
    name_rect := get_rect(x + 20, y, 300, 37);
    name_action, new_name := text_input(name_rect, context.room_editor_state.current_room.name, *theme.text_input_theme);
    if name_action & .ENTERED || name_action & .TEXT_MODIFIED modify_string(*context.room_editor_state.current_room.name, new_name);
    y -= 40;

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
    su_rect := get_rect(marking_x, y, 50, 30);
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
    flags_margin := x + 20;
    flag_label_rect := get_rect(x, y + 30, 300, 30);
    label(flag_label_rect, "Flags", *theme.label_theme);
    enum_flag_display(*room_ptr.flags, flags_margin, y);

    // Exits
    exit_label_rect := get_rect(x + 170, y + 30, 300, 30);
    label(exit_label_rect, "Exits", *theme.label_theme);
    enum_flag_display(*room_ptr.exits, x + 180, y);

    y -= 370;
    save_button_rect := get_rect(x + 10, y, 110, 30);
    save_pressed := button(save_button_rect, "Save Room");
    if save_pressed {
        // then save_room(room_ptr.*) // Need a new save room function
    }

    load_button_rect := get_rect(x + 130, y, 110, 30);
    load_pressed := button(load_button_rect, "Load Room");
    if load_pressed editor_state.load_window.open = true;

    y -= 40;

    if room_ptr.flags & .STATIC == .STATIC {
        map_position_display(x + 350, x + 650, y + 600, y + 300);
    }
}

draw_entity_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    editor_state := context.room_editor_state;
    room := editor_state.current_room;
    if entity_valid(editor_state.current_entity_handle, *room.entities) {
        entity := entity_get(editor_state.current_entity_handle, *room.entities);
        x := r.x;
        y := r.y + r.h - 40;
        tag_rect := get_rect(x, y, 350, 40);
        tag_string := tprint("%", entity.tag);
        label(tag_rect, tag_string, *context.room_editor_state.theme.label_theme);
        y -= 45;
        vec_field("Position", *entity.position);
        rotation_field(*entity.rotation);
        extents_display("Extents", entity);
        handle_field("Handle", *entity.handle, .NONE, false, false);
        handle_field("Parent", *entity.parent, .PARENT);
        handle_field("F Child", *entity.first_child, .CHILD);
        handle_field("L Child", *entity.last_child, .CHILD);
        handle_field("P Sib", *entity.prev_sibling, .SIB);
        handle_field("N Sib", *entity.next_sibling, .SIB);

        props_rect := get_rect(x, y, 100, 30);
        exits_rect := get_rect(x + 170, y, 100, 30);
        y -= 32;

        label(props_rect, "Props", *context.room_editor_state.theme.label_theme);
        enum_flag_display(*entity.props, x + 15, y);

        label(exits_rect, "Flags", *context.room_editor_state.theme.label_theme);
        flags_y_offset := enum_flag_display(*entity.flags, x + 185, y);
    }
}

draw_collection_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    collection_scroll_rect := get_rect(r.x + 10, r.y + 10, r.w - 20, r.h - 20);
    scroll_region, inside := begin_scrollable_region(collection_scroll_rect, *context.room_editor_state.theme.scrollable_region_theme);
    s := inside;
    x := s.x;
    // y := s.y + s.h - 50;
    s.y += context.room_editor_state.collection_window_scroll_value;
    // print("Main: %\nRoom: %\n", context.entities.count, context.room_editor_state.current_room.entities.count);
    for *context.room_editor_state.current_room.entities {
        draw_collection_entity_entry(it, it_index);
    }
    end_scrollable_region(scroll_region, s.x + s.w, s.y, *context.room_editor_state.collection_window_scroll_value);
}

draw_actions_window :: (state: *Subwindow_State, r: Rect, data: *void) {
    editor_state := context.room_editor_state;
    room_ptr := editor_state.current_room;
    x := r.x;
    y := r.y + r.h - 40;
    create_entity_action_button(.CRATE, shift_y = false);
    create_entity_action_button(.GEAR, x + 170);
    create_entity_action_button(.LEVER, shift_y = false);
    create_entity_action_button(.BUTTON, x + 170);
    create_entity_action_button(.SWITCH_BLOCK, shift_y = false);
    y -= 32;
    create_wall_action_button(.WALL, x + 170);
    create_wall_action_button(.TOP_HALF, shift_y = false);
    create_wall_action_button(.BOT_HALF, x + 170);
    create_wall_action_button(.RIGHT_HALF, shift_y = false);
    create_wall_action_button(.LEFT_HALF, x + 170);

    // Pin save button to the bottom of the window
    save_button_rect := get_rect(r.x + (r.w / 2) - 100, r.y + 2, 200, 40);
    save_pressed := button(save_button_rect, "Save Room");
    if save_pressed {
        save_room_v2(editor_state.current_room.*);
    }
}

draw_collection_entity_entry :: (entity: *Entity, identifier: int, loc := #caller_location) #expand {
    x := `x;
    if entity.parent.index != 0 {
        x += 20;
    }
    label_rect := get_rect(x, `s.y + 200, 180, 30);
    label_string := tprint("%", entity.tag);
    label(label_rect, label_string, *context.room_editor_state.theme.label_theme);
    button_rect := get_rect(x + 185, `s.y + 200, 30, 30);
    should_select := button(button_rect, "-", identifier = identifier, loc = loc);
    if should_select {
        context.room_editor_state.current_entity_handle = entity.handle;
    }
    if entity.handle == context.room_editor_state.current_entity_handle {
        set_shader_for_color();
        p: [4]Vector2;
        p[0] = .{x + 190, `s.y + 225};
        p[1] = .{x + 190, `s.y + 205};
        p[2] = .{x + 210, `s.y + 205};
        p[3] = .{x + 210, `s.y + 225};
        immediate_quad(p[0], p[1], p[2], p[3], .{1, 0, 0, 1});
    }
    `s.y -= 31;
}

draw_load_window :: (state: *Subwindow_State, r: Rect, data: *void) {
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

get_mouse_editor_cell :: () -> Coord, bool {
    width := ROOM_WIDTH;
    height := ROOM_HEIGHT;
    tile_height, grid_height, left_boundary, right_boundary, bot_boundary, top_boundary := get_tile_ui_data(height);
    mouse_x, mouse_y, ok := get_mouse_pointer_position();

    // print("Tile Height True: %\n", tile_height);

    mouse_y = WINDOW_HEIGHT - mouse_y; // Flip mouse y to match grid row ordering
    in_bounds: bool;

    mouse_x = (mouse_x - xx left_boundary - xx tile_height) / xx tile_height;
    mouse_y = (mouse_y - xx bot_boundary - xx tile_height) / xx tile_height;

    in_bounds = mouse_x >= 0 && mouse_x < width && mouse_y >= 0 && mouse_y < height;

    // Want to find a vec here that is the distance from the center, but using the the gameplay tile height instead of the editor tile_height

    return .{xx mouse_x, xx mouse_y}, ok && in_bounds;
}

#scope_file
Entity_Relationship :: enum {
    NONE;
    PARENT;
    CHILD;
    SIB;
}
handle_field :: (field_name: string, field_ptr: *Entity_Handle, relationship: Entity_Relationship, follow_handle := true, set_button := true, loc := #caller_location) #expand {
    label_rect := get_rect(`x, `y, 100, 30);
    label(label_rect, field_name, *`editor_state.theme.label_theme);

    field_rect := get_rect(`x + 75, `y, 160, 24);
    field_string: string;
    if entity_valid(field_ptr.*, e = *`room.entities) {
        field_string = tprint("i: %, g: %", field_ptr.index, field_ptr.generation);
    } else {
        field_string = "NULL";
    }
    label(field_rect, field_string, *`editor_state.theme.label_theme);
    if set_button {
        button_rect := get_rect(`x + 155, `y, 80, 30);
        should_set_handle := button(button_rect, "Set", loc = loc, identifier = 0);
        if should_set_handle {
            if relationship == {
            case .PARENT;
                context.room_editor_state.editor_click_mode = .HANDLE_SET_PARENT;
            case .CHILD;
                context.room_editor_state.editor_click_mode = .HANDLE_SET_CHILD;
            case .SIB;
                context.room_editor_state.editor_click_mode = .HANDLE_SET_SIB;
            }
        }
    }
    if follow_handle && entity_valid(field_ptr.*, e = *`room.entities) {
        button_rect := get_rect(`x + 240, `y, 80, 30);
        should_goto_handle := button(button_rect, "Goto", loc = loc, identifier = 1);
        if should_goto_handle {
            context.room_editor_state.current_entity_handle = field_ptr.*;
        }
    }

    button_rect := get_rect(`x + 320, `y, 20, 30);
    should_drop_handle := button(button_rect, "X", loc = loc, identifier = 1);
    if should_drop_handle {
        // TO make this really complete need to drop it from the parent too
        field_ptr.* = .{};
    }

    `y -= 32;
}

vec_field :: (field_name: string, field_ptr: *Vector2, loc := #caller_location, set_button := true, follow_handle := true) #expand {
    label_rect := get_rect(`x, `y, 100, 30);
    label(label_rect, field_name, *`editor_state.theme.label_theme);

    field_rect := get_rect(`x + 105, `y, 160, 24);
    field_string := tprint("{% , %}",
                           formatFloat(field_ptr.x, width = 1, trailing_width = 1, zero_removal = .NO),
                           formatFloat(field_ptr.x, width = 1, trailing_width = 1, zero_removal = .NO));
    label(field_rect, field_string, *`editor_state.theme.label_theme);
    if set_button {
        button_rect := get_rect(`x + 240, `y, 80, 30);
        should_set_vector := button(button_rect, "Set", loc = loc, identifier = 0);
        if should_set_vector {
            context.room_editor_state.editor_click_mode = .VECTOR_SET;
        }
    }
    `y -= 35;
}

rotation_field :: (field_ptr: *float, loc := #caller_location) #expand {
    label_rect := get_rect(`x, `y, 100, 30);
    label(label_rect, "Rotation", *`editor_state.theme.label_theme);

    rot_left_rect := get_rect(`x + 105, `y, 40, 24);
    field_rect := get_rect(`x + 150, `y, 60, 24);
    rot_right_rect := get_rect(`x + 215, `y, 40, 24);
    field_string := tprint("%", formatFloat(field_ptr.*, width = 1, trailing_width = 1, zero_removal = .NO));
    label(field_rect, field_string, *`editor_state.theme.label_theme);
    left_pressed := button(rot_left_rect, "<-");
    right_pressed := button(rot_right_rect, "->");

    if left_pressed field_ptr.* += PI / 2;
    if right_pressed field_ptr.* -= PI / 2;
    `y -= 35;
}

extents_display :: (field_name: string, entity_ptr: *Entity, loc := #caller_location) #expand {
    `y -= 20;
    label_rect := get_rect(`x, `y, 100, 30);
    label(label_rect, field_name, *`editor_state.theme.label_theme);

    field_rect := get_rect(`x + 105, `y, 160, 24);
    left_button_rect := get_rect(`x + 70, `y, 30, 30);
    right_button_rect := get_rect(`x + 270, `y, 30, 30);
    up_button_rect := get_rect(`x + 170, `y + 27, 30, 30);
    down_button_rect := get_rect(`x + 170, `y - 27, 30, 30);
    field_string := tprint("{% , %}",
                           formatFloat(entity_ptr.render_extents.x / TILE_SIZE, width = 1, trailing_width = 2, zero_removal = .NO),
                           formatFloat(entity_ptr.render_extents.y / TILE_SIZE, width = 1, trailing_width = 2, zero_removal = .NO));
    label(field_rect, field_string, *`editor_state.theme.label_theme);

    left_pressed := button(left_button_rect, "<", loc = loc, identifier = 0);
    right_pressed := button(right_button_rect, ">", loc = loc, identifier = 1);
    up_pressed := button(up_button_rect, "^", loc = loc, identifier = 2);
    down_pressed := button(down_button_rect, "v", loc = loc, identifier = 3);

    if left_pressed {
        entity_ptr.extents.x -= TILE_SIZE * 1;
        entity_ptr.render_extents.x -= TILE_SIZE * 1;
    }
    if right_pressed {
        entity_ptr.extents.x += TILE_SIZE * 2;
        entity_ptr.render_extents.x += TILE_SIZE * 1;
    }
    if up_pressed {
        entity_ptr.extents.y += TILE_SIZE * 2;
        entity_ptr.render_extents.y += TILE_SIZE * 1;
    }
    if down_pressed {
        entity_ptr.extents.y -= TILE_SIZE * 2;
        entity_ptr.render_extents.y -= TILE_SIZE * 1;
    }

    `y -= 60;
}

create_entity_action_button :: (tag: Entity_Tag, x_position: float = -1, shift_y := true, loc := #caller_location) #expand {
    x: float;
    if x_position == -1 then x = `x + 5; else x = x_position;
    button_rect := get_rect(x, `y, 165, 30);
    button_text := tprint("%", tag);
    should_make_entity := button(button_rect, button_text, loc = loc);
    if should_make_entity {
        `editor_state.entity_to_make = tag;
        `editor_state.editor_click_mode = .MAKE_ENTITY;
    }
    if shift_y `y -= 32;
}

create_wall_action_button :: (type: Collision_Tile, x_position: float = -1, shift_y := true, loc := #caller_location) #expand {
    x: float;
    if x_position == -1 then x = `x + 5; else x = x_position;
    button_rect := get_rect(x, `y, 165, 30);
    button_text := tprint("%", type);
    should_make_wall := button(button_rect, button_text, loc = loc);
    if should_make_wall {
        `editor_state.wall_to_make = type;
        `editor_state.editor_click_mode = .SET_WALL_START;
    }
    if shift_y `y -= 32;
}

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

enum_flag_display :: (ptr_to_enum: *$T, left_margin: float32, top_margin: float32, loc := #caller_location) -> float #expand {
    enum_type_info := cast(*Type_Info_Enum)T;
    y := top_margin;
    for 0..enum_type_info.names.count - 1 {
        m_rect := get_rect(left_margin, y, 140, 22);
        y -= 30;
        name := enum_type_info.names[it];
        value := cast(T)enum_type_info.values[it];
        has_flag := ptr_to_enum.* & value == value;
        m_pressed := base_checkbox(m_rect, name, has_flag, *`editor_state.theme.checkbox_theme, identifier = it, loc = loc);
        if m_pressed {
            if has_flag {
                ptr_to_enum.* &= ~value;
            } else {
                ptr_to_enum.* |= value;
            }
        }
    }
    return y;
}

map_position_display :: (left: float32, right: float32, top: float32, bot: float32) #expand {
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

true_vec_from_coord :: (c: Coord) -> Vector2 #expand {
    raw := Vector2.{xx c.x * TILE_SIZE, xx c.y * TILE_SIZE};
    // Translate mouse cell to true vector representation when saving an entity
    half_room := Vector2.{((cast(float)ROOM_WIDTH) / 2) * TILE_SIZE, ((cast(float)ROOM_WIDTH) / 2) * TILE_SIZE};
    half_tile := Vector2.{TILE_SIZE, TILE_SIZE} / 2;
    final := raw - half_room + half_tile;
    return final;
}

modify_string :: (ps: *string, new_value: string) {
    free(ps.*);
    ps.* = copy_string(new_value);
}
