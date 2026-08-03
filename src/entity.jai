// When loading a room alot of these values will be prefabs that are inferred from the entity types in the int grid
Entity_Manager :: struct {
    items: [..]Entity;
    freelist: [..]Entity_Handle;
    count: u32;
}

Entity :: struct {
    #as using rigibody: Rigidbody;
    props: Entity_Properties;
    flags: Entity_Flags;
    using sprite: Sprite; @ignore_serialize
    handle: Entity_Handle; @ignore_serialize
    parent: Entity_Handle; @ignore_serialize
    first_child: Entity_Handle; @ignore_serialize
    next_sibling: Entity_Handle; @ignore_serialize
}

Entity_Handle :: struct {
    index: u32;
    generation: u32;
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

#add_context entities: *Entity_Manager;

operator == :: (a: Entity_Handle, b: Entity_Handle) -> bool {
    return a.index == b.index && a.generation == b.generation;
}

init_entities :: () {
    if !context.entities {
        context.entities = New(Entity_Manager);
    }
}

entities_clear :: (e: *Entity_Manager = context.entities) {
    array_reset_keeping_memory(*e.items);
    array_reset_keeping_memory(*e.freelist);
}

entities_free :: (e: *Entity_Manager = context.entities) {
    array_free(e.items);
    array_free(e.freelist);
}

entity_add :: (new_entity: Entity, e: *Entity_Manager = context.entities) -> Entity_Handle {
    entity := new_entity;
    if e.freelist.count > 0 {
        handle := pop(*e.freelist);
        handle.generation += 1;
        entity.handle = handle;
        e.items[handle.index] = entity;
        e.count += 1;
        return entity.handle;
    }

    if e.items.count == 0 {
        array_add(*e.items, Entity.{});
    }

    index := cast(u32)e.items.count;
    entity.handle.index = index;
    entity.handle.generation = 1;
    array_add(*e.items, entity);
    e.count += 1;
    return entity.handle;
}

entity_get :: (handle: Entity_Handle, e: *Entity_Manager = context.entities) -> *Entity {
    if handle.index > 0 && cast(int)handle.index < e.items.count && e.items[handle.index].handle == handle {
        return *e.items[handle.index];
    }
    return null;
}

entity_remove :: (handle: Entity_Handle, e: *Entity_Manager = context.entities) {
    if handle.index > 0 && cast(int)handle.index < e.items.count && e.items[handle.index].handle == handle {
        array_add(*e.freelist, handle);
        e.items[handle.index] = .{};
        e.count -= 1;
    }
}

entity_valid :: (handle: Entity_Handle, e: *Entity_Manager = context.entities) -> bool {
    return entity_get(handle, e) != null;
}

for_expansion :: (e: *Entity_Manager, body: Code, flags: For_Flags) #expand {
    for index: 0..e.items.count - 1 {
        if index == 0 continue;
        if e.items[index].handle.index == 0 continue;

        `it := *e.items[index];
        `it_index := index;
        #insert body;
    }
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
