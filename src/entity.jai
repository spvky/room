Entity :: struct {
    #as using rigibody: Rigidbody;
    props: Entity_Properties;
    flags: Entity_Flags;
    handle: Entity_Handle;
    using sprite: Sprite;
}

Rigidbody :: struct {
    position: Vector2;
    velocity: Vector2;
    rotation: float32;
    shape_kind: Collision_Shape;
    parent: Entity_Handle; @ignore_serialize
    first_child: Entity_Handle; @ignore_serialize
    next_sibling: Entity_Handle; @ignore_serialize
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
    GRAVITY_AFFECTED :: 1 << 2;
}

Entity_Flags :: enum_flags u32 {
    GROUNDED :: 1 << 0;
    IN_WATER :: 1 << 1;
    POWERED :: 1 << 2;
}
