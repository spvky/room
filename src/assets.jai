Asset_Atlas :: struct {
    rune_atlas: Sprite_Atlas;
    tile_atlas: Sprite_Atlas;
    room_frame_texture: Texture;
    collision_circle: Texture;
    map_cursor: Texture;
    player_sprite: Sprite;
    font: *Dynamic_Font;
}

frame_bytes :: #run read_entire_file("assets/room_frame.png");
collision_circle_bytes :: #run read_entire_file("assets/collision_circle.png");
map_cursor_bytes :: #run read_entire_file("assets/map_cursor.png");

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
    ok = texture_load_from_memory(*atlas.map_cursor, cast([]u8)map_cursor_bytes);
    atlas.player_sprite = make_sprite(*atlas.collision_circle);
    pixel_height := WINDOW_HEIGHT / 24;
    atlas.font = get_font_at_size("assets", "OpenSans-BoldItalic.ttf", pixel_height);
}

// my_init_fonts :: () {
//     // So that we can load our font, set to path of running executable.
//     // @Incomplete: Pack a default font into Simp.
// 
//     pixel_height := window_height / 24;
// 
//     // @Cleanup: Don't have path + name be separate.
//     my_font = Simp.get_font_at_size(base_dir, "OpenSans-BoldItalic.ttf", pixel_height);
//     assert(my_font != null);
// }

sprite :: (idx: int, null_ptr := false) -> Sprite #expand {
    atlas := *context.atlas.tile_atlas;
    return sprite_from_atlas(atlas, idx);
}

sprite_sheet :: (idx: int, length: int) -> Sprite_Sheet #expand {
    atlas := *context.atlas.tile_atlas;
    return Sprite_Sheet.{
                         atlas = atlas, start = idx, idx = idx, length = length};
}

make_static_tile_sprite :: (idx: int) -> Sprite_Animation_Player #expand {
    return Sprite_Animation_Player.{atlas = *context.atlas.tile_atlas, start = idx, idx = idx};
}
