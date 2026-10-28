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
aabb_from_entity :: (e: *Entity) -> Bounding_Box {
    bb: Bounding_Box;
    if e.shape_kind == {
    case .RECTANGLE;
        bb.center = e.position;
        bb.extents = e.extents;
    case .CIRCLE;
        bb.center = e.position;
        bb.extents = Vector2.{e.radius, e.radius};
    }
    return bb;
}

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
create_quad_tree_from_entity_manager :: (q: *Quad_Tree_Node, center: Vector2, extents: Vector2, capacity: int, entity_manager := context.entities) {
    q.entities.allocator = temp;
    q.children.allocator = temp;
    q.bounding_box.center = center;
    q.bounding_box.extents = extents;
    q.capacity = capacity;
    for *entity_manager array_add(*q.entities, it);
    if q.entities.count > q.capacity then subdivide(q);
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
                                  bounding_box = Bounding_Box.{center = center + Vector2.{extents.x / 4, extents.y / 4}, extents = extents / 2},
                                  capacity = q.capacity};

            bl.entities.allocator = temp;
            bl.children.allocator = temp;
            for q.entities insert(*bl, it);
            array_add(*q.children, bl);
        }

        {
            br := Quad_Tree_Node.{
                                  bounding_box = Bounding_Box.{center = center + Vector2.{extents.x / 4, extents.y / 4}, extents = extents / 2},
                                  capacity = q.capacity};

            br.entities.allocator = temp;
            br.children.allocator = temp;
            for q.entities insert(*br, it);
            array_add(*q.children, br);
        }
    }
}

query_quad_tree :: (q: *Quad_Tree_Node, range: Bounding_Box) -> [..]*Entity {
    entities: [..]*Entity;
    entities.allocator = temp;
    query_quad_tree_node(q, range, *entities);
    return entities;
}

query_quad_tree_node :: (q: *Quad_Tree_Node, range: Bounding_Box, entities: *[..]*Entity) {
    if aabb_intersects(q.bounding_box, range) {
        if q.subdivided {
            for *q.children query_quad_tree_node(it, range, entities);
        } else {
            for q.entities array_add(entities, it);
        }
    }
}

quadtree_stats :: (q: *Quad_Tree_Node) -> Quad_Tree_Stats {
    stats: Quad_Tree_Stats;
    entities: [..]*Entity;
    defer array_free(entities);
    entities.allocator = temp;
    node_count: int;
    count_quadtree_node(q, *entities, *node_count);
    stats.entities = entities.count;
    stats.nodes = node_count;
    return stats;
}

count_quadtree_node :: (q: *Quad_Tree_Node, entities: *[..]*Entity, node_count: *int) {
    if q.subdivided {
        count_quadtree_node(q, entities, node_count);
    } else {
        for q.entities array_add_if_unique(entities, it);
        node_count.* += 1;
    }
}
