PLAYER_IDLE_ANIMATION := Sprite_Animation.{start = 1, end = 10};
PLAYER_DASH_ANIMATION := Sprite_Animation.{start = 29, end = 33, next_anim = *PLAYER_RUN_ANIMATION};
PLAYER_RUN_ANIMATION := Sprite_Animation.{start = 34, end = 43};
PLAYER_JUMP_ANIMATION := Sprite_Animation.{start = 63, end = 68, next_anim = *PLAYER_RISE_ANIMATION};
PLAYER_RISE_ANIMATION := Sprite_Animation.{start = 67, end = 68};
PLAYER_FALL_ANIMATION := Sprite_Animation.{start = 69, end = 72, next_anim = *PLAYER_FALL_LOOP_ANIMATION};
PLAYER_FALL_LOOP_ANIMATION := Sprite_Animation.{start = 73, end = 75};
PLAYER_RUN_TO_IDLE_ANIMATION := Sprite_Animation.{start = 48, end = 54, next_anim = *PLAYER_IDLE_ANIMATION};
PLAYER_SKID_ANIMATION := Sprite_Animation.{start = 44, end = 47, next_anim = *PLAYER_RUN_ANIMATION, transition_proc = player_exit_skid};

GEAR_ANIMATION := Sprite_Animation.{start = 17, end = 18};

set_animation :: (player: *Sprite_Animation_Player, animation: *Sprite_Animation) #expand {
    player.current_animation = animation;
    player.idx = animation.start;
}

player_exit_skid :: () {
    player := player_get();
    if !player {
        print("!!! Tried to exit skid but player pointer is invalid!\n");
        return;
    }
    print("Exit Skid\n");
    context.player_data.facing_right = player.movement_delta.x >= 0;
    player.flags &= ~.SKIDDING;
}
