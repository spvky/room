Asset_Atlas :: struct {
    rune_atlas: Sprite_Atlas;
    tile_atlas: Sprite_Atlas;
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

    atlas.crate = sprite_from_atlas(*atlas.tile_atlas, 0);
}
