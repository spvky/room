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

draw_int_grid :: () {
    set_shader_for_images(*context.atlas.industrial_atlas.texture);
    for <y: 0..WORLD_HEIGHT - 1 {
        for x: 0..WORLD_WIDTH - 1 {
            coord := Coord.{xx x, xx y};
            nt := check_world_auto_tile_value(coord);
            if nt == 0 then continue;
            pos := Vector2.{xx x * TILE_SIZE, xx y * TILE_SIZE} + (Vector2.{TILE_SIZE, TILE_SIZE} / 2);
            position, extents := cam_relative_pos_extents(pos, .{TILE_SIZE, TILE_SIZE});

            draw_tile(position, extents, nt);
            // pos and extents defined here will allow calling
            // draw_quad(uv_quad) for now
        }
    }
}

quad_from_neighbors :: (nt: Neighboring_Tiles, atlas: *Sprite_Atlas) -> UV_Quad #expand {
    // Fill
    if nt & FILL_MASK == FILL_MASK return uv_quad_from_atlas(atlas, 17);

    // Top
    if nt & TOP_MASK == TOP_MASK return uv_quad_from_atlas(atlas, 1);
    // Right
    if nt & RIGHT_MASK == RIGHT_MASK return uv_quad_from_atlas(atlas, 18);
    // Bot
    if nt & BOT_MASK == BOT_MASK return uv_quad_from_atlas(atlas, 33);
    // Left
    if nt & LEFT_MASK == LEFT_MASK return uv_quad_from_atlas(atlas, 16);

    // Top Left Corner
    if nt & TOP_LEFT_CORNER_MASK == TOP_LEFT_CORNER_MASK return uv_quad_from_atlas(atlas, 0);
    // Top Right Corner
    if nt & TOP_RIGHT_CORNER_MASK == TOP_RIGHT_CORNER_MASK return uv_quad_from_atlas(atlas, 2);
    // Bot Right Corner
    if nt & BOT_RIGHT_CORNER_MASK == BOT_RIGHT_CORNER_MASK return uv_quad_from_atlas(atlas, 34);
    // Bot Left Corner
    if nt & BOT_LEFT_CORNER_MASK == BOT_LEFT_CORNER_MASK return uv_quad_from_atlas(atlas, 32);

    // Vertical Bar
    if nt & VERTICAL_BAR_MASK == VERTICAL_BAR_MASK return uv_quad_from_atlas(atlas, 4);
    // Horizontal Bar
    if nt & HORIZONTAL_BAR_MASK == HORIZONTAL_BAR_MASK return uv_quad_from_atlas(atlas, 3);

    // Top Cap
    if nt & TOP_CAP_MASK == TOP_CAP_MASK return uv_quad_from_atlas(atlas, 5);
    // Right Cap
    if nt & RIGHT_CAP_MASK == RIGHT_CAP_MASK return uv_quad_from_atlas(atlas, 20);
    // Bot Cap
    if nt & BOT_CAP_MASK == BOT_CAP_MASK return uv_quad_from_atlas(atlas, 19);
    // Left Cap
    if nt & LEFT_CAP_MASK == LEFT_CAP_MASK return uv_quad_from_atlas(atlas, 21);
}

draw_tile :: (position: Vector2, extents: Vector2, nt: Neighboring_Tiles) #expand {
    p: [4]Vector2;
    uvs := quad_from_neighbors(nt, *context.atlas.industrial_atlas);
    half_tile := extents / 2;

    p[0] = .{-half_tile.x, -half_tile.y} + position;
    p[1] = .{half_tile.x, -half_tile.y} + position;
    p[2] = .{half_tile.x, half_tile.y} + position;
    p[3] = .{-half_tile.x, half_tile.y} + position;

    immediate_quad(p[0], p[1], p[2], p[3],
                   .{1, 1, 1, 1},
                   uvs[0], uvs[1], uvs[2], uvs[3]);
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
