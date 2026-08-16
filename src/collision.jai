Collision :: struct {
    normal: Vector2;
    depth: float32;
}
Collision_Mode :: enum {
    SAT;
    AABB;
}

Interval :: struct {
    min: float32;
    max: float32;
}

overlap :: (a: Interval, b: Interval) -> bool, float32 {
    overlaps := a.min <= b.max && b.min <= a.max;
    if !overlaps {
        return false, -1;
    }

    amount: float32 = min(a.max, b.max) - max(a.min, b.min);
    return overlaps, amount;
}

Axis_Interval_Pair :: struct {
    axis: Vector2;
    interval: Interval;
}

Edge :: struct {
    normal: Vector2;
    center: Vector2;
}

Static_Collision_Table :: Table(Entity_Handle, [..]Axis_Interval_Pair, given_hash_function = handle_hash, given_compare_function = handle_compare);

#add_context static_collision_table: *Static_Collision_Table;

init_static_collision_table :: () {
    if !context.static_collision_table {
        context.static_collision_table = New(Static_Collision_Table);
    }
}

rebuild_static_collision_table :: () {
    table_reset_keeping_memory(context.static_collision_table);
    for *context.entities {
        if it.props & .STATIC == .STATIC {
            ai_pairs: [..]Axis_Interval_Pair;
            // For now just storing X and Y axis for static entities, may eventually support ramps
            ix := project_rigidbody_along_axis(it, Vector2.{1, 0});
            iy := project_rigidbody_along_axis(it, Vector2.{0, 1});
            array_add(*ai_pairs, Axis_Interval_Pair.{axis = Vector2.{1, 0}, interval = ix});
            array_add(*ai_pairs, Axis_Interval_Pair.{axis = Vector2.{0, 1}, interval = iy});
            table_add(context.static_collision_table, it.handle, ai_pairs);
        }
    }
}

dynamic_vs_static_collision_test :: (d: *Entity, s: *Entity, mode := Collision_Mode.SAT) -> Collision, bool {
    collision: Collision;
    if mode == {
    case .AABB;
    case .SAT;
        static_ai_pairs := table_find_pointer(context.static_collision_table, d.handle);
        if static_ai_pairs != null {
            axes: [..]Vector2;
            min_depth: float32 = FLOAT32_MAX;
            axes.allocator = temp;
            save_rigidbody_axes(d, *axes);
            if axes.count > 0 {
                for axes {
                    ia := project_rigidbody_along_axis(d, it);
                    ib := project_rigidbody_along_axis(s, it);
                    overlaps, depth := overlap(ia, ib);
                    if overlaps {
                        if depth < min_depth {
                            min_depth = depth;
                            collision.depth = depth;
                            collision.normal = it;
                        }
                    } else {
                        return collision, false;
                    }
                }
            }

            for static_ai_pairs.* {
                id := project_rigidbody_along_axis(d, it.axis);
                is := it.interval;
                overlaps, depth := overlap(id, is);
                if overlaps {
                    if depth < min_depth {
                        min_depth = depth;
                        collision.depth = depth;
                        collision.normal = it.axis;
                    }
                } else {
                    return collision, false;
                }
            }
        } else {
            print("Tried to collide against missing static entity, skipping!\n");
            return collision, false;
        }
    }

    return collision, true;
}

dynamic_vs_dynamic_collision_test :: (a: *Rigidbody, b: *Rigidbody, mode := Collision_Mode.SAT) -> Collision, bool {
    collision: Collision;
    if a.shape_kind == .CIRCLE && b.shape_kind == .CIRCLE {
        dist := distance(a.position, b.position);
        radii := a.radius + b.radius;
        if dist < radii {
            normal := normalize(b.position - a.position);
            depth := radii - dist;
            return Collision.{normal, depth}, true;
        } else {
            return collision, false;
        }
    }
    if mode == {
    case .AABB;
    case .SAT;
        axes: [..]Vector2;
        axes.allocator = temp;
        save_rigidbody_axes(a, *axes);
        save_rigidbody_axes(b, *axes);

        min_depth: float32 = FLOAT32_MAX;
        for axes {
            ia := project_rigidbody_along_axis(a, it);
            ib := project_rigidbody_along_axis(b, it);
            overlaps, depth := overlap(ia, ib);
            if overlaps {
                if depth < min_depth {
                    min_depth = depth;
                    collision.depth = depth;
                    collision.normal = it;
                }
            } else {
                return collision, false;
            }
        }

        // Just axis alligned, but will support rotation
    }
    return collision, true;
}

// SAT
project_rigidbody_along_axis :: (rb: *Rigidbody, a: Vector2) -> Interval {
    // Minimum and maximum dot products along the axis
    min := FLOAT32_MAX;
    max := -FLOAT32_MAX;
    if rb.shape_kind == {
    case .RECTANGLE;
        // Points to test
        p: [4]Vector2;
        h := rb.extents / 2;
        p[0] = rb.position - h;
        p[1] = rb.position + h;
        p[2] = rb.position + .{-h.x, h.y};
        p[3] = rb.position + .{h.x, -h.y};

        for p {
            dot := dot_product(it, a);
            min = ifx dot < min then dot else min;
            max = ifx dot > max then dot else max;
        }
    case .CIRCLE;
        min = dot_product(rb.position - (rb.radius * a), a);
        max = dot_product(rb.position + (rb.radius * a), a);
    case .CAPSULE;
    }
    return Interval.{min, max};
}

save_rigidbody_axes :: (rb: *Rigidbody, axes: *[..]Vector2) {
    if rb.shape_kind == .CIRCLE || rb.shape_kind == .CAPSULE return;
    if rb.rotation == 0 {
        if axes.count == 0 {
            array_add(axes, Vector2.{1, 0});
            array_add(axes, Vector2.{1, 1});
        }
    } else {
    }
}
// AABB
static_rectangle_nearest_point :: (p: Vector2, rb: *Rigidbody) -> Vector2 {
    min_x, max_x := rb.position.x - (rb.extents.x / 2), rb.position.x + (rb.extents.x / 2);
    min_y, max_y := rb.position.y - (rb.extents.y / 2), rb.position.y + (rb.extents.y / 2);
    ret: Vector2;
    ret.x = clamp(p.x, min_x, max_x);
    ret.y = clamp(p.y, min_y, max_y);
    return ret;
}

// Return a resizable array with the edges (center and normal) of a collision shape, using the temporary allocator, returns an empty array if the thing is not a collider
// get_shape_edges :: (thing: *Thing) -> [..]Edge {
//     edges: [..]Edge;
//     edges.allocator = temp;
//     if thing.kind == .COLLISION {
//         if thing.collision_shape == {
//         case .AABB;
// 
//         case .TRIANGLE;
//             ab := thing.triangle_verts[1] - thing.triangle_verts[0];
//             n1 := normalize(Vector2.{ab.y, -ab.x});
//             if dot(Vector2.{0, 0}, n1) > 0 then n1 = -n1;
//             ab_center := (thing.triangle_verts[0] + thing.triangle_verts[1]) / 2;
//             array_add(*edges, .{normal = n1, center = ab_center});
// 
//             bc := thing.triangle_verts[2] - thing.triangle_verts[1];
//             n2 := normalize(Vector2.{bc.y, -bc.x});
//             if dot(Vector2.{0, 0}, n2) > 0 then n2 = -n2;
//             bc_center := (thing.triangle_verts[1] + thing.triangle_verts[2]) / 2;
//             array_add(*edges, .{normal = n2, center = bc_center});
// 
//             ca := thing.triangle_verts[0] - thing.triangle_verts[2];
//             n3 := normalize(Vector2.{ca.y, -ca.x});
//             if dot(Vector2.{0, 0}, n3) > 0 then n3 = -n3;
//             ca_center := (thing.triangle_verts[2] + thing.triangle_verts[0]) / 2;
//             array_add(*edges, .{normal = n3, center = ca_center});
// 
//         case .POLYGON;
//             ab := thing.polygon_verts[1] - thing.polygon_verts[0];
//             n1 := normalize(Vector2.{ab.y, -ab.x});
//             if dot(Vector2.{0, 0}, n1) > 0 then n1 = -n1;
//             ab_center := (thing.polygon_verts[0] + thing.polygon_verts[1]) / 2;
//             array_add(*edges, .{normal = n1, center = ab_center});
// 
//             bc := thing.polygon_verts[2] - thing.polygon_verts[1];
//             n2 := normalize(Vector2.{bc.y, -bc.x});
//             if dot(Vector2.{0, 0}, n2) > 0 then n2 = -n2;
//             bc_center := (thing.polygon_verts[1] + thing.polygon_verts[2]) / 2;
//             array_add(*edges, .{normal = n2, center = bc_center});
// 
//             cd := thing.polygon_verts[3] - thing.polygon_verts[2];
//             n3 := normalize(Vector2.{cd.y, -cd.x});
//             if dot(Vector2.{0, 0}, n3) > 0 then n3 = -n3;
//             cd_center := (thing.polygon_verts[2] + thing.polygon_verts[3]) / 2;
//             array_add(*edges, .{normal = n3, center = cd_center});
// 
//             da := thing.polygon_verts[0] - thing.polygon_verts[3];
//             n4 := normalize(Vector2.{da.y, -da.x});
//             if dot(Vector2.{0, 0}, n4) > 0 then n4 = -n4;
//             da_center := (thing.polygon_verts[3] + thing.polygon_verts[0]) / 2;
//             array_add(*edges, .{normal = n4, center = da_center});
//         }
//     }
//     return edges;
// }
