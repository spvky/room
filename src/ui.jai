EDITOR_MODES: [2]string: .["Room", "Map"];
TILE_TYPES: [2]string: .["Wall", "Slope"];

Editor_State :: struct {
    editor_type: s32;
    editor_theme: Overall_Theme;
    room_options: Room_Editor_Options;
    kb_captured: bool;
    mouse_captured: bool;
    primary_window: Subwindow_Info = .{
                                       rect = #run get_rect(20, cast(float32)WINDOW_HEIGHT - 310, 400, 300),
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
    dropdown_rect := get_rect(r.x, r.y + r.h - 50, r.w, 50);
    y_pos := dropdown_rect.y - dropdown_rect.h - 10;
    x_pos := dropdown_rect.x + 5;

    dropdown(dropdown_rect, EDITOR_MODES, *editor_state.editor_type);
    if context.editor_state.editor_type == {
    case 0;
        // Tile painting
        room_options := *editor_state.room_options;
        tile_type_rect := get_rect(x_pos, y_pos, 200, 50);
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
        // /////
    }
}

#import "GetRect";
