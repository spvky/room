window: Window_Type;
should_close: bool;
WINDOW_WIDTH :: 1920;
WINDOW_HEIGHT :: 1080;
room: Room;

AABB :: struct {
    min: Vector2;
    max: Vector2;
    start_x: int;
    start_y: int;
    end_x: int;
    end_y: int;
}

colliders: [..]AABB;

main :: () {
    window = create_window(WINDOW_WIDTH, WINDOW_HEIGHT, "Room");
    set_render_target(window);

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
#import "Input";
#import "Math";
#import "Window_Creation";
#load "src/room.jai";
#load "src/render.jai";
#load "src/input.jai";
