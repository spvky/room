Animation_Manager :: struct {
    player: Sprite_Animation_Player;
    gears: Sprite_Animation_Player;
}

#add_context animations: *Animation_Manager;

init_animations :: () {
    if !context.animations {
        context.animations = New(Animation_Manager);
        context.animations.player.atlas = *context.atlas.character_atlas;
        context.animations.gears.atlas = *context.atlas.tile_atlas;
        set_animation(*context.animations.player, *PLAYER_IDLE_ANIMATION);
        set_animation(*context.animations.gears, *GEAR_ANIMATION);
    }
}
// Animations
PLAYER_IDLE_ANIMATION := Sprite_Animation.{start = 1, end = 10};
PLAYER_DASH_ANIMATION := Sprite_Animation.{start = 29, end = 33, next_anim = *PLAYER_RUN_ANIMATION};
PLAYER_RUN_ANIMATION := Sprite_Animation.{start = 34, end = 43};
PLAYER_JUMP_ANIMATION := Sprite_Animation.{start = 63, end = 68, next_anim = *PLAYER_RISE_ANIMATION};
PLAYER_RISE_ANIMATION := Sprite_Animation.{start = 67, end = 68};
PLAYER_FALL_ANIMATION := Sprite_Animation.{start = 69, end = 72, next_anim = *PLAYER_FALL_LOOP_ANIMATION};
PLAYER_FALL_LOOP_ANIMATION := Sprite_Animation.{start = 73, end = 75};
PLAYER_RUN_TO_IDLE_ANIMATION := Sprite_Animation.{start = 48, end = 54, next_anim = *PLAYER_IDLE_ANIMATION};
PLAYER_SKID_ANIMATION := Sprite_Animation.{start = 44, end = 47, next_anim = *PLAYER_RUN_ANIMATION, transition_proc = player_exit_skid};
PLAYER_WALK_ANIMATION := Sprite_Animation.{start = 15, end = 24};
PLAYER_PUSH_ANIMATION := Sprite_Animation.{start = 131, end = 140};
PLAYER_DEATH_ANIMATION := Sprite_Animation.{start = 108, end = 130, transition_proc = reset_player};
PLAYER_WALL_SLIDE_ANIMATION := Sprite_Animation.{start = 76, end = 79};
PLAYER_WALL_JUMP_ANIMATION := Sprite_Animation.{start = 80, end = 83};
GEAR_ANIMATION := Sprite_Animation.{start = 18, end = 18};

set_animation :: (player: *Sprite_Animation_Player, animation: *Sprite_Animation, speed := 0.05) #expand {
    player.seconds_per_frame = speed;
    player.current_animation = animation;
    player.idx = animation.start;
}

player_exit_skid :: () {
    player := player_get();
    if !player {
        print("!!! Tried to exit skid but player pointer is invalid!\n");
        return;
    }
    context.player_data.facing_right = player.movement_delta.x >= 0;
}
