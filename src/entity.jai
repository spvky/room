Entity :: struct {
    #as using rigibody: Rigidbody;
    props: Entity_Properties;
    flags: Entity_Flags;
    handle: Entity_Handle;
    using sprite: Sprite;
    parent: Entity_Handle; @ignore_serialize
    first_child: Entity_Handle; @ignore_serialize
    next_sibling: Entity_Handle; @ignore_serialize
}

Rigidbody :: struct {
    position: Vector2;
    velocity: Vector2;
    rotation: float32;
    shape_kind: Collision_Shape;
    // Keep the collision data at the bottom unless there are alignment issues to avoid some funky overlays
    // Triangle Collision
    triangle_vertices: [3]Vector2;
    // Rectangle Collision
    #overlay (triangle_vertices) extents: Vector2;
    // Circle and Capsule Collision
    #overlay (triangle_vertices) radius: float32;
    // Capsule Collision
    #overlay (triangle_vertices[0].y) height: float32;
}

Collision_Shape :: enum {
    RECTANGLE;
    TRIANGLE;
    CIRCLE;
    CAPSULE;
}

Entity_Properties :: enum_flags u32 {
    RENDERABLE :: 1 << 0;
    STATIC :: 1 << 1;
    COLLIDABLE :: 1 << 2;
    GRAVITY_AFFECTED :: 1 << 3;
}

Entity_Flags :: enum_flags u32 {
    GROUNDED :: 1 << 0;
    IN_WATER :: 1 << 1;
    POWERED :: 1 << 2;
}

make_static_aabb_from_grid :: (left: int, right: int, bot: int, top: int) -> Entity {
    entity: Entity;
    entity.shape_kind = .RECTANGLE;
    entity.flags = .RENDERABLE | .STATIC | .COLLIDABLE;
    f_left: float32 = GRID_LEFT_BOUNDARY + (GRID_TILE_HEIGHT * xx left);
    f_bot: float32 = GRID_BOT_BOUNDARY + (GRID_TILE_HEIGHT * xx bot);
    f_right: float32 = GRID_LEFT_BOUNDARY + (GRID_TILE_HEIGHT * (xx right + 1));
    f_top: float32 = GRID_BOT_BOUNDARY + (GRID_TILE_HEIGHT * (xx top + 1));

    width := f_right - f_left;
    height := f_top - f_bot;
    entity.position = (Vector2.{f_left, f_bot} + Vector2.{f_right, f_top}) / 2;
    entity.extents = Vector2.{width / 2, height / 2};

    return entity;
}
