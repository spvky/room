Asset_Atlas :: struct {
    rune_atlas: Sprite_Atlas;
    tile_atlas: Sprite_Atlas;
    room_frame_texture: Texture;
    collision_circle: Texture;
    crate: Sprite;
    checker: Sprite;
    player_sprite: Sprite;
}

frame_bytes :: #run read_entire_file("assets/room_frame.png");
collision_circle_bytes :: #run read_entire_file("assets/collision_circle.png");

#add_context atlas: *Asset_Atlas;

init_textures :: () {
    if !context.atlas {
        context.atlas = New(Asset_Atlas);
    }
    atlas := context.atlas;
    atlas.rune_atlas = load_sprite_atlas_from_file("runes.png", 5, 4);
    atlas.tile_atlas = load_sprite_atlas_from_file("tiles.png", 32, 32);
    frame_bytes_view: []u8;
    frame_bytes_view.data = frame_bytes.data;
    frame_bytes_view.count = frame_bytes.count;
    ok := texture_load_from_memory(*atlas.room_frame_texture, cast([]u8)frame_bytes);
    if !ok print("Failed to load room frame texture from memory!\n");
    ok = texture_load_from_memory(*atlas.collision_circle, cast([]u8)collision_circle_bytes);
    if !ok print("Failed to load collision circle texture from memory!\n");
    atlas.player_sprite = make_sprite(*atlas.collision_circle);
    atlas.crate = sprite_from_atlas(*atlas.tile_atlas, 0);
    atlas.checker = sprite_from_atlas(*atlas.tile_atlas, 1);
}

draw_player :: (position: Vector2) {
    half_tile := TILE_SIZE / 2;
    left: float32 = position.x - (half_tile);
    right: float32 = position.x + (half_tile);
    top: float32 = position.y + (half_tile);
    bot: float32 = position.y - (half_tile);
    color: Vector4 = ifx player_colliding then Vector4.{0, 0, 1, 1} else Vector4.{1, 1, 1, 1};

    set_shader_for_images(*context.atlas.collision_circle);
    immediate_quad(
                   .{left, bot},
                   .{right, bot},
                   .{right, top},
                   .{left, top},
                   color);
}
