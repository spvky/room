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
    relative_room_coord: Coord;
    current_coord: Coord;
    text_message: Display_Message;
    render_kind: Entity_Render_Kind;
    render_extents: Vector2;
    room_pickup_hash: u32;
    animation_player: Sprite_Animation_Player;
    #overlay (animation_player) sprite_sheet: Sprite_Sheet;
    #overlay (animation_player) sprite: Sprite;
    handle: Entity_Handle;
    parent: Entity_Handle;
    first_child: Entity_Handle;
    last_child: Entity_Handle;
    prev_sibling: Entity_Handle;
    next_sibling: Entity_Handle;
    tail: [16]u8;
}

Entity_Render_Kind :: enum u8 {
    ANIMATION_PLAYER;
    SPRITE_SHEET;
    SPRITE;
}

Entity_Handle :: struct {
    index: u32;
    generation: u32;
}

operator == :: (a: Entity_Handle, b: Entity_Handle) -> bool {
    return a.index == b.index && a.generation == b.generation;
}

handle_compare :: (a: Entity_Handle, b: Entity_Handle) -> bool {
    return a.index == b.index && a.generation == b.generation;
}

handle_hash :: (a: Entity_Handle) -> u32 {return sdbm_hash(*a, size_of(Entity_Handle));}

hash_handle_pair :: (a: Entity_Handle, b: Entity_Handle) -> u64 {
    ahash := handle_hash(a);
    bhash := handle_hash(b);
    lower := ifx ahash < bhash then ahash else bhash;
    upper := ifx ahash < bhash then bhash else ahash;
    base := cast(u64)lower;
    final := base << 32 | upper;
    return final;
}

Rigidbody :: struct {
    position: Vector2;
    offset: Vector2;
    movement_delta: Vector2;
    velocity: Vector2;
    inherited_velocity: Vector2;
    rotation: float32;
    shape_kind: Collision_Shape;
    extents: Vector2;
    ray: Ray;
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
    WALL_CASTER;
    GEAR;
    LEFT_SENSOR;
    RIGHT_SENSOR;
    SWITCH_BLOCK;
    LEVER;
    BUTTON;
    SWITCH_BLOCK_OFF_TARGET;
    SWITCH_BLOCK_ON_TARGET;
    ASSEMBLER;
    ROOM_PICKUP;
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
    RAY_CASTER :: 1 << 9;
    ANIMATED :: 1 << 10;
    DEATH_ZONE :: 1 << 11;
    UNSTABLE :: 1 << 12;
    KINEMATIC :: 1 << 13;
    INTERACTABLE :: 1 << 14;
    FOREGROUND :: 1 << 15;
    CONDUIT :: 1 << 16;
    TEXT_DISPLAY :: 1 << 17;
    PICKUP :: 1 << 18;
    PRESSES_BUTTONS :: 1 << 19;
}

Entity_Flags :: enum_flags u32 {
    GROUNDED :: 1 << 0;
    IN_WATER :: 1 << 1;
    POWERED :: 1 << 2;
    PHYSICS_REST :: 1 << 3;
    LEFT_BLOCKED :: 1 << 4;
    RIGHT_BLOCKED :: 1 << 5;
    TEXT_ACTIVE :: 1 << 6;
}

Entity_Message :: enum_flags u32 {
    RAY_HIT_SOLID :: 1 << 0;
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
    e.count = 0;
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
        entity := entity_get(handle, e = e);
        if entity_valid(entity.first_child, e = e) {
            current_child := entity_get(entity.first_child, e = e);

            while entity_valid(current_child.next_sibling, e = e) {
                entity_remove(current_child.next_sibling, e = e);
            }

            entity_remove(entity.first_child, e = e);
        }

        if entity_valid(entity.next_sibling) {
            next_sibling := entity_get(entity.next_sibling, e = e);
            next_sibling.prev_sibling = entity.prev_sibling;
        }

        if entity_valid(entity.prev_sibling, e = e) {
            prev_sibling := entity_get(entity.prev_sibling, e = e);
            prev_sibling.next_sibling = entity.next_sibling;
        }

        if !entity_valid(entity.prev_sibling, e = e) && entity_valid(entity.parent, e = e) {
            parent := entity_get(entity.parent, e = e);
            parent.first_child = entity.next_sibling;
        }

        array_add(*e.freelist, handle);
        e.items[handle.index] = .{};
        e.count -= 1;
    }
}

entity_valid :: (handle: Entity_Handle, e: *Entity_Manager = context.entities) -> bool {
    if handle == .{0, 0} return false;
    return entity_get(handle, e = e) != null;
}

entity_add_child :: (parent_handle: Entity_Handle, child_entity: Entity, e: *Entity_Manager = context.entities) -> Entity_Handle {
    is_extra_manager := e != context.entities;
    if is_extra_manager print("Adding Special Child!\n");
    child_handle: Entity_Handle;
    // check if parent is still valid
    if entity_valid(parent_handle, e = e) {
        if is_extra_manager print("Pre-add count: %\n", e.count);
        child_handle = entity_add(child_entity, e = e);
        if is_extra_manager print("Post-add count: %\n", e.count);
        if !entity_valid(child_handle, e) {
            print("Tried to add entity child and still have a null handle, something is wrong!\n");
            return child_handle;
        }

        parent_ptr := entity_get(parent_handle, e = e);
        child_ptr := entity_get(child_handle, e = e);
        child_ptr.parent = parent_handle;

        // you can also keep a handle to the last child to avoid iterating the list when inserting
        // assert((parent_ptr.first_child == NULL_HANDLE && parent_ptr.last_child == NULL_HANDLE) ||
        //        (parent_ptr.first_child != NULL_HANDLE && parent_ptr.last_child != NULL_HANDLE));

        child_ptr.prev_sibling = parent_ptr.last_child;
        if !entity_valid(parent_ptr.last_child, e = e) {
            parent_ptr.first_child = child_handle;
            parent_ptr.last_child = child_handle;
        } else {
            prev_sibling := entity_get(parent_ptr.last_child, e = e);
            prev_sibling.next_sibling = child_handle;
            child_ptr.next_sibling = parent_ptr.first_child;
            parent_ptr.last_child = child_handle;
        }
    }
    return child_handle;
}

for_expansion :: (e: *Entity_Manager, body: Code, flags: For_Flags) #expand {
    // print("Looping over entity manager count is %\n", e.count);
    for index: 0..e.items.count - 1 {
        // print("ENTGUY IDX: %\n", e.items[index].handle.index);
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

// Returns the world coord as a Vector2(Bottom_Left_Origin)
world_coord_to_vector2 :: (c: Coord) -> Vector2 #expand {
    return c * Vector2.{TILE_SIZE, TILE_SIZE};
}

make_wall :: (left: int, right: int, top: int, bot: int, kind: Collision_Tile) {
    if kind == {
    case .WALL;
        entity: Entity;
        f_left: float32 = xx left * TILE_SIZE;
        f_right: float32 = (xx right + 1) * TILE_SIZE;
        f_top: float32 = (xx top + 1) * TILE_SIZE;
        f_bot: float32 = xx bot * TILE_SIZE;

        entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
        entity.tag = .WALL;
        entity.props = .RENDERABLE | .STATIC | .SOLID;
        entity.render_kind = .SPRITE;
        entity.sprite = sprite(1);
        entity.render_extents = Vector2.{f_right - f_left, f_top - f_bot};
        entity_add(entity);
    case .TOP_HALF;
        entity: Entity;
        f_left: float32 = xx left * TILE_SIZE;
        f_right: float32 = (xx right + 1) * TILE_SIZE;
        f_top: float32 = (xx top + 1) * TILE_SIZE;
        f_bot: float32 = f_top - (TILE_SIZE / 2);

        entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
        entity.tag = .WALL;
        entity.props = .RENDERABLE | .STATIC | .SOLID;
        entity.render_kind = .SPRITE;
        entity.sprite = sprite(1);
        entity.render_extents = Vector2.{f_right - f_left, f_top - f_bot};
        entity_add(entity);
    case .BOT_HALF;
        entity: Entity;
        f_left: float32 = xx left * TILE_SIZE;
        f_right: float32 = (xx right + 1) * TILE_SIZE;
        f_bot: float32 = xx top * TILE_SIZE;
        f_top: float32 = f_bot + (TILE_SIZE / 2.0);

        entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
        entity.tag = .WALL;
        entity.props = .RENDERABLE | .STATIC | .SOLID;
        entity.render_kind = .SPRITE;
        entity.sprite = sprite(1);
        entity.render_extents = Vector2.{f_right - f_left, f_top - f_bot};
        entity_add(entity);
    case .LEFT_HALF;
        entity: Entity;
        f_left: float32 = xx left * TILE_SIZE;
        f_right: float32 = f_left + (TILE_SIZE / 2.0);
        f_top: float32 = (xx top + 1) * TILE_SIZE;
        f_bot: float32 = xx bot * TILE_SIZE;

        entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
        entity.tag = .WALL;
        entity.props = .RENDERABLE | .STATIC | .SOLID;
        entity.render_kind = .SPRITE;
        entity.sprite = sprite(1);
        entity.render_extents = Vector2.{f_right - f_left, f_top - f_bot};
        entity_add(entity);
    case .RIGHT_HALF;
        entity: Entity;

        f_right: float32 = (xx left + 1) * TILE_SIZE;
        f_left: float32 = f_right - (TILE_SIZE / 2);
        f_top: float32 = (xx top + 1) * TILE_SIZE;
        f_bot: float32 = xx bot * TILE_SIZE;

        entity.position = Vector2.{(f_left + f_right) / 2, (f_top + f_bot) / 2};
        entity.shape_kind = .RECTANGLE;
        entity.extents = Vector2.{f_right - f_left, f_top - f_bot};
        entity.tag = .WALL;
        entity.props = .RENDERABLE | .STATIC | .SOLID;
        entity.render_kind = .SPRITE;
        entity.sprite = sprite(1);
        entity.render_extents = Vector2.{f_right - f_left, f_top - f_bot};
        entity_add(entity);
    }
}
