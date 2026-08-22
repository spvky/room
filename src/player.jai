JUMP_HEIGHT: float32: 3.5 * TILE_SIZE;
JUMP_DISTANCE: float32: TILE_SIZE * 7;
TIME_TO_PEAK: float32: 0.3;
TIME_TO_DESCENT: float32: 0.28;
// Compile time calculated constants
JUMP_SPEED :: #run calculate_jump_speed();
RISING_GRAVITY :: #run calculate_rising_gravity();
FALLING_GRAVITY :: #run calculate_falling_gravity();
MOVE_SPEED :: #run calculate_lateral_speed();

#add_context player_handle: *Entity_Handle;

init_player :: () {
    if !context.player_handle {
        context.player_handle = New(Entity_Handle);
    }
}

player_is_valid :: () -> bool {
    return entity_valid(context.player_handle.*);
}

player_get :: () -> *Entity {
    return entity_get(context.player_handle.*);
}

set_player_move_delta :: () {
    player := player_get();
    if player.state == {
    case .MOVING;
        #through;
    case .STAND;
        #through;
    case .RISING;
        #through;
    case .FALLING;
        x: float32;
        if is_action_held(.MOVE_LEFT) {
            x -= 1;
        }
        if is_action_held(.MOVE_RIGHT) {
            x += 1;
        }
    }
}

#scope_file
calculate_jump_speed :: () -> float32 {
    return (-2 * JUMP_HEIGHT) / TIME_TO_PEAK;
}

calculate_rising_gravity :: () -> float32 {
    return (2 * JUMP_HEIGHT) / (TIME_TO_PEAK * TIME_TO_PEAK);
}

calculate_falling_gravity :: () -> float32 {
    return (2 * JUMP_HEIGHT) / (TIME_TO_DESCENT * TIME_TO_DESCENT);
}

calculate_lateral_speed :: () -> float32 {
    return JUMP_DISTANCE / (TIME_TO_PEAK + TIME_TO_DESCENT);
}
