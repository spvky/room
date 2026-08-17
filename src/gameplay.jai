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
            dir_to_static := normalize(static.position - p.position);
            push_direction := ifx dot_product(dir_to_static, collision.normal) < 0 then collision.normal else -collision.normal;
            print("Current Position: %\nPush Amount: %\n", p.position, push_direction * collision.depth);
            player_pos += push_direction * collision.depth;
            hit = true;
        }
    }
    player_colliding = hit;
}
