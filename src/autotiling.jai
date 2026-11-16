Neighboring_Tiles :: enum_flags u8 {
    TOP :: 1 << 1;
    TOP_RIGHT :: 1 << 1;
    RIGHT :: 1 << 2;
    BOT_RIGHT :: 1 << 3;
    BOT :: 1 << 4;
    BOT_LEFT :: 1 << 5;
    LEFT :: 1 << 6;
    TOP_LEFT :: 1 << 7;
}

quad_from_neighbors :: (nt: Neighboring_Tiles) -> UV_Quad #expand {
    atlas := *context.atlas.factory_atlas;

    // Fill
    if nt & FILL_MASK == FILL_MASK return uv_quad_from_atlas(atlas, 4);

    // Top
    if nt & TOP_MASK == TOP_MASK return uv_quad_from_atlas(atlas, 4);
    // Right
    if nt & RIGHT_MASK == RIGHT_MASK return uv_quad_from_atlas(atlas, 4);
    // Bot
    if nt & BOT_MASK == BOT_MASK return uv_quad_from_atlas(atlas, 4);
    // Left
    if nt & LEFT_MASK == LEFT_MASK return uv_quad_from_atlas(atlas, 4);

    // Top Left Corner
    if nt & TOP_LEFT_CORNER_MASK == TOP_LEFT_CORNER_MASK return uv_quad_from_atlas(atlas, 1);
    // Top Right Corner
    if nt & TOP_RIGHT_CORNER_MASK == TOP_RIGHT_CORNER_MASK return uv_quad_from_atlas(atlas, 3);
    // Bot Right Corner
    if nt & BOT_RIGHT_CORNER_MASK == BOT_RIGHT_CORNER_MASK return uv_quad_from_atlas(atlas, 5);
    // Bot Left Corner
    if nt & BOT_LEFT_CORNER_MASK == BOT_LEFT_CORNER_MASK return uv_quad_from_atlas(atlas, 5);

    // Vertical Bar
    if nt & VERTICAL_BAR_MASK == VERTICAL_BAR_MASK return uv_quad_from_atlas(atlas, 5);
    // Horizontal Bar
    if nt & HORIZONTAL_BAR_MASK == HORIZONTAL_BAR_MASK return uv_quad_from_atlas(atlas, 5);

    // Top Cap
    if nt & TOP_CAP_MASK == TOP_CAP_MASK return uv_quad_from_atlas(atlas, 1);
    // Right Cap
    if nt & RIGHT_CAP_MASK == RIGHT_CAP_MASK return uv_quad_from_atlas(atlas, 3);
    // Bot Cap
    if nt & BOT_CAP_MASK == BOT_CAP_MASK return uv_quad_from_atlas(atlas, 5);
    // Left Cap
    if nt & LEFT_CAP_MASK == LEFT_CAP_MASK return uv_quad_from_atlas(atlas, 5);
}

draw_tile :: (x: int, y: int, origin: Vector2) #expand {
    uvs: UV_Quad;
}

#scope_file
FILL_MASK: Neighboring_Tiles: .TOP | .LEFT | .RIGHT | .BOT;

TOP_CAP_MASK: Neighboring_Tiles: .BOT;
RIGHT_CAP_MASK: Neighboring_Tiles: .LEFT;
BOT_CAP_MASK: Neighboring_Tiles: .TOP;
LEFT_CAP_MASK: Neighboring_Tiles: .RIGHT;

VERTICAL_BAR_MASK: Neighboring_Tiles: .RIGHT | .LEFT;
HORIZONTAL_BAR_MASK: Neighboring_Tiles: .TOP | .BOT;

TOP_LEFT_CORNER_MASK: Neighboring_Tiles: .RIGHT | .BOT;
TOP_RIGHT_CORNER_MASK: Neighboring_Tiles: .LEFT | .BOT;
BOT_RIGHT_CORNER_MASK: Neighboring_Tiles: .TOP | .LEFT;
BOT_LEFT_CORNER_MASK: Neighboring_Tiles: .TOP | .RIGHT;

TOP_MASK: Neighboring_Tiles: .RIGHT | .BOT | .LEFT;
RIGHT_MASK: Neighboring_Tiles: .TOP | .BOT | .LEFT;
BOT_MASK: Neighboring_Tiles: .TOP | .RIGHT | .LEFT;
LEFT_MASK: Neighboring_Tiles: .TOP | .RIGHT | .BOT;
