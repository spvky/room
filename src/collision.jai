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
