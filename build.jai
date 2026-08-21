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
        case .GAMEPLAY;
            gameplay_update();
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
    init_static_collision_table();
    entity_relation_test();
}

entity_relation_test :: () {
    a := entity_add(Entity.{});

    b := entity_add_child(a, Entity.{});
    c := entity_add_child(a, Entity.{});
    d := entity_add_child(a, Entity.{});
    e := entity_add_child(a, Entity.{});
    f := entity_add_child(c, Entity.{});
    g := entity_add_child(c, Entity.{});
    h := entity_add_child(e, Entity.{});

    print("Entities count: %!\n", context.entities.count);
    entity_remove(e);

    print("Entities count: %!\n", context.entities.count);
    // print("A: % | % child % parent %\n", a, entity_get(a), entity_get(a).first_child, entity_get(a).parent);
    // print("B: % | % child % parent % \n", b, entity_get(b), entity_get(b).first_child, entity_get(b).parent);
    // print("C: % | % child % parent % \n", c, entity_get(c), entity_get(c).first_child, entity_get(c).parent);
    // print("D: % | % child % parent % \n", d, entity_get(d), entity_get(d).first_child, entity_get(d).parent);
    // print("E: % | % child % parent % \n", e, entity_get(e), entity_get(e).first_child, entity_get(e).parent);
    // print("F: % | % child % parent % \n", f, entity_get(f), entity_get(f).first_child, entity_get(f).parent);
    // print("G: % | % child % parent % \n", g, entity_get(g), entity_get(g).first_child, entity_get(g).parent);
    // print("H: % | % child % parent % \n", h, entity_get(h), entity_get(h).first_child, entity_get(h).parent);
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
GL :: #import "GL";
#load "src/assets.jai";
#load "src/render.jai";
#load "src/input.jai";
#load "src/runes.jai";
#load "src/player.jai";
#load "src/room_designer.jai";
#load "src/entity.jai";
#load "src/collision.jai";
#load "src/io.jai";
#load "src/camera.jai";
#load "src/map.jai";
#load "src/game_ui.jai";
#load "src/game_state.jai";
#load "src/gameplay.jai";
#load "src/rope.jai";
#load "src/events.jai";
#load "src/dev_util.jai";
