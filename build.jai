window: Window_Type;
should_close: bool;
WINDOW_WIDTH :: 1920;
WINDOW_HEIGHT :: 1080;

AABB :: struct {
    min: Vector2;
    max: Vector2;
}

colliders: [..]AABB;

main :: () {
    window = create_window(WINDOW_WIDTH, WINDOW_HEIGHT, "Room");
    set_render_target(window);

    init();

    // player_tex = load_texture_from_file("player.png");
    // player_sprite = make_sprite(*player_tex);
    // helman := load_editor_room_from_file("Timothy.room");
    while !should_close {
        update_window_events();
        for event: events_this_frame {
            getrect_handle_event(event);
        }
        #if OS == .WINDOWS get_mouse_cell();
        process_input();
        #if OS == .WINDOWS paint_tile_values();
        render();
    }
}

init :: () {
    init_textures();
    init_editor();
    init_entities();
    init_editor_room();
}

#import "Basic";
#import "Simp";
#import "Simp_Extended";
#import "Input";
#import "Math";
#import "Window_Creation";
#import "File";
#import "String";
#import "Hash_Table";
#load "src/assets.jai";
#load "src/room.jai";
#load "src/render.jai";
#load "src/input.jai";
#load "src/runes.jai";
#load "src/player.jai";
#load "src/ui.jai";
#load "src/thing.jai";
#load "src/collision.jai";
#load "src/io.jai";
#load "src/entity.jai";
#load "src/editing.jai";
#load "src/entity_manager.jai";
