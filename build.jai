window: Window_Type;
should_close: bool;
WINDOW_WIDTH :: 1920;
WINDOW_HEIGHT :: 1080;
last_time: float64;

main :: () {
    window = create_window(WINDOW_WIDTH, WINDOW_HEIGHT, "Room");
    set_render_target(window);
    init();
    while !should_close {
        update_window_events();
        now := seconds_since_init();
        raw_delta: float64 = now - last_time;
        delta := cast(float32)raw_delta;
        last_time = now;
        for event: events_this_frame {
            getrect_handle_event(event);
        }
        #if OS == .WINDOWS get_mouse_cell();
        process_input(delta);
        if context.game_state == {
        case .ROOM_DESIGNER;
            #if OS == .WINDOWS paint_tile_values();
        case .MAP_PLACEMENT;
            map_screen_update();
        }
        render();
        game_state_update();
        reset_temporary_storage();
    }
}

// get_editor_mode :: () -> s32 {
//     return context.editor_state.editor_type;
// }

init :: () {
    init_camera();
    init_rendering();
    init_textures();
    init_editor();
    init_entities();
    init_rooms();
    init_map();
    init_input();
    init_world();
}

#import "Basic";
#import "Simp";
#import "Simp_Extended";
#import "Input";
#import "InputBuffer"(ACTION_TYPE = Action);
#import "Math";
#import "Window_Creation";
#import "File";
#import "String";
#import "Hash_Table";
#import "Hash";
#import "stb_image_write";
#load "src/assets.jai";
#load "src/render.jai";
#load "src/input.jai";
#load "src/runes.jai";
#load "src/player.jai";
#load "src/room_designer.jai";
#load "src/thing.jai";
#load "src/collision.jai";
#load "src/io.jai";
#load "src/entity.jai";
#load "src/camera.jai";
#load "src/map.jai";
#load "src/game_ui.jai";
#load "src/game_state.jai";
