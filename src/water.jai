calculate_water_flow :: (entity: *Entity) {
    cast_hit, cast_did_hit := circle_cast(entity.position, .{0, -1}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
    if cast_did_hit {
        horizontal_origin := cast_hit.shape_position_at_toi + (cast_hit.collision.depth * Vector2.{0, 1});
        left_cast_hit, left_cast_did_hit := circle_cast(horizontal_origin, .{-1, 0}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
        right_cast_hit, right_cast_did_hit := circle_cast(horizontal_origin, .{1, 0}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
    }
}

horizontal_water_flow :: () {
}
