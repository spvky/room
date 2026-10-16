Asset_Atlas :: struct {
    rune_atlas: Sprite_Atlas;
    tile_atlas: Sprite_Atlas;
    character_atlas: Sprite_Atlas;
    room_frame_texture: Texture;
    collision_circle: Texture;
    moving_block_texture: Texture;
    map_cursor: Texture;
    player_sprite: Sprite;
    font: *Dynamic_Font;
}

frame_bytes :: #run read_entire_file("assets/room_frame.png");
collision_circle_bytes :: #run read_entire_file("assets/collision_circle.png");
map_cursor_bytes :: #run read_entire_file("assets/map_cursor.png");
moving_block_bytes :: #run read_entire_file("assets/moving_block.png");

#add_context atlas: *Asset_Atlas;

init_textures :: () {
    if !context.atlas {
        context.atlas = New(Asset_Atlas);
    }
    atlas := context.atlas;
    atlas.rune_atlas = load_sprite_atlas_from_file("runes.png", 5, 4);
    atlas.tile_atlas = load_sprite_atlas_from_file("tiles_32.png", 16, 16);
    atlas.character_atlas = load_sprite_atlas_from_file("main_character.png", 16, 9);

    ok := texture_load_from_memory(*atlas.room_frame_texture, cast([]u8)frame_bytes);
    if !ok print("Failed to load room frame texture from memory!\n");
    ok = texture_load_from_memory(*atlas.collision_circle, cast([]u8)collision_circle_bytes);
    if !ok print("Failed to load collision circle texture from memory!\n");
    ok = texture_load_from_memory(*atlas.map_cursor, cast([]u8)map_cursor_bytes);
    if !ok print("Failed to load map cursor texture from memory!\n");
    ok = texture_load_from_memory(*atlas.moving_block_texture, cast([]u8)moving_block_bytes);
    if !ok print("Failed to load moving block texture from memory!\n");
    atlas.player_sprite = make_sprite(*atlas.collision_circle);
    pixel_height := WINDOW_HEIGHT / 24;
    atlas.font = get_font_at_size("assets", "OpenSans-BoldItalic.ttf", pixel_height);
}
