Asset_Atlas :: struct {
    rune_atlas: Sprite_Atlas;
    tile_atlas: Sprite_Atlas;
    room_frame_texture: Texture;
    crate: Sprite;
}

#add_context atlas: *Asset_Atlas;

init_textures :: () {
    if !context.atlas {
        context.atlas = New(Asset_Atlas);
    }
    atlas := context.atlas;
    atlas.rune_atlas = load_sprite_atlas_from_file("runes.png", 5, 4);
    atlas.tile_atlas = load_sprite_atlas_from_file("tiles.png", 32, 32);
    rft, ok := load_texture_from_file("room_frame.png");
    if ok {
        atlas.room_frame_texture = rft;
    } else {
        print("Failed to load room frame texture!\n");
    }
    atlas.crate = sprite_from_atlas(*atlas.tile_atlas, 0);
}
