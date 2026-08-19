Entity_Manager :: struct {
    items: [..]Entity;
    freelist: [..]Entity_Handle;
    count: u32;
}

#add_context entities: *Entity_Manager;

Entity :: struct {
    #as using rigibody: Rigidbody;
    props: Entity_Properties;
    flags: Entity_Flags;
    tag: Entity_Tag;
    sprite: *Sprite; @ignore_serialize
    handle: Entity_Handle; @ignore_serialize
    parent: Entity_Handle; @ignore_serialize
    first_child: Entity_Handle; @ignore_serialize
    last_child: Entity_Handle; @ignore_serialze
    prev_sibling: Entity_Handle; @ignore_serialize
    next_sibling: Entity_Handle; @ignore_serialize
    entity_signals: [..]Entity_Signal; @ignore_serialize
}

Entity_Handle :: struct {
    index: u32;
    generation: u32;
}

NULL_HANDLE :: Entity_Handle.{};

operator == :: (a: Entity_Handle, b: Entity_Handle) -> bool {
    return a.index == b.index && a.generation == b.generation;
}

handle_compare :: (a: Entity_Handle, b: Entity_Handle) -> bool {
    return a.index == b.index && a.generation == b.generation;
}

handle_hash :: (a: Entity_Handle) -> u32 {return sdbm_hash(*a, size_of(Entity_Handle));}

Rigidbody :: struct {
    position: Vector2;
    velocity: Vector2;
    rotation: float32;
    shape_kind: Collision_Shape;
    // Collision fields
    extents: Vector2;
    #overlay (extents) radius: float32;
    #overlay (extents.y) height: float32;
}

Collision_Shape :: enum {
    RECTANGLE;
    CIRCLE;
    CAPSULE;
}

Entity_Tag :: enum u8 {
    WALL;
    CRATE;
    GROUND_SENSOR;
}

Entity_Properties :: enum_flags u32 {
    RENDERABLE :: 1 << 0;
    STATIC :: 1 << 1;
    COLLIDABLE :: 1 << 2;
    GRAVITY_AFFECTED :: 1 << 3;
    SENSOR :: 1 << 4;
}

Entity_Flags :: enum_flags u32 {
    GROUNDED :: 1 << 0;
    IN_WATER :: 1 << 1;
    POWERED :: 1 << 2;
}
Entity_Signal :: struct {
    kind: Entity_Flag_Signal_Kind;
    relationship: Entity_Flag_Signal_Relationship;
    tag: Entity_Tag;
    flags: Entity_Flags;
}

// Entity Signals
Entity_Flag_Signal_Kind :: enum {
    ADD_FLAG;
    REMOVE_FLAG;
}

Entity_Flag_Signal_Relationship :: enum {
    PARENT;
    CHILD;
    CHILD_WITH_TAG;
    NEXT_SIBLING;
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
        array_add(*e.items, Entity.{}, true);
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

entity_remove :: (handle: Entity_Handle, e: *Entity_Manager = context.entities, depth := 0) {
    if handle.index > 0 && cast(int)handle.index < e.items.count && e.items[handle.index].handle == handle {
        print("Start removal at depth: % with handle %\n", depth, handle);
        entity := entity_get(handle);
        print("Got entity for removal % with handle %\n", entity, handle);
        if entity.first_child != NULL_HANDLE {
            current_child := entity_get(entity.first_child);

            while current_child.next_sibling != NULL_HANDLE {
                print("Child % removing sibling %\n", entity.first_child, current_child.next_sibling);
                entity_remove(current_child.next_sibling, depth = depth + 1);
            }

            entity_remove(entity.first_child, depth = depth + 1);
        }

        if entity.next_sibling != NULL_HANDLE {
            print("Ammending next sibling! at depth %\n", depth);
            next_sibling := entity_get(entity.next_sibling);
            next_sibling.prev_sibling = entity.prev_sibling;
        }

        if entity.prev_sibling != NULL_HANDLE {
            print("Ammending previous sibling! at depth %\n", depth);
            prev_sibling := entity_get(entity.prev_sibling);
            prev_sibling.next_sibling = entity.next_sibling;
        }

        if entity.prev_sibling == NULL_HANDLE && entity.parent != NULL_HANDLE {
            parent := entity_get(entity.parent);
            parent.first_child = entity.next_sibling;
        }

        print("Add Item to freelist at handle: %\n", handle);
        array_add(*e.freelist, handle);
        print("Clearing Item at handle: %\n", handle);
        e.items[handle.index] = .{};
        print("Decrementing at depth %!\n", depth);
        e.count -= 1;
    }
}

entity_valid :: (handle: Entity_Handle, e: *Entity_Manager = context.entities) -> bool {
    return entity_get(handle, e) != null;
}

entity_add_child :: (parent_handle: Entity_Handle, child_entity: Entity, e: *Entity_Manager = context.entities) -> Entity_Handle {
    child_handle: Entity_Handle;
    // check if parent is still valid
    if entity_valid(parent_handle) {
        child_handle = entity_add(child_entity);
        if child_handle == NULL_HANDLE {
            print("Tried to add entity child and still have a null handle, something is wrong!\n");
            return child_handle;
        }

        parent_ptr := entity_get(parent_handle);
        child_ptr := entity_get(child_handle);
        child_ptr.parent = parent_handle;

        // you can also keep a handle to the last child to avoid iterating the list when inserting
        // assert((parent_ptr.first_child == NULL_HANDLE && parent_ptr.last_child == NULL_HANDLE) ||
        //        (parent_ptr.first_child != NULL_HANDLE && parent_ptr.last_child != NULL_HANDLE));

        child_ptr.prev_sibling = parent_ptr.last_child;
        if parent_ptr.last_child == NULL_HANDLE {
            parent_ptr.first_child = child_handle;
            parent_ptr.last_child = child_handle;
        } else {
            prev_sibling := entity_get(parent_ptr.last_child);
            print("Prev sibling is invalid handle, something is wrong!\n");
            prev_sibling.next_sibling = child_handle;
            parent_ptr.last_child = child_handle;
        }
    }
    return child_handle;
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

// Entity Helper procs
make_wall :: (left: int, right: int, top: int, bot: int) {
    wall_entity: Entity;
    f_left: float32 = xx left * TILE_SIZE;
    f_right: float32 = (xx right + 1) * TILE_SIZE;
    f_top: float32 = (xx top + 1) * TILE_SIZE;
    f_bot: float32 = xx bot * TILE_SIZE;

    wall_entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
    wall_entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
    wall_entity.shape_kind = .RECTANGLE;
    wall_entity.tag = .WALL;
    wall_entity.props = .RENDERABLE | .STATIC | .COLLIDABLE;
    wall_entity.sprite = *context.atlas.checker;
    entity_add(wall_entity);
}

make_crate :: (c: Coord) {
    crate_entity: Entity;
    half_tile := Vector2.{TILE_SIZE, TILE_SIZE} / 2;
    crate_entity.position = Vector2.{xx c.x * TILE_SIZE, xx c.y * TILE_SIZE} + half_tile;
    crate_entity.extents = Vector2.{TILE_SIZE, TILE_SIZE};
    crate_entity.shape_kind = .RECTANGLE;
    crate_entity.tag = .CRATE;
    crate_entity.props = .RENDERABLE | .COLLIDABLE;
    crate_entity.sprite = *context.atlas.crate;
    entity_add(crate_entity);
}
