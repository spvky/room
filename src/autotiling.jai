Neighboring_Tiles :: enum_flags u8 {
    TOP_LEFT :: 1 << 0;
    TOP :: 1 << 1;
    TOP_RIGHT :: 1 << 2;
    RIGHT :: 1 << 3;
    BOT_RIGHT :: 1 << 4;
    BOT :: 1 << 5;
    BOT_LEFT :: 1 << 6;
    LEFT :: 1 << 7;
}

quad_from_neighbors :: (nt: Neighboring_Tiles) -> UV_Quad #expand {
    atlas := *context.atlas.factory_atlas;
    if nt & .TOP | .LEFT | .RIGHT | .BOT == .TOP | .LEFT | .RIGHT | .BOT return uv_quad_from_atlas(atlas, 4);
    if nt & .TOP | .LEFT | .RIGHT | .TOP | .LEFT | .RIGHT return uv_quad_from_atlas(atlas, 7);
    if nt & .LEFT | .RIGHT | .BOT == .LEFT | .RIGHT | .BOT return uv_quad_from_atlas(atlas, 1);
    if nt & .TOP | .RIGHT | .BOT == .TOP | .RIGHT | .BOT return uv_quad_from_atlas(atlas, 3);
    if nt & .TOP | .LEFT | .BOT == .TOP | .LEFT | .BOT return uv_quad_from_atlas(atlas, 5);
}

draw_tile :: (x: int, y: int) {
    uvs: UV_Quad;
}
