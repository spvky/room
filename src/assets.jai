Asset_Atlas :: struct {
    rune_atlas: Sprite_Atlas;
    tile_atlas: Sprite_Atlas;
    room_frame_texture: Texture;
    collision_circle: Texture;
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
    atlas.tile_atlas = load_sprite_atlas_from_file("tiles.png", 16, 16);
    frame_bytes_view: []u8;
    frame_bytes_view.data = frame_bytes.data;
    frame_bytes_view.count = frame_bytes.count;
    ok := texture_load_from_memory(*atlas.room_frame_texture, cast([]u8)frame_bytes);
    if !ok print("Failed to load room frame texture from memory!\n");
    ok = texture_load_from_memory(*atlas.collision_circle, cast([]u8)collision_circle_bytes);
    if !ok print("Failed to load collision circle texture from memory!\n");
    atlas.player_sprite = make_sprite(*atlas.collision_circle);
}

make_static_tile_sprite :: inline (idx: int) -> Sprite_Animation_Player {
    return Sprite_Animation_Player.{atlas = *context.atlas.tile_atlas, start = idx, idx = idx};
}
