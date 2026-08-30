World :: struct {
    collision: [WORLD_WIDTH * WORLD_HEIGHT]Collision_Tile;
    entities: [WORLD_WIDTH * WORLD_HEIGHT]Entity_Tile;
    rooms: [MAP_WIDTH * MAP_HEIGHT]Map_Room;
    room_effects: [..]Room_Effect;
}

Room_Effect :: struct {
    effect: Effect_Rune;
    rooms: [..]Coord;
}

Room_Modifier :: enum {
    RAIN;
}

bake_world :: () {
    write_room_cards_to_world();
    open_map_exits();
    generate_world_map_png("assets/world.png");
    parse_entities_from_tiles();
    rebuild_static_collision_table();
    parse_runes();
    print("Found % static entities while re-building the static collision table!\n", context.static_collision_table.count);
}

reset_world_tilemap :: () {
    world := context.world;
    for x: 0..WORLD_WIDTH - 1 {
        for y: 0..WORLD_HEIGHT - 1 {
            idx := coord_to_index(.{xx x, xx y}, .WORLD);
            world.collision[idx] = .BLANK;
            world.entities[idx] = .EMPTY;
        }
    }
}

parse_runes :: () {
    world := context.world;
    for <y: 0..MAP_HEIGHT - 1 {
        for x: 0..MAP_WIDTH - 1 {
            coord := Coord.{xx x, xx y};
            idx := coord_to_index(coord, .MAP);
            room := world.rooms[idx];
            if !room.exists continue;
            x_coord := coord;
            x_rune: Rune;
            x_coords: [..]Coord;
            y_coords: [..]Coord;
            // If the moving
            while x_coord.x < MAP_WIDTH - 1 && world.rooms[coord_to_index(x_coord, .MAP)].exists && !world.rooms[coord_to_index(x_coord, .MAP)].rune_parsed_x {
                array_add(*x_coords, x_coord);
                x_rune += world.rooms[coord_to_index(x_coord, .MAP)].rune;
                world.rooms[coord_to_index(x_coord, .MAP)].rune_parsed_x = true;
                x_coord.x += 1;
            }
            x_effect := parse_effect_rune(x_rune);
            if x_effect == {
            case .NONE;
                array_free(x_coords);
            case .RAIN;
                array_add(*context.world.room_effects, .{x_effect, x_coords});
                print("A Rain effect room and stored it!\n");
            }

            y_coord := coord;
            y_rune: Rune;
            // If the moving
            while y_coord.y > 0 && world.rooms[coord_to_index(y_coord, .MAP)].exists && !world.rooms[coord_to_index(y_coord, .MAP)].rune_parsed_y {
                array_add(*y_coords, y_coord);
                y_rune += world.rooms[coord_to_index(y_coord, .MAP)].rune;
                world.rooms[coord_to_index(y_coord, .MAP)].rune_parsed_y = true;
                y_coord.y -= 1;
            }
            y_effect := parse_effect_rune(y_rune);
            if y_effect == {
            case .NONE;
                array_free(y_coords);
            case .RAIN;
                array_add(*context.world.room_effects, .{y_effect, y_coords});
            }
        }
    }
}

// Returns the range for which tiles from a given room can occupy
tile_range_from_map_coord :: (map_coord: Coord) -> Coord_Range {
    range: Coord_Range;
    first_column := Coord.{COLUMN_WIDTH, COLUMN_WIDTH};
    range.min = Coord.{map_coord.x * ROOM_WIDTH, map_coord.y * ROOM_HEIGHT} + first_column;
    range.max = Coord.{(map_coord.x * ROOM_WIDTH) + ROOM_WIDTH - 1, (map_coord.y * ROOM_HEIGHT) + ROOM_HEIGHT - 1} + first_column;
    return range;
}

write_room_cards_to_world :: () {
    world := context.world;
    map := context.map;
    for map.placed_room_cards {
        r := get_room_from_hash(it.room_hash);
        assert(r != null, "Hit null room pointer while adding room tiles to tilemap.\nSkipping placed room %!\n", it.room_hash);
        start_x: s16 = it.coord.x * xx ROOM_WIDTH + (1 + it.coord.x); // Wall offset
        start_y: s16 = it.coord.y * xx ROOM_HEIGHT + (1 + it.coord.y); // Wall offset

        room_copy := r.*;

        if it.rotation > 0 {
            for 1..it.rotation {
                room_copy = rotate_room(room_copy);
            }
        }

        // Write Room exits and rune to the world map
        room_to_place := Map_Room.{rune = room_copy.rune, exits = room_copy.exits, exists = true};
        placed_idx := coord_to_index(it.coord, .MAP);
        world.rooms[placed_idx] = room_to_place;

        for y: 0..ROOM_HEIGHT - 1 {
            for x: 0..ROOM_WIDTH - 1 {
                room_coord := Coord.{xx x, xx y};
                world_coord := room_coord + Coord.{start_x, start_y};
                collision_tile := check_collision_tile_value(*room_copy, room_coord);
                entity_tile := check_entity_tile_value(*room_copy, room_coord);
                world_idx := coord_to_index(world_coord, .WORLD);
                world.collision[world_idx] = collision_tile;
                world.entities[world_idx] = entity_tile;
            }
        }
    }
}

open_map_exits :: () {
    _Late_Tile_Update :: struct {
        idx: int;
        tile: Collision_Tile;
    }
    _contains :: (e: Room_Exits, ce: Room_Exits) -> bool {
        return e & ce == ce;
    }
    world := context.world;
    late_tile_updates: [..]_Late_Tile_Update;
    late_tile_updates.allocator = temp;
    for <y: 0..MAP_HEIGHT - 1 {
        for x: 0..MAP_WIDTH - 1 {
            current_coord := Coord.{xx x, xx y};
            origin_tile := Coord.{current_coord.x * xx (ROOM_WIDTH + 1), current_coord.y * xx (ROOM_HEIGHT + 1)};
            current_room := world.rooms[coord_to_index(current_coord, .MAP)];
            if !current_room.exists continue;
            // Place the maps border
            for by: 0..ROOM_HEIGHT + 1 {
                for bx: 0..ROOM_WIDTH + 1 {
                    if bx == 0 || bx == ROOM_WIDTH + 1 || by == 0 || by == ROOM_HEIGHT + 1 {
                        world.collision[coord_to_index(origin_tile + .{xx bx, xx by}, .WORLD)] = .WALL;
                    }
                }
            }
            east_exits: Room_Exits;
            south_exits: Room_Exits;
            if x < MAP_WIDTH - 1 {
                east_neighbor := world.rooms[coord_to_index(current_coord + .{1, 0}, .MAP)];
                if east_neighbor.exists {
                    east_exits = exits_match(current_room.exits, east_neighbor.exits, .EAST);
                }
            }
            if y > 0 {
                south_neighbor := world.rooms[coord_to_index(current_coord + .{0, -1}, .MAP)];
                if south_neighbor.exists {
                    south_exits = exits_match(current_room.exits, south_neighbor.exits, .SOUTH);
                }
            }
            // Set the tiles corresponding to the exits to empty
            if east_exits != 0 {
                if _contains(east_exits, .EAST_NORTH) {
                    id1 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, ROOM_HEIGHT}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, ROOM_HEIGHT - 1}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                }
                if _contains(east_exits, .EAST) {
                    id1 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, ROOM_HEIGHT / 2}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, (ROOM_HEIGHT / 2) + 1}, .WORLD);
                    id3 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, (ROOM_HEIGHT / 2) + 2}, .WORLD);
                    id4 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, (ROOM_HEIGHT / 2) - 1}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                    array_add(*late_tile_updates, .{id3, .EMPTY});
                    array_add(*late_tile_updates, .{id4, .EMPTY});
                }
                if _contains(east_exits, .EAST_SOUTH) {
                    id1 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, 1}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{ROOM_WIDTH + 1, 2}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                }
            }

            if south_exits != 0 {
                if _contains(south_exits, .SOUTH_EAST) {
                    id1 := coord_to_index(origin_tile + .{ROOM_WIDTH, 0}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{ROOM_WIDTH - 1, 0}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                }
                if _contains(south_exits, .SOUTH) {
                    id1 := coord_to_index(origin_tile + .{ROOM_WIDTH / 2, 0}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{(ROOM_WIDTH / 2) + 1, 0}, .WORLD);
                    id3 := coord_to_index(origin_tile + .{(ROOM_WIDTH / 2) + 2, 0}, .WORLD);
                    id4 := coord_to_index(origin_tile + .{(ROOM_WIDTH / 2) - 1, 0}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                }
                if _contains(south_exits, .SOUTH_WEST) {
                    id1 := coord_to_index(origin_tile + .{2, 0}, .WORLD);
                    id2 := coord_to_index(origin_tile + .{1, 0}, .WORLD);
                    array_add(*late_tile_updates, .{id1, .EMPTY});
                    array_add(*late_tile_updates, .{id2, .EMPTY});
                }
            }
        }
    }

    // Final tile updates, right now it's just punching exit holes while still allowing each room to create it's border
    for late_tile_updates {
        world.collision[it.idx] = it.tile;
    }
    array_free(late_tile_updates);
}

// Takes 2 rooms and a coord relative to the first and returns which of the first rooms exits are clear
exits_match :: (a: Room_Exits, b: Room_Exits, direction: Map_Direction) -> Room_Exits {
    contains :: (e: Room_Exits, ce: Room_Exits) -> bool {
        return e & ce == ce;
    }
    matches: Room_Exits;
    if direction == {
    case .EAST;
        if contains(a, .EAST_NORTH) && contains(b, .WEST_NORTH) then matches |= .EAST_NORTH;
        if contains(a, .EAST) && contains(b, .WEST) then matches |= .EAST;
        if contains(a, .EAST_SOUTH) && contains(b, .WEST_SOUTH) then matches |= .EAST_SOUTH;
    case .SOUTH;
        if contains(a, .SOUTH_EAST) && contains(b, .NORTH_EAST) then matches |= .SOUTH_EAST;
        if contains(a, .SOUTH) && contains(b, .NORTH) then matches |= .SOUTH;
        if contains(a, .SOUTH_WEST) && contains(b, .NORTH_WEST) then matches |= .SOUTH_WEST;
    }
    return matches;
}

parse_entities_from_tiles :: () {
    is_valid_wall :: (x: int, y: int) -> bool #expand {
        coord := Coord.{xx x, xx y};
        return !`parsed[coord_to_index(coord, .WORLD)] && check_world_collision_tile_value(coord) == .WALL;
    }

    // Calculate the collision layer
    parsed: [WORLD_WIDTH * WORLD_HEIGHT]bool;
    for <y: 0..WORLD_HEIGHT - 1 {
        for x: 0..WORLD_WIDTH - 1 {
            coord := Coord.{xx x, xx y};
            if !parsed[coord_to_index(coord, .WORLD)] {
                tile := check_world_collision_tile_value(coord);
                if tile == {
                case .WALL;
                    left := x;
                    right := x;
                    top := y;
                    bot := y;

                    ix := x;
                    iy := y;
                    while is_valid_wall(ix, iy) {
                        right = ix;
                        if ix == WORLD_WIDTH - 1 break;
                        ix += 1;
                    }
                    for left..right parsed[coord_to_index(.{xx it, xx iy}, .WORLD)] = true;
                    complete_row: bool;

                    while y_loop := true {
                        iy -= 1;
                        if iy < 0 break y_loop;
                        ix := left;
                        while x_loop := ix <= right {
                            if is_valid_wall(ix, iy) {
                                ix += 1;
                            } else {
                                break y_loop;
                            }
                        }
                        for left..right parsed[coord_to_index(.{xx it, xx iy}, .WORLD)] = true;
                        bot = iy;
                    }
                    make_wall(left, right, top, bot);
                case .TOP_HALF;
                    left := x;
                    right := x;
                    ix := x;
                    while !parsed[coord_to_index(.{xx ix, xx y})] && check_world_collision_tile_value(.{xx ix, xx y}) == .TOP_HALF {
                        right = ix;
                        if ix == WORLD_WIDTH - 1 break;
                        ix += 1;
                    }

                    for left..right parsed[coord_to_index(.{xx it, xx y}, .WORLD)] = true;
                    make_top_wall(left, right, y);
                case .BOT_HALF;
                    left := x;
                    right := x;
                    ix := x;
                    while !parsed[coord_to_index(.{xx ix, xx y})] && check_world_collision_tile_value(.{xx ix, xx y}) == .BOT_HALF {
                        right = ix;
                        if ix == WORLD_WIDTH - 1 break;
                        ix += 1;
                    }
                    for left..right parsed[coord_to_index(.{xx it, xx y}, .WORLD)] = true;
                    make_bot_wall(left, right, y);
                case .LEFT_HALF;
                    top := y;
                    bot := y;
                    iy := y;
                    while !parsed[coord_to_index(.{xx x, xx iy})] && check_world_collision_tile_value(.{xx x, xx iy}) == .LEFT_HALF {
                        bot = iy;
                        if iy == 0 break;
                        iy -= 1;
                    }
                    for bot..top parsed[coord_to_index(.{xx x, xx it}, .WORLD)] = true;
                    make_left_wall(top, bot, x);
                case .RIGHT_HALF;
                    top := y;
                    bot := y;
                    iy := y;
                    while !parsed[coord_to_index(.{xx x, xx iy})] && check_world_collision_tile_value(.{xx x, xx iy}) == .RIGHT_HALF {
                        bot = iy;
                        if iy == 0 break;
                        iy -= 1;
                    }
                    for bot..top parsed[coord_to_index(.{xx x, xx it}, .WORLD)] = true;
                    make_right_wall(top, bot, x);
                }
            }
        }
    }

    for *parsed {
        it.* = false;
    }

    for y: 0..WORLD_HEIGHT - 1 {
        for x: 0..WORLD_WIDTH - 1 {
            coord := Coord.{xx x, xx y};
            if !parsed[coord_to_index(coord, .WORLD)] {
                entity := check_world_entity_tile_value(coord);
                if entity == {
                case .CRATE;
                    print("Started Parsing a crate at %,%\n", x, y);
                    // travelling coord
                    t_coord := coord;
                    t_coord.y -= 1;
                    if t_coord.y < 0 {
                        make_crate(coord);
                        parsed[coord_to_index(coord, .WORLD)] = true;
                        continue;
                    }
                    col_bellow: Collision_Tile;
                    ent_bellow: Entity_Tile;
                    while t_coord.y > 0 {
                        col_bellow = check_world_collision_tile_value(t_coord);
                        ent_bellow = check_world_entity_tile_value(t_coord);
                        if col_bellow == .EMPTY && ent_bellow == .EMPTY {
                            parsed[coord_to_index(t_coord, .WORLD)] = true;
                            print("Crate Falling: % --> %\n", coord, t_coord);
                            t_coord.y -= 1;
                            continue;
                        }

                        if col_bellow == {
                        case .TOP_HALF; #through;
                        case .BOT_HALF; #through;
                        case .RIGHT_HALF; #through;
                        case .LEFT_HALF; #through;
                        case .WALL;
                            print("Crate Hit Wall: % --> %\n", coord, t_coord);
                            break;
                        case .BLANK;
                            print("CRATE FELL INTO A BLANK TILE, SOMETHING IS WRONG!\n");
                            break;
                        }

                        if ent_bellow == {
                        case .CRATE;
                            print("Crate Hit a Crate: % --> %\n", coord, t_coord);
                            break;
                        }
                        t_coord.y -= 1;
                    }
                    if t_coord != coord {
                        parsed[coord_to_index(coord, .WORLD)] = true;
                        set_world_entity_tile_value(.EMPTY, coord);
                        new_coord := t_coord + .{0, 1};

                        parsed[coord_to_index(new_coord, .WORLD)] = true;
                        set_world_entity_tile_value(.CRATE, new_coord);
                        make_crate(new_coord);
                    }
                case .PLAYER_SPAWN;
                    if !player_is_valid() then make_player(coord);
                case .EMPTY;
                    parsed[coord_to_index(coord, .WORLD)] = true;
                }
            }
        }
    }
}
