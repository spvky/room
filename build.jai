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
    init_editor();
    init_entities();

    entity_add(Entity.{props = .RENDERABLE | .STATIC});
    h2 := entity_add(Entity.{props = .STATIC});
    entity_add(Entity.{props = .GRAVITY_AFFECTED});
    entity_remove(h2);
    print("% Entities found\n", context.entities.count);
    for *context.entities print("Props: %\n", it.props);

    context.current_room = New(Room);
    rune_atlas = load_sprite_atlas_from_file("runes.png", 5, 4);
    player_tex = load_texture_from_file("player.png");
    player_sprite = make_sprite(*player_tex);
    while !should_close {
        update_window_events();
        get_mouse_cell();
        process_input();
        paint_tile_values();
        render();
    }
}

#import "Basic";
#import "Simp";
#import "Simp_Extended";
#import "Input";
#import "Math";
#import "Window_Creation";
#load "src/room.jai";
#load "src/render.jai";
#load "src/input.jai";
#load "src/runes.jai";
#load "src/player.jai";
#load "src/ui.jai";
#load "src/thing.jai";
#load "src/collision.jai";
#load "src/entity.jai";
#load "src/entity_manager.jai";
