Bounding_Box :: struct {
    center: Vector2;
    extents: Vector2;
}

Quad_Tree_Node :: struct {
    bounding_box: Bounding_Box;
    capacity: int;
    subdivided: bool;
    entities: [..]*Entity;
    children: [..]Quad_Tree_Node;
}

Quad_Tree_Stats :: struct {
    entities: int;
    nodes: int;
}

// Ignores rotation

aabb_intersects :: (a: Bounding_Box, b: Bounding_Box) -> bool #expand {
    ha := a.extents / 2;
    hb := b.extents / 2;
    return !(
             b.center.x - hb.x > a.center.x + ha.x ||
             b.center.x + hb.x < a.center.x - ha.x ||
             b.center.y - hb.y > a.center.y + ha.y ||
             b.center.y + hb.y < a.center.y - ha.y);
}

// Creates a quad tree and inserts entities from the passed entity manager, if the number of entities is greater than the capacity, does the initial subdivision
build_collision_tree :: (center: Vector2, extents: Vector2, capacity: int, entity_manager := context.entities, allocator := temp) {
    if context.collision_tree then free(context.collision_tree);
    context.collision_tree = New(Quad_Tree_Node);
    q := context.collision_tree;
    q.bounding_box.center = center;
    q.bounding_box.extents = extents;
    q.capacity = capacity;
    for *entity_manager {
        if entity_has_props(it, .PHYSICAL) then array_add(*q.entities, it);
    }
    if q.entities.count > q.capacity {
        subdivide(q);
    }
}

insert :: (q: *Quad_Tree_Node, e: *Entity) {
    aabb := aabb_from_entity(e);
    if aabb_intersects(q.bounding_box, aabb) {
        if q.subdivided {
            for *q.children insert(it, e);
        } else {
            array_add(*q.entities, e);
            if q.entities.count > q.capacity then subdivide(q);
        }
    }
}

subdivide :: (q: *Quad_Tree_Node) {
    defer q.subdivided = true;
    if !q.subdivided {
        using q.bounding_box;

        {
            tl := Quad_Tree_Node.{
                                  bounding_box = Bounding_Box.{center = center + Vector2.{-extents.x / 4, extents.y / 4}, extents = extents / 2},
                                  capacity = q.capacity};
            tl.entities.allocator = temp;
            tl.children.allocator = temp;
            for q.entities insert(*tl, it);
            array_add(*q.children, tl);
        }

        {
            tr := Quad_Tree_Node.{
                                  bounding_box = Bounding_Box.{center = center + Vector2.{extents.x / 4, extents.y / 4}, extents = extents / 2},
                                  capacity = q.capacity};

            tr.entities.allocator = temp;
            tr.children.allocator = temp;
            for q.entities insert(*tr, it);
            array_add(*q.children, tr);
        }

        {
            bl := Quad_Tree_Node.{
                                  bounding_box = Bounding_Box.{center = center + Vector2.{-extents.x / 4, -extents.y / 4}, extents = extents / 2},
                                  capacity = q.capacity};

            bl.entities.allocator = temp;
            bl.children.allocator = temp;
            for q.entities insert(*bl, it);
            array_add(*q.children, bl);
        }

        {
            br := Quad_Tree_Node.{
                                  bounding_box = Bounding_Box.{center = center + Vector2.{extents.x / 4, -extents.y / 4}, extents = extents / 2},
                                  capacity = q.capacity};

            br.entities.allocator = temp;
            br.children.allocator = temp;
            for q.entities insert(*br, it);
            array_add(*q.children, br);
        }
    }
}

query_tree :: (q: *Quad_Tree_Node, entities: *[..]*Entity, range: Bounding_Box, include: Entity_Properties = 0, exclude: Entity_Properties = 0) {
    query_quad_tree_node(q, range, entities, include, exclude);
}

query_quad_tree_node :: (q: *Quad_Tree_Node, range: Bounding_Box, entities: *[..]*Entity, include: Entity_Properties, exclude: Entity_Properties) {
    should_include := include != 0;
    should_exclude := exclude != 0;
    if aabb_intersects(q.bounding_box, range) {
        if q.subdivided {
            for *q.children query_quad_tree_node(it, range, entities, include, exclude);
        } else {
            for q.entities {
                should_return: bool = true;
                if should_include {
                    should_return = entity_has_props(it, include) && should_return;
                }
                if should_exclude {
                    should_return = !entity_has_props(it, exclude) && should_return;
                }
                if should_return then array_add(entities, it);
            }
        }
    }
}

quadtree_stats :: (q: *Quad_Tree_Node) -> Quad_Tree_Stats {
    stats: Quad_Tree_Stats;
    entities: [..]*Entity;
    entities.allocator = temp;
    array_reserve(*entities, 200);
    node_count: int;
    count_quadtree_node(q, *entities, *node_count);
    stats.entities = entities.count;
    stats.nodes = node_count;
    array_free(entities);
    return stats;
}

count_quadtree_node :: (q: *Quad_Tree_Node, entities: *[..]*Entity, node_count: *int) {
    // Pointer to entities won't work here because it will move if it grows
    if q.subdivided {
        for *q.children count_quadtree_node(it, entities, node_count);
    } else {
        for q.entities array_add_if_unique(entities, it);
        node_count.* += 1;
    }
}

draw_quadtree :: (q: *Quad_Tree_Node) {
    if q {
        if q.subdivided {
            for q.children {
                a := *it;
                draw_quadtree(*it);
            }
        }
        p: [4]Vector2;
        using q.bounding_box;
        pos, _ := cam_relative_pos_extents(center, .{});
        he := extents / 2;
        _: Vector2;
        p[0] = pos + Vector2.{-he.x, he.y};
        p[1] = pos + Vector2.{-he.x, -he.y};
        p[2] = pos + Vector2.{he.x, -he.y};
        p[3] = pos + Vector2.{he.x, he.y};
        thickness := 0.5;
        draw_line(p[0], p[1], thickness = thickness);
        draw_line(p[1], p[2], thickness = thickness);
        draw_line(p[2], p[3], thickness = thickness);
        draw_line(p[3], p[0], thickness = thickness);
    }
}
