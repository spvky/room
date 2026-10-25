calculate_water_flow :: (entity: *Entity) {
    cast_hit, cast_did_hit := circle_cast(entity.position, .{0, -1}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
    if cast_did_hit {
        hit_water_node := entity_has_props(cast_hit.hit_entity, .WATER_NODE);
        if hit_water_node {
            // Transfer the water
        } else {
            print("Making a ground node\n");
            new_node_origin := cast_hit.shape_position_at_toi + (cast_hit.collision.depth * Vector2.{0, 1});
            make_water_node(new_node_origin, true);
        }
        // horizontal_origin := cast_hit.shape_position_at_toi + (cast_hit.collision.depth * Vector2.{0, 1});
        // left_cast_hit, left_cast_did_hit := circle_cast(horizontal_origin, .{-1, 0}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
        // right_cast_hit, right_cast_did_hit := circle_cast(horizontal_origin, .{1, 0}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
    }
}

handle_water_pipes :: () {
    for *context.entities {
        if it.tag != .WATER_PIPE continue;
        calculate_water_flow(it);
    }
}

handle_ground_water_nodes :: () {
    for *context.entities {
        if it.tag != .WATER_NODE_GROUND continue;
        left_cast_hit, left_cast_did_hit := circle_cast(it.position, .{-1, 0}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
        if left_cast_did_hit {
        }

        right_cast_hit, right_cast_did_hit := circle_cast(it.position, .{1, 0}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
        if right_cast_did_hit {
        }
    }
}

handle_air_water_nodes :: () {
}

make_water_node :: (position: Vector2, is_grounded_node: bool, e := context.entities) {
    entity: Entity;

    entity.position = position + .{0, TILE_SIZE / 4};
    entity.shape_kind = .CIRCLE;
    entity.radius = TILE_SIZE / 2;
    entity.props = .WATER_COLLISION | .WATER_NODE | .RENDERABLE;

    if is_grounded_node {
        entity.tag = .WATER_NODE_GROUND;

        new_node_handle := entity_add(entity, e = e);

        volume_entity: Entity;
        volume_entity.tag = .WATER_VOLUME;
        volume_entity.shape_kind = .RECTANGLE;
        entity_add_child(new_node_handle, volume_entity, e = e);
    } else {
        entity.tag = .WATER_NODE_FALLING;
        entity_add(entity, e = e);
    }
}

// Design:
/*
	Thinking about a design that involves

	Pipe, Water_Node, Water_Volume

	Pipe flows downward

	every time a stream hits a surface/falls spawn another water node, when water nodes terminate, create a water volume
	add a `misc_value: float` field to entities, use that to track the current water flowing in to a node, and the nodes flow forward with the full amount, water volumes adjust their height based on the water amount

	Design the system around the fact that it will eventually be correct

	For a pipe:
	- Flow down, once we hit something that collides:
	- 1: if it is a water node, transfer all of my misc value
	- 2: if not a water node, create water nodes splitting my misc value and heading right and left

	-- Maybe when we collide vertically we just make a single node that casts in both directions, if it's blocked on both sides it becomes a water volume

	For a node:
	- Flow in your direction
	- 1: if horizontal and we collide
	-- a: if we hit a non-node, set blocked flag
	-- b: if we hit a node, transfer value
	- 2: if we fall
	-- a: create a new node flowing downard
	- 3: if vertical
	-- a: if we hit a non-node, create water nodes splitting my misc value and heading right and left
	-- b: if we hit a node, transfer our value

	for a water volume:
	adjust extents based on misc value which has been poured in from nodes
	
	Is there a way to use entity relationships to refine this?

	the physical approach seems like it might be better but could run in to weird inconsistencies

	one benefit of the physical approach is that it may be easier to equalize water in real time


maybe use events to handle water transfers, run the flow step, create events of handle + water amount, the only issue is that there are easily cases where this loop becomes hard to solve, if we are trying to resolve immediately -- the answer could be as above to let things take a few frames to equalize, but in that case wiping values to 0 each frame will not make sense, I think it makes more sense to design it in a way were it is not ruined if some flow is missed in a frame, make everything just flow forward and resolve

| _ _ P _ _ _ _ _ _ _ |  In this diagram:
| _ _ _ _ _ _ _ _ _ _ |		1, 5, and 6 are of the volume type
| 2 _ 1 _ 3 _ _ _ _ _ |		2,3,4 are of the node type as they don't really store any flow
| _ w w w _ _ _ _ _ _ |		on their own, but are part of the same circuit
| 5 _ _ _ 4 _ _ _ _ _ |
| w w w w _ _ _ _ _ _ |
| _ _ _ _ _ _ _ _ _ _ |
| _ _ _ _ _ _ _ _ _ _ |
| _ _ _ _ _ _ _ _ _ _ |
| _ _ _ _ 6 _ _ _ _ _ |
| w w w w w w w w w w |

Might make sense for the Pipe to generate a constant amount of water,
in which case, should the nodes pass everything along? and in that case maybe volumes drain a percentage every cycle?
It's okay for the water level to ebb and flow a bit, but It does need to remain reasonably consistent, within less than half of TILE_SIZE

Pipe | Falling_Water_Node | Grounded_Water_Node
Pipe - Source of water, pushes constant amount
Grounded_Water_Node - Created when a (Pipe/Falling_Water_Node) collides with the ground, Pushes water in both directions, if it's blocked on both sides begins to expand into a volume
Falling_Water_Node - Created when water from a  Grounded_Node would fall off of a cliff, Mainly serves so that we don't have to calculate a dropoff every cycle

Flow Management:

Global Consts: 
	-Water transfer rate: float
	-Water drain rate: float

If the water system takes a bit of time to equalize, could simulate it for a second or something on bake to ensure it's in a settled state once a bake finishes


*/
