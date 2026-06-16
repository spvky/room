Thing :: struct {
    using position: Vector2;
    kind: Thing_Kind;
    using collision_data: Collision_Data;
    #overlay (collision_data) using character_data: Character_Data;
}

Thing_Kind :: enum {
    NIL :: 0;
    CHARACTER :: 1;
    COLLISION :: 2;
}

Collision_Data :: struct @thing_data {
    collision_shape: Collision_Shape;
    is_sensor := false;
    verts: void;
    polygon_verts: [4]Vector2;
    #overlay (polygon_verts) aabb_extents: [2]Vector2;
    #overlay (polygon_verts) triangle_verts: [3]Vector2;
}

Character_Data :: struct {
    velocity: Vector2;
    size := Vector2.{100, 100};
    map: *Texture;
}

Collision_Shape :: enum {
    TRIANGLE;
    POLYGON;
    AABB;
}

Character_Kind :: enum {
    BUG :: 0;
}
