calculate_water_flow :: (entity: *Entity) {
    cast_hit, cast_did_hit := circle_cast(entity.position, .{0, -1}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
    if cast_did_hit {
        horizontal_origin := cast_hit.shape_position_at_toi + (cast_hit.collision.depth * Vector2.{0, 1});
        left_cast_hit, left_cast_did_hit := circle_cast(horizontal_origin, .{-1, 0}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
        right_cast_hit, right_cast_did_hit := circle_cast(horizontal_origin, .{1, 0}, TILE_SIZE / 4, TILE_SIZE / 2, 100, .WATER_COLLISION, true);
    }
}

horizontal_water_flow :: () {
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


*/
