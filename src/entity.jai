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
    // Collision fields
    triangle_vertices: [3]Vector2;
    #overlay (triangle_vertices) extents: Vector2;
    #overlay (triangle_vertices) radius: float32;
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

// make_static_aabb_from_grid :: (left: int, right: int, bot: int, top: int, tile_height: float32) -> Editor_Collider {
//     entity: Entity;
//     entity.shape_kind = .RECTANGLE;
//     entity.props = .RENDERABLE | .STATIC | .COLLIDABLE;
//     f_left: float32 = tile_height * xx left;
//     f_bot: float32 = tile_height * xx bot;
//     f_right: float32 = tile_height * (xx right + 1);
//     f_top: float32 = tile_height * (xx top + 1);
// 
//     width := f_right - f_left;
//     height := f_top - f_bot;
//     entity.position = (Vector2.{f_left, f_bot} + Vector2.{f_right, f_top}) / 2;
//     entity.extents = Vector2.{width / 2, height / 2};
// 
//     return entity;
// }
