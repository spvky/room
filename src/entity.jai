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
    state: Entity_State;
    current_coord: Coord;
    sprite: *Sprite; @ignore_serialize
    handle: Entity_Handle; @ignore_serialize
    parent: Entity_Handle; @ignore_serialize
    first_child: Entity_Handle; @ignore_serialize
    last_child: Entity_Handle; @ignore_serialze
    prev_sibling: Entity_Handle; @ignore_serialize
    next_sibling: Entity_Handle; @ignore_serialize
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
    offset: Vector2;
    movement_delta: Vector2;
    velocity: Vector2;
    rotation: float32;
    shape_kind: Collision_Shape;
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
    PLAYER;
    WALL;
    CRATE;
    GROUND_SENSOR;
}

Entity_Properties :: enum_flags u32 {
    RENDERABLE :: 1 << 0;
    STATIC :: 1 << 1;
    DYNAMIC :: 1 << 2;
    SOLID :: 1 << 3;
    GRAVITY_AFFECTED :: 1 << 4;
    SENSOR :: 1 << 5;
    RELATIVE_POSITION :: 1 << 6;
    RELATIVE_ROTATION :: 1 << 7;
    SELF_PROPELLED :: 1 << 8;
}

Entity_Flags :: enum_flags u32 {
    GROUNDED :: 1 << 0;
    IN_WATER :: 1 << 1;
    POWERED :: 1 << 2;
    PHYSICS_REST :: 1 << 3;
}

Entity_State :: enum u8 {
    STAND;
    MOVING;
    RISING;
    FALLING;
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

entity_has_props :: inline (h: Entity_Handle, props: Entity_Properties) -> bool {
    ent := entity_get(h);
    if !ent {
        print("Attempted to check props on an entity by an invalid handle!\n");
        return false;
    } else {
        return ent.props & props == props;
    }
}

entity_has_props :: inline (e: *Entity, props: Entity_Properties) -> bool {
    if !e {
        print("Attempted to check props on an entity by an invalid pointer!\n");
        return false;
    } else {
        return e.props & props == props;
    }
}

entity_has_flags :: inline (h: Entity_Handle, flags: Entity_Flags) -> bool {
    ent := entity_get(h);
    if !ent {
        print("Attempted to check flags on an entity by an invalid handle!\n");
        return false;
    } else {
        return ent.flags & flags == flags;
    }
}

entity_has_flags :: inline (e: *Entity, flags: Entity_Flags) -> bool {
    if !e {
        print("Attempted to check flags on an entity by an invalid pointer!\n");
        return false;
    } else {
        return e.flags & flags == flags;
    }
}

// Entity Helper procs
make_player :: (c: Coord) {
    player_entity: Entity;
    half_tile := Vector2.{TILE_SIZE, TILE_SIZE} / 2;
    player_entity.position = Vector2.{xx c.x * TILE_SIZE, xx c.y * TILE_SIZE} + half_tile;
    player_entity.shape_kind = .CIRCLE;
    player_entity.radius = TILE_SIZE / 2;
    player_entity.tag = .PLAYER;
    player_entity.props = .RENDERABLE | .GRAVITY_AFFECTED | .DYNAMIC | .SELF_PROPELLED;
    player_entity.sprite = *context.atlas.player_sprite;
    player_entity.movement_delta.x = -1;
    context.player_handle.* = entity_add(player_entity);

    // Ground Sensor Entity
    gse: Entity;
    gse.offset = Vector2.{0, -TILE_SIZE / 2};
    gse.extents = Vector2.{TILE_SIZE * 0.8, TILE_SIZE / 8};
    gse.shape_kind = .RECTANGLE;
    gse.tag = .GROUND_SENSOR;
    gse.props = .SENSOR | .RELATIVE_POSITION | .RELATIVE_ROTATION;
    entity_add_child(context.player_handle.*, gse);
}

make_wall :: (left: int, right: int, top: int, bot: int) {
    wall_entity: Entity;
    f_left: float32 = xx left * TILE_SIZE;
    f_right: float32 = (xx right + 1) * TILE_SIZE;
    f_top: float32 = (xx top + 1) * TILE_SIZE;
    f_bot: float32 = xx bot * TILE_SIZE;

    wall_entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
    wall_entity.shape_kind = .RECTANGLE;
    wall_entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
    wall_entity.tag = .WALL;
    wall_entity.props = .RENDERABLE | .STATIC | .SOLID;
    wall_entity.sprite = *context.atlas.checker;
    entity_add(wall_entity);
}

make_top_wall :: (left: int, right: int, y: int) {
    top_half_entity: Entity;
    f_left: float32 = xx left * TILE_SIZE;
    f_right: float32 = (xx right + 1) * TILE_SIZE;
    f_top: float32 = (xx y + 1) * TILE_SIZE;
    f_bot: float32 = f_top - (TILE_SIZE / 2);

    top_half_entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
    top_half_entity.shape_kind = .RECTANGLE;
    top_half_entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
    top_half_entity.tag = .WALL;
    top_half_entity.props = .RENDERABLE | .STATIC | .SOLID;
    top_half_entity.sprite = *context.atlas.checker;
    entity_add(top_half_entity);
}

make_bot_wall :: (left: int, right: int, y: int) {
    bot_half_entity: Entity;
    f_left: float32 = xx left * TILE_SIZE;
    f_right: float32 = (xx right + 1) * TILE_SIZE;
    f_bot: float32 = xx y * TILE_SIZE;
    f_top: float32 = f_bot + (TILE_SIZE / 2.0);

    bot_half_entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
    bot_half_entity.shape_kind = .RECTANGLE;
    bot_half_entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
    bot_half_entity.tag = .WALL;
    bot_half_entity.props = .RENDERABLE | .STATIC | .SOLID;
    bot_half_entity.sprite = *context.atlas.checker;
    entity_add(bot_half_entity);
}

make_left_wall :: (top: int, bot: int, x: int) {
    left_half_entity: Entity;
    f_left: float32 = xx x * TILE_SIZE;
    f_right: float32 = f_left + (TILE_SIZE / 2.0);
    f_top: float32 = (xx top + 1) * TILE_SIZE;
    f_bot: float32 = xx bot * TILE_SIZE;

    left_half_entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
    left_half_entity.shape_kind = .RECTANGLE;
    left_half_entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
    left_half_entity.tag = .WALL;
    left_half_entity.props = .RENDERABLE | .STATIC | .SOLID;
    left_half_entity.sprite = *context.atlas.checker;
    entity_add(left_half_entity);
}

make_right_wall :: (top: int, bot: int, x: int) {
    right_half_entity: Entity;

    f_right: float32 = (xx x + 1) * TILE_SIZE;
    f_left: float32 = f_right - (TILE_SIZE / 2);
    f_top: float32 = (xx top + 1) * TILE_SIZE;
    f_bot: float32 = xx bot * TILE_SIZE;

    right_half_entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
    right_half_entity.shape_kind = .RECTANGLE;
    right_half_entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
    right_half_entity.tag = .WALL;
    right_half_entity.props = .RENDERABLE | .STATIC | .SOLID;
    right_half_entity.sprite = *context.atlas.checker;
    entity_add(right_half_entity);
}

make_crate :: (c: Coord) {
    crate_entity: Entity;
    half_tile := Vector2.{TILE_SIZE, TILE_SIZE} / 2;
    crate_entity.position = Vector2.{xx c.x * TILE_SIZE, xx c.y * TILE_SIZE} + half_tile;
    crate_entity.shape_kind = .RECTANGLE;
    crate_entity.extents = Vector2.{TILE_SIZE, TILE_SIZE};
    crate_entity.tag = .CRATE;
    crate_entity.props = .RENDERABLE | .SOLID | .GRAVITY_AFFECTED | .DYNAMIC;
    crate_entity.sprite = *context.atlas.crate;
    crate_handle := entity_add(crate_entity);

    // Ground Sensor Entity
    gse: Entity;
    gse.offset = Vector2.{0, -TILE_SIZE / 2};
    gse.extents = Vector2.{TILE_SIZE * 0.95, TILE_SIZE / 8};
    gse.shape_kind = .RECTANGLE;
    gse.tag = .GROUND_SENSOR;
    gse.props = .SENSOR | .RELATIVE_POSITION | .RELATIVE_ROTATION;
    entity_add_child(crate_handle, gse);
}
