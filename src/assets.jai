Asset_Atlas :: struct {
    rune_atlas: Sprite_Atlas;
    tile_atlas: Sprite_Atlas;
    room_frame_texture: Texture;
    crate: Sprite;
    player_texture: Texture;
}

frame_bytes :: #run read_entire_file("assets/room_frame.png");

// #run {
//     handle, ok := file_open("assets/room_frame.png");
//     assert(ok, "Failed to open room frame!\n");
//     file_length, length_ok := file_length(handle);
//     assert(length_ok, "Failed to get frame file length!\n");
//     frame_bytes: [file_length]u8;
//     file_read(handle, *frame_bytes, file_length);
// }

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
    // rft, ok := load_texture_from_file("room_frame.png");
    // if ok {
    //     atlas.room_frame_texture = rft;
    // } else {
    //     print("Failed to load room frame texture!\n");
    // }
    atlas.crate = sprite_from_atlas(*atlas.tile_atlas, 0);
    texture_load_from_file(*atlas.player_texture, "assets/player.png");
}

draw_player :: (position: Vector2) {
    half_tile := TILE_SIZE / 2;
    left: float32 = position.x - (half_tile);
    right: float32 = position.x + (half_tile);
    top: float32 = position.y + (half_tile);
    bot: float32 = position.y - (half_tile);

    set_shader_for_images(*context.atlas.player_texture);
    immediate_quad(
                   .{left, bot},
                   .{right, bot},
                   .{right, top},
                   .{left, top},
                   .{1, 1, 1, 1});
}
