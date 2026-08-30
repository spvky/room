Collision :: struct {
    normal: Vector2;
    depth: float32;
}
Collision_Mode :: enum {
    SAT;
    AABB;
}

Ray :: struct {
    direction: Vector2;
    max_toi: float32;
    hit: bool;
    hit_point: Vector2;
    hit_handle: Entity_Handle;
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

rigidbody_edges :: (r: *Rigidbody) -> [4][2]Vector2, bool {
    edges: [4][2]Vector2;

    if r.shape_kind == .RECTANGLE {
        half_x := r.extents.x / 2;
        half_y := r.extents.y / 2;

        p: [4]Vector2;
        p[0] = .{(-half_x) * cos(r.rotation) - (half_y) * sin(r.rotation), (-half_x) * sin(r.rotation) + (half_y) * cos(r.rotation)} + r.position;
        p[1] = .{(-half_x) * cos(r.rotation) - (-half_y) * sin(r.rotation), (-half_x) * sin(r.rotation) + (-half_y) * cos(r.rotation)} + r.position;
        p[2] = .{(half_x) * cos(r.rotation) - (-half_y) * sin(r.rotation), (half_x) * sin(r.rotation) + (-half_y) * cos(r.rotation)} + r.position;
        p[3] = .{(half_x) * cos(r.rotation) - (half_y) * sin(r.rotation), (half_x) * sin(r.rotation) + (half_y) * cos(r.rotation)} + r.position;

        edges[0] = .[p[0], p[1]];
        edges[1] = .[p[1], p[2]];
        edges[2] = .[p[2], p[3]];
        edges[3] = .[p[3], p[0]];
        return edges, true;
    }

    return edges, false;
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
        static_ai_pairs := table_find_pointer(context.static_collision_table, s.handle);
        // print("Fetching cached collision data for handle: %\n", d.handle);
        if static_ai_pairs != null {
            axes: [..]Vector2;
            min_depth: float32 = FLOAT32_MAX;
            axes.allocator = temp;
            store_rigidbody_axes(d, *axes);
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
        store_rigidbody_axes(a, *axes);
        store_rigidbody_axes(b, *axes);

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

line_intersection_test :: (a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> Vector2, bool {
    o1 := line_orientation(a, b, c);
    o2 := line_orientation(a, b, d);
    o3 := line_orientation(c, d, a);
    o4 := line_orientation(c, d, b);

    // If orientations don't match, we should intersect at some point
    if (o1 != o2 && o3 != o4) {
        a1 := b.y - a.y;
        b1 := a.x - b.x;
        c1 := a1 * a.x + b1 * a.y;

        a2 := d.y - c.y;
        b2 := c.x - d.x;
        c2 := a2 * c.x + b2 * d.y;

        determinant := a1 * b2 - a2 * b1;

        if determinant != 0 {
            p: Vector2;
            p.x = (c1 * b2 - c2 * b1) / determinant;
            p.y = (a1 * c2 - a2 * c1) / determinant;
            // print("RAYCAST HIT! % - %\n", a, b);
            return p, true;
        }
    }

    return Vector2.{}, false;
}

line_orientation :: (a: Vector2, b: Vector2, c: Vector2) -> s8 {
    val := (b.y - a.y) * (c.x - b.x) - (b.x - a.x) * (c.y - b.y);
    if val == 0 return 0;
    result: s8 = ifx val > 0.0 then cast(s8)1 else cast(s8)2;
    return result;
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

store_rigidbody_axes :: (rb: *Rigidbody, axes: *[..]Vector2) {
    if rb.shape_kind == .CIRCLE || rb.shape_kind == .CAPSULE return;
    if rb.rotation == 0 {
        if axes.count == 0 {
            array_add(axes, Vector2.{1, 0});
            array_add(axes, Vector2.{0, 1});
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
