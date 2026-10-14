// Sprites 
CRATE_SPRITE: Sprite;
LEVER_ON_SPRITE: Sprite;
LEVER_OFF_SPRITE: Sprite;
BUTTON_ON_SPRITE: Sprite;
BUTTON_OFF_SPRITE: Sprite;
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
GEAR_ANIMATION := Sprite_Animation.{start = 17, end = 18};

Sprite_UVs :: [4]Vector2;

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

draw_one_tile_entity :: (entity: *Entity) {
    atlas := *context.atlas.tile_atlas;
    pos, extents, offset := cam_relative_pos_extents(entity.position, .{TILE_SIZE, TILE_SIZE}, .{});
    set_shader_for_images(*atlas.texture);

    if entity.tag == {
    case .CRATE;
        uvs := uv_quad_from_atlas(atlas, 0);
        draw_quad(uvs);
    case .LEVER;
        uvs: UV_Quad;
        if entity_has_flags(entity, .POWERED) {
            uvs = uv_quad_from_atlas(atlas, 8);
        } else {
            uvs = uv_quad_from_atlas(atlas, 9);
        }
        draw_quad(uvs);
    case .BUTTON;
        uvs: UV_Quad;
        if entity_has_flags(entity, .POWERED) {
            uvs = uv_quad_from_atlas(atlas, 11);
        } else {
            uvs = uv_quad_from_atlas(atlas, 10);
        }
        draw_quad(uvs);
    case .GEAR;
    case .ROOM_PICKUP;
        room_ptr := table_find_pointer(context.room_table, entity.room_pickup_hash);
        if room_ptr {
            pos.y += 4 + context.camera.zoom * 4.0 * cast(float32)sin(last_time * 4);
            uvs := uv_quad_from_atlas(atlas, 19);
            color: Vector4;
            has_been_picked_up := room_ptr.flags & .PICKED_UP == .PICKED_UP;
            if has_been_picked_up {
                color = .{1, 1, 1, 0.2};
            } else {
                color = .{1, 1, 1, 1};
            }
            draw_quad(uvs, color);
        }
    }
}

draw_switch_block :: (entity: *Entity) {
    pos, extents, offset := cam_relative_pos_extents(entity.position, entity.render_extents, entity.render_offset);
    tiles_width := entity.render_extents.x / TILE_SIZE;
    tiles_height := entity.render_extents.y / TILE_SIZE;

    set_shader_for_images(*context.atlas.moving_block_texture);
    // Todo, actually render the switch blocks
    if tiles_width == 1 && tiles_height == 1 {
        render_npatch_segment(.TOP_LEFT, pos + .{-TILE_SIZE / 4, TILE_SIZE / 4});
        render_npatch_segment(.TOP_RIGHT, pos + .{TILE_SIZE / 4, TILE_SIZE / 4});
        render_npatch_segment(.BOT_LEFT, pos + .{-TILE_SIZE / 4, -TILE_SIZE / 4});
        render_npatch_segment(.BOT_RIGHT, pos + .{TILE_SIZE / 4, -TILE_SIZE / 4});
    } else if tiles_width == 1 {
        height_int := cast(int)tiles_height;
        extent_bottom := pos.y + ((-TILE_SIZE * tiles_height) * 0.5);
        for 0..height_int - 1 {
            position := Vector2.{pos.x, (extent_bottom + (TILE_SIZE / 2)) + (xx it) * (TILE_SIZE)};
            tl: N_Patch_Region;
            tr: N_Patch_Region;
            bl: N_Patch_Region;
            br: N_Patch_Region;
            if it == 0 {
                tl = .LEFT;
                tr = .RIGHT;
                bl = .BOT_LEFT;
                br = .BOT_RIGHT;
            } else if it == height_int - 1 {
                tl = .TOP_LEFT;
                tr = .TOP_RIGHT;
                bl = .LEFT;
                br = .RIGHT;
            } else {
                tl = .LEFT;
                tr = .RIGHT;
                bl = .LEFT;
                br = .RIGHT;
            }
            render_npatch_segment(tl, position + .{-TILE_SIZE / 4, TILE_SIZE / 4});
            render_npatch_segment(tr, position + .{TILE_SIZE / 4, TILE_SIZE / 4});
            render_npatch_segment(bl, position + .{-TILE_SIZE / 4, -TILE_SIZE / 4});
            render_npatch_segment(br, position + .{TILE_SIZE / 4, -TILE_SIZE / 4});
        }
    } else if tiles_height == 1 {
        width_int := cast(int)tiles_width;
        extent_left := pos.x + ((-TILE_SIZE * tiles_width) * 0.5);
        for 0..width_int - 1 {
            position := Vector2.{(extent_left + (TILE_SIZE / 2)) + (xx it) * (TILE_SIZE), pos.y};
            tl: N_Patch_Region;
            tr: N_Patch_Region;
            bl: N_Patch_Region;
            br: N_Patch_Region;
            if it == 0 {
                tl = .TOP_LEFT;
                tr = .TOP;
                bl = .BOT_LEFT;
                br = .BOT;
            } else if it == width_int - 1 {
                tl = .TOP;
                tr = .TOP_RIGHT;
                bl = .BOT;
                br = .BOT_RIGHT;
            } else {
                tl = .TOP;
                tr = .TOP;
                bl = .BOT;
                br = .BOT;
            }
            render_npatch_segment(tl, position + .{-TILE_SIZE / 4, TILE_SIZE / 4});
            render_npatch_segment(tr, position + .{TILE_SIZE / 4, TILE_SIZE / 4});
            render_npatch_segment(bl, position + .{-TILE_SIZE / 4, -TILE_SIZE / 4});
            render_npatch_segment(br, position + .{TILE_SIZE / 4, -TILE_SIZE / 4});
        }
    } else {
        width_int := cast(int)tiles_width;
        height_int := cast(int)tiles_height;
        extent_left := pos.x + ((-TILE_SIZE * tiles_width) * 0.5);
        extent_bottom := pos.y + ((-TILE_SIZE * tiles_height) * 0.5);
        for x: 0..width_int - 1 {
            for y: 0..height_int - 1 {
                position := Vector2.{(extent_left + (TILE_SIZE / 2)) + (xx x) * (TILE_SIZE), (extent_bottom + (TILE_SIZE / 2)) + (xx y) * (TILE_SIZE)};
                tl: N_Patch_Region;
                tr: N_Patch_Region;
                bl: N_Patch_Region;
                br: N_Patch_Region;
                if x == 0 && y == 0 {
                    tl = .LEFT;
                    tr = .CENTER;
                    bl = .BOT_LEFT;
                    br = .BOT;
                } else if x == width_int - 1 && y == height_int - 1 {
                    tl = .TOP;
                    tr = .TOP_RIGHT;
                    bl = .CENTER;
                    br = .RIGHT;
                } else if x == width_int - 1 && y == 0 {
                    tl = .CENTER;
                    tr = .RIGHT;
                    bl = .BOT;
                    br = .BOT_RIGHT;
                } else if x == 0 && y == height_int - 1 {
                    tl = .TOP_LEFT;
                    tr = .TOP;
                    bl = .LEFT;
                    br = .CENTER;
                } else if x == 0 {
                    tl = .LEFT;
                    tr = .CENTER;
                    bl = .LEFT;
                    br = .CENTER;
                } else if y == 0 {
                    tl = .CENTER;
                    tr = .CENTER;
                    bl = .BOT;
                    br = .BOT;
                } else if x == width_int - 1 {
                    tl = .CENTER;
                    tr = .RIGHT;
                    bl = .CENTER;
                    br = .RIGHT;
                } else if y == height_int - 1 {
                    tl = .TOP;
                    tr = .TOP;
                    bl = .CENTER;
                    br = .CENTER;
                } else {
                    tl = .CENTER;
                    tr = .CENTER;
                    bl = .CENTER;
                    br = .CENTER;
                }
                render_npatch_segment(tl, position + .{-TILE_SIZE / 4, TILE_SIZE / 4});
                render_npatch_segment(tr, position + .{TILE_SIZE / 4, TILE_SIZE / 4});
                render_npatch_segment(bl, position + .{-TILE_SIZE / 4, -TILE_SIZE / 4});
                render_npatch_segment(br, position + .{TILE_SIZE / 4, -TILE_SIZE / 4});
            }
        }
    }
}

#scope_file
draw_quad :: (uvs: UV_Quad, color := Vector4.{1, 1, 1, 1}) #expand {
    p: [4]Vector2;

    origin := `pos + `extents;

    p[0] = .{-`extents.x / 2, -`extents.y / 2};
    p[1] = .{`extents.x / 2, -`extents.y / 2};
    p[2] = .{`extents.x / 2, `extents.y / 2};
    p[3] = .{-`extents.x / 2, `extents.y / 2};

    // Rotation is still a little funky revist when needed, it works fine for origin 0
    for 0..3 {
        p[it] = rotate(p[it], `entity.rotation);
        p[it] += `pos;
    }

    immediate_quad(p[0], p[1], p[2], p[3],
                   color,
                   uvs[0], uvs[1], uvs[2], uvs[3]);
}
