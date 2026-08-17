gameplay_update :: () {
    p: Entity;
    p.position = player_pos;
    p.shape_kind = .CIRCLE;
    p.radius = TILE_SIZE / 2;

    hit: bool;
    for context.static_collision_table {
        static := entity_get(it_index);
        collision, did_collide := dynamic_vs_static_collision_test(*p, static);
        if did_collide {
            hit = true;
        }
    }
    player_colliding = hit;
}
