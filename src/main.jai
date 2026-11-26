last_time: float64;

main :: () {
    init();
    start_game();
    while !context.render_settings.should_close {
        update_window_events();
        recalc_display_values();
        now := seconds_since_init();
        raw_delta: float64 = now - last_time;
        delta := cast(float32)raw_delta;

        // Clamp Delta to make debugging easier but also alert that our delta is slow
        if delta >= 0.008333 {
            print("Unusually High Delta: %, clamping to 0.008333 (120 FPS)\n", delta);
            delta = 0.008333;
        }
        last_time = now;
        for event: events_this_frame {
            getrect_handle_event(event);
        }
        process_input(delta);
        if context.game_state == {
        case .GAMEPLAY;
            gameplay_update(delta);
        case .MAP_PLACEMENT;
            map_screen_update();
        case .ROOM_EDITOR;
            room_editor_update();
        }
        render();
        game_state_update();
        reset_temporary_storage();
    }
}

start_game :: () {
    bake_world();
    snap_camera_pos();
    context.game_state = .GAMEPLAY;
    snapshot_entities();
}

init :: () {
    init_render_settings();
    init_camera();
    init_player();
    init_events();
    init_textures();
    init_animations();
    init_entities();
    init_rooms();
    init_map();
    init_input();
    init_world();
    init_collision_tables();
    init_inspector();
    init_room_editor();
    init_debug_mode();
    init_screen_effects();
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
#import "GetRect";
#import "File_Utilities";
#import "Random";
#import "Trees";
#import "stb_image_write";
GL :: #import "GL";
#load "animations.jai";
#load "autotiling.jai";
#load "assets.jai";
#load "render.jai";
#load "input.jai";
#load "runes.jai";
#load "player.jai";
#load "entity.jai";
#load "collision.jai";
#load "io.jai";
#load "camera.jai";
#load "map_screen.jai";
#load "gameplay.jai";
#load "events.jai";
#load "physics.jai";
#load "sprites.jai";
#load "dev_util.jai";
// #load "quadtree.jai";
#load "parsing.jai";
#load "inspector.jai";
#load "text.jai";
#load "map_types.jai";
#load "power.jai";
#load "room_editor.jai";
#load "util.jai";
#load "water.jai";
#load "debug_mode.jai";
#load "screen_effects.jai";
