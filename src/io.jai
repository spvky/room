ROOMS_PATH :: "assets/rooms";
ASSET_VERSION: float32: 0.6;
PIXELS_PER_TILE :: 2;

save_room_v2 :: (r: Room_V2) {
    is_static := r.flags & .STATIC == .STATIC;
    subdir: string = ifx is_static "static" else "placeable";
    path := tprint("%/%/%.room", ROOMS_PATH, subdir, r.name);
    replace_chars(path, " ", #char "_");
    file, ok := file_open(path, true);
    assert(ok, "Failed to open % for writing!\n", path);
    defer {
        file_close(*file);
        print("Finished writing room to %\n", path);
    }
    // Version
    version: float32 = ASSET_VERSION;
    success := file_write(*file, *version, size_of(float32));
    _room_assert("Failed to write room version!");
    // Flags
    success = file_write(*file, *r.flags, size_of(Room_Flags));
    _room_assert("Failed to write room flags!");
    // Exits
    success = file_write(*file, *r.exits, size_of(Room_Exits));
    _room_assert("Failed to write room exits!");
    // Int Grid
    success = file_write(*file, *r.int_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Collision_Tile));
    _room_assert("Failed to write int_grid!");
    // Rune
    success = file_write(*file, *r.rune, size_of(Rune));
    _room_assert("Failed to write room rune!");
    // Map Position
    success = file_write(*file, *r.static_position, size_of(Coord));
    _room_assert("Failed to write map position!");
    // Name
    success = file_write(*file, *r.name.count, size_of(int));
    _room_assert("Failed to write name string length for room!");
    success = file_write(*file, r.name.data, r.name.count);
    _room_assert("Failed to write room name!");
    write_entity_manager_to_file(*r.entities, *file);

    // TODO:
    // img_path := tprint("%/%/%.png", ROOMS_PATH, subdir, r.name);
    // replace_chars(img_path, " ", #char "_");
    // generate_room_png(*r, img_path);
}

load_room_v2 :: (filename: string, static := false) -> Room_V2, bool {
    // Helper for logging loading errors
    subdir: string = ifx static "static" else "placeable";
    path := tprint("%/%/%", ROOMS_PATH, subdir, filename);
    file, ok := file_open(path);
    assert(ok, "Failed to open % for reading!\n", path);
    defer {
        file_close(*file);
        print("Finished reading room from %\n", path);
    }
    r: Room_V2;
    // Version
    version: float32;
    success := file_read(file, *version, size_of(float32));
    if version != ASSET_VERSION {
        print("Room at % had a version number of %, when it should be %, skipping...\n", path, version, ASSET_VERSION);
        return r, false;
    }
    // Flags
    success = file_read(file, *r.flags, size_of(Room_Flags));
    _room_assert("Failed to read room flags!");
    // Exits
    success = file_read(file, *r.exits, size_of(Room_Exits));
    _room_assert("Failed to read room exits!");
    // Int Grid
    success = file_read(file, *r.int_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Collision_Tile));
    _room_assert("Failure when reading room int_grid!");
    // Rune
    success = file_read(file, *r.rune, size_of(Rune));
    _room_assert("Failed to read room rune!");
    // Map Position
    success = file_read(file, *r.static_position, size_of(Coord));
    _room_assert("Failed to read map position!");
    // Name
    name_length: int;
    success = file_read(file, *name_length, size_of(int));
    _room_assert("Failed to read room name length!");
    r.name = alloc_string(name_length);
    success = file_read(file, r.name.data, name_length);
    _room_assert("Failure when reading room name!");
    read_entity_manager_from_file(*r.entities, *file);

    // TODO:
    // img_path := tprint("%/%/%.png", ROOMS_PATH, subdir, r.name);
    // replace_chars(img_path, " ", #char "_");
    // texture_ok := texture_load_from_file(*r.texture, img_path);
    // _room_assert("Failure to load room texture!");

    return r, true;
}

write_entity_manager_to_file :: (e: *Entity_Manager, file: *File) {
    items_bytes := e.items.count * size_of(Entity);
    print("Items bytes ins %\n", items_bytes);
    freelist_bytes := e.freelist.count * size_of(Entity_Handle);
    success := file_write(file, *items_bytes, size_of(int));
    if !success print("Failed to write entity items bytes to %!\n", file.*);
    success = file_write(file, *freelist_bytes, size_of(int));
    if !success print("Failed to write entity freelist bytes to %!\n", file.*);
    success = file_write(file, *e.count, size_of(u32));
    if !success print("Failed to write entity manager count %!\n", file.*);
    print("Successfully wrote the count of the entity manager as %\n", e.count);
    if items_bytes > 0 {
        success = file_write(file, e.items.data, items_bytes);
        if !success print("Failed to write entity data to %!\n", file.*);
        print("Successfully wrote % bytes of entity data\n", items_bytes);
    }
    if freelist_bytes > 0 {
        success = file_write(file, e.freelist.data, freelist_bytes);
        if !success print("Failed to write entity freelist to %!\n", file.*);
    }
}

read_entity_manager_from_file :: (e: *Entity_Manager, file: *File) {
    items_bytes: int;
    freelist_bytes: int;
    success := file_read(file, *items_bytes, size_of(int));
    if !success print("Failed to read items bytes from %!\n", file.*);
    items_count := items_bytes / size_of(Entity);
    print("Items Bytes: %\n Items Count: %\n", items_bytes, items_count);
    success = file_read(file, *freelist_bytes, size_of(int));
    if !success print("Failed to read freelist bytes from %!\n", file.*);
    freelist_count := freelist_bytes / size_of(Entity_Handle);
    success = file_read(file, *e.count, size_of(u32));
    if !success print("Failed to read entity manager count from %!\n", file.*);
    if items_bytes > 0 {
        array_reserve(*e.items, items_count);
        success = file_read(file, e.items.data, items_bytes);
        e.items.count = items_count;
        print("Set a count of % for items!\n", items_count);
        if !success print("Failed to read entity data from %!\n", file.*);
    }
    for e.items print("Read Entity: %\n", it.handle);
    if freelist_bytes > 0 {
        array_reserve(*e.freelist, freelist_count);
        success = file_read(file, e.freelist.data, freelist_bytes);
        e.freelist.count = freelist_count;
        if !success print("Failed to read freelist data from %!\n", file.*);
    }
}

save_room :: (r: Room) {
    is_static := r.flags & .STATIC == .STATIC;
    subdir: string = ifx is_static "static" else "placeable";
    path := tprint("%/%/%.room", ROOMS_PATH, subdir, r.name);
    replace_chars(path, " ", #char "_");
    file, ok := file_open(path, true);
    assert(ok, "Failed to open % for writing!\n", path);
    defer {
        file_close(*file);
        print("Finished writing room to %\n", path);
    }
    // Version
    version: float32 = ASSET_VERSION;
    success := file_write(*file, *version, size_of(float32));
    _room_assert("Failed to write room version!");
    // Flags
    success = file_write(*file, *r.flags, size_of(Room_Flags));
    _room_assert("Failed to write room flags!");
    // Exits
    success = file_write(*file, *r.exits, size_of(Room_Exits));
    _room_assert("Failed to write room exits!");
    // Int Grid
    success = file_write(*file, *r.int_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Collision_Tile));
    _room_assert("Failed to write int_grid!");
    // Entity Grid
    success = file_write(*file, *r.entity_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Entity_Tile));
    _room_assert("Failed to write entity_grid!");
    // Rune
    success = file_write(*file, *r.rune, size_of(Rune));
    _room_assert("Failed to write room rune!");
    // Map Position
    success = file_write(*file, *r.map_position, size_of(Coord));
    _room_assert("Failed to write map position!");
    // Name
    success = file_write(*file, *r.name.count, size_of(int));
    _room_assert("Failed to write name string length for room!");
    success = file_write(*file, r.name.data, r.name.count);
    _room_assert("Failed to write room name!");
    // Extra Entity Data
    extra_entity_bytes := r.extra_data.count * size_of(Extra_Entity_Data);

    success = file_write(*file, *extra_entity_bytes, size_of(int));
    _room_assert("Failed to write extra entity data bytes!");
    if r.extra_data.count > 0 {
        print("Found % bytes of extra entity data, writing now\n", extra_entity_bytes);
        success = file_write(*file, r.extra_data.data, extra_entity_bytes);
        _room_assert("Failed to write extra entity data!");
    } else {
        print("No entity data in %, skipping writing it!\n", path);
    }

    img_path := tprint("%/%/%.png", ROOMS_PATH, subdir, r.name);
    replace_chars(img_path, " ", #char "_");
    generate_room_png(*r, img_path);
}

load_room :: (filename: string, static := false) -> Room, bool {
    // Helper for logging loading errors
    subdir: string = ifx static "static" else "placeable";
    path := tprint("%/%/%", ROOMS_PATH, subdir, filename);
    file, ok := file_open(path);
    assert(ok, "Failed to open % for reading!\n", path);
    defer {
        file_close(*file);
        print("Finished reading room from %\n", path);
    }
    r: Room;
    // Version
    version: float32;
    success := file_read(file, *version, size_of(float32));
    if version != ASSET_VERSION {
        print("Room at % had a version number of %, when it should be %, skipping...\n", path, version, ASSET_VERSION);
        return r, false;
    }
    // Flags
    success = file_read(file, *r.flags, size_of(Room_Flags));
    _room_assert("Failed to read room flags!");
    // Exits
    success = file_read(file, *r.exits, size_of(Room_Exits));
    _room_assert("Failed to read room exits!");
    // Int Grid
    success = file_read(file, *r.int_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Collision_Tile));
    _room_assert("Failure when reading room int_grid!");
    // Entity Grid
    success = file_read(file, *r.entity_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Entity_Tile));
    _room_assert("Failure when reading room entity_grid!");
    // Rune
    success = file_read(file, *r.rune, size_of(Rune));
    _room_assert("Failed to read room rune!");
    // Map Position
    success = file_read(file, *r.map_position, size_of(Coord));
    _room_assert("Failed to read map position!");
    // Name
    name_length: int;
    success = file_read(file, *name_length, size_of(int));
    _room_assert("Failed to read room name length!");
    r.name = alloc_string(name_length);
    success = file_read(file, r.name.data, name_length);
    _room_assert("Failure when reading room name!");
    // Extra Entity Data
    entity_data_bytes: int;
    success = file_read(file, *entity_data_bytes, size_of(int));
    _room_assert("Failure when reading entity data bytes!");
    if entity_data_bytes > 0 {
        extra_entity_count := cast(s64)(cast(float32)entity_data_bytes / cast(float32)size_of(Extra_Entity_Data));
        print("Reading % Extra Entities from room\n", extra_entity_count);
        array_reserve(*r.extra_data, extra_entity_count);
        success = file_read(file, r.extra_data.data, entity_data_bytes);
        _room_assert("Failure when reading entity data!");
        r.extra_data.count = extra_entity_count;
    } else {
        print("No entity data in %, skipping reading it!\n", path);
    }

    img_path := tprint("%/%/%.png", ROOMS_PATH, subdir, r.name);
    replace_chars(img_path, " ", #char "_");
    texture_ok := texture_load_from_file(*r.texture, img_path);
    _room_assert("Failure to load room texture!");

    return r, true;
}

load_all_rooms :: () {
    // Load placable rooms
    for file_list("assets/rooms/placeable",, temp) {
        _, _, extension, filename := path_decomp(it);
        if equal(extension, "room") {
            room, success := load_room(filename); // Put the room into the map from here
            if success {
                room_hash := djb2_hash(room.name);

                table_set(context.room_table, room_hash, room);
                print("Placeable Room: % | % has been added to the table\n", room.name, room_hash);
            }
        }
    }

    // Load static rooms
    for file_list("assets/rooms/static",, temp) {
        _, _, extension, filename := path_decomp(it);
        if equal(extension, "room") {
            room, success := load_room(filename, true); // Put the room into the map from here
            if success {
                room_hash := djb2_hash(room.name);

                table_set(context.room_table, room_hash, room);
                print("Static Room: % | % has been added to the table\n", room.name, room_hash);
            }
        }
    }
}

is_room_available :: (hash: u32) -> bool {
    for context.map_screen_state.available_rooms if it == hash return true;
    return false;
}

generate_room_png :: (r: *Room, path: string) {
    Pixel :: struct {
        r: u8;
        g: u8;
        b: u8;
        a: u8;
    }
    Room_Color :: enum {
        COLOR_EMPTY;
        COLOR_WALL;
        COLOR_BLANK;
        COLOR_RED;
    }
    _set_pixel :: (idx: int, color: Room_Color) #expand {
        if color == {
        case .COLOR_WALL;
            `pixel_data[idx] = .{255, 255, 255, 255};
        case .COLOR_EMPTY;
            if r.flags & .STATIC == .STATIC {
                `pixel_data[idx] = .{55, 148, 110, 255};
            } else {
                `pixel_data[idx] = .{80, 115, 240, 255};
            }
        case .COLOR_BLANK;
            `pixel_data[idx] = .{0, 0, 0, 255};
        case .COLOR_RED;
            `pixel_data[idx] = .{255, 0, 0, 255};
        }
    }
    _set_tile :: (tile: Collision_Tile) #expand {
        if tile == {
        case .WALL;
            _set_pixel(`tl, .COLOR_WALL);
            _set_pixel(`tr, .COLOR_WALL);
            _set_pixel(`bl, .COLOR_WALL);
            _set_pixel(`br, .COLOR_WALL);
        case .EMPTY;
            _set_pixel(`tl, .COLOR_EMPTY);
            _set_pixel(`tr, .COLOR_EMPTY);
            _set_pixel(`bl, .COLOR_EMPTY);
            _set_pixel(`br, .COLOR_EMPTY);
        case .TOP_HALF;
            _set_pixel(`tl, .COLOR_WALL);
            _set_pixel(`tr, .COLOR_WALL);
            _set_pixel(`bl, .COLOR_EMPTY);
            _set_pixel(`br, .COLOR_EMPTY);
        case .BOT_HALF;
            _set_pixel(`tl, .COLOR_EMPTY);
            _set_pixel(`tr, .COLOR_EMPTY);
            _set_pixel(`bl, .COLOR_WALL);
            _set_pixel(`br, .COLOR_WALL);
        case .LEFT_HALF;
            _set_pixel(`tl, .COLOR_WALL);
            _set_pixel(`tr, .COLOR_EMPTY);
            _set_pixel(`bl, .COLOR_WALL);
            _set_pixel(`br, .COLOR_EMPTY);
        case .RIGHT_HALF;
            _set_pixel(`tl, .COLOR_EMPTY);
            _set_pixel(`tr, .COLOR_WALL);
            _set_pixel(`bl, .COLOR_EMPTY);
            _set_pixel(`br, .COLOR_WALL);
        }
    }

    _has_exit :: (exit: Room_Exits) -> bool #expand {
        return `r.exits & exit == exit;
    }

    pixel_array_width :: (ROOM_WIDTH + (COLUMN_WIDTH * 2)) * PIXELS_PER_TILE;
    pixel_array_height :: (ROOM_HEIGHT + (COLUMN_WIDTH * 2)) * PIXELS_PER_TILE;
    pixel_data: [pixel_array_width * pixel_array_height]Pixel;

    for y: 0..ROOM_HEIGHT + 1 {
        for x: 0..ROOM_WIDTH + 1 {
            by := y * 2;
            bx := x * 2;
            bl := by * pixel_array_width + bx;
            br := by * pixel_array_width + (bx + 1);
            tl := (by + 1) * pixel_array_width + bx;
            tr := (by + 1) * pixel_array_width + (bx + 1);

            if x == 0 || x == ROOM_WIDTH + 1 || y == 0 || y == ROOM_HEIGHT + 1 {
                is_wall: bool = true;

                // Will only work with even numbered, square maps
                if _has_exit(.NORTH_EAST) && (x == ROOM_WIDTH - 1 || x == ROOM_WIDTH) && y == ROOM_HEIGHT + 1 then is_wall = false;
                if _has_exit(.NORTH) && (x == HALF_ROOM_SIZE - 1 || x == HALF_ROOM_SIZE || x == HALF_ROOM_SIZE + 1 || x == HALF_ROOM_SIZE + 2) && y == ROOM_HEIGHT + 1 then is_wall = false;
                if _has_exit(.NORTH_WEST) && (x == 1 || x == 2) && y == ROOM_HEIGHT + 1 then is_wall = false;

                if _has_exit(.SOUTH_EAST) && (x == ROOM_WIDTH - 1 || x == ROOM_WIDTH) && y == 0 then is_wall = false;
                if _has_exit(.SOUTH) && (x == HALF_ROOM_SIZE - 1 || x == HALF_ROOM_SIZE || x == HALF_ROOM_SIZE + 1 || x == HALF_ROOM_SIZE + 2) && y == 0 then is_wall = false;
                if _has_exit(.SOUTH_WEST) && (x == 1 || x == 2) && y == 0 then is_wall = false;

                if _has_exit(.EAST_SOUTH) && (y == 1 || y == 2) && x == ROOM_WIDTH + 1 then is_wall = false;
                if _has_exit(.EAST) && (y == HALF_ROOM_SIZE - 1 || y == HALF_ROOM_SIZE || y == HALF_ROOM_SIZE + 1 || y == HALF_ROOM_SIZE + 2) && x == ROOM_WIDTH + 1 then is_wall = false;
                if _has_exit(.EAST_NORTH) && (y == ROOM_HEIGHT - 1 || y == ROOM_HEIGHT) && x == ROOM_WIDTH + 1 then is_wall = false;

                if _has_exit(.WEST_SOUTH) && (y == 1 || y == 2) && x == 0 then is_wall = false;
                if _has_exit(.WEST) && (y == HALF_ROOM_SIZE - 1 || y == HALF_ROOM_SIZE || y == HALF_ROOM_SIZE + 1 || y == HALF_ROOM_SIZE + 2) && x == 0 then is_wall = false;
                if _has_exit(.WEST_NORTH) && (y == ROOM_HEIGHT - 1 || y == ROOM_HEIGHT) && x == 0 then is_wall = false;

                if is_wall {
                    _set_tile(.WALL);
                } else {
                    _set_tile(.EMPTY);
                }
            } else {
                tile := check_collision_tile_value(r, .{xx (x - 1), xx (y - 1)});
                _set_tile(tile);
            }
        }
    }

    channels: s32: 4;
    stride := pixel_array_width * channels;
    raw_path := to_c_string(path);
    defer free(raw_path);

    stbi_flip_vertically_on_write(1);
    stbi_write_png(raw_path, xx pixel_array_width, xx pixel_array_height, channels, *pixel_data, stride);
}

generate_world_map_png :: (path: string) {
    // Helper types/macros //////////////////////////
    Room_Color :: enum {
        COLOR_EMPTY;
        COLOR_WALL;
        COLOR_BLANK;
    }

    _set_pixel :: (color: Room_Color) #expand {
        if color == {
        case .COLOR_WALL;
            `data[(`i * `channels)] = 255;
            `data[(`i * `channels) + 1] = 255;
            `data[(`i * `channels) + 2] = 255;
            `data[(`i * `channels) + 3] = 255;
        case .COLOR_EMPTY;
            `data[(`i * `channels)] = 80;
            `data[(`i * `channels) + 1] = 115;
            `data[(`i * `channels) + 2] = 240;
            `data[(`i * `channels) + 3] = 255;
        case .COLOR_BLANK;
            `data[(`i * `channels)] = 0;
            `data[(`i * `channels) + 1] = 0;
            `data[(`i * `channels) + 2] = 0;
            `data[(`i * `channels) + 3] = 255;
        }
    }
    _has_exit :: (exit: Room_Exits) -> bool #expand {
        return `r.exits & exit == exit;
    }
    // /////////////////////////////////////////////
    world := context.world;

    channels: s32: 4;
    data: [(WORLD_WIDTH * WORLD_HEIGHT) * channels]u8;
    stride := xx (WORLD_HEIGHT) * channels;

    i: int;
    for <y: 0..WORLD_HEIGHT - 1 {
        for x: 0..WORLD_WIDTH - 1 {
            tile := world.collision[coord_to_index(.{xx x, xx y}, .WORLD)];
            if tile == {
            case .EMPTY;
                _set_pixel(.COLOR_EMPTY);
            case .WALL;
                _set_pixel(.COLOR_WALL);
            case .BLANK;
                _set_pixel(.COLOR_BLANK);
            }
            i += 1;
        }
    }
    raw_path := to_c_string(path);
    defer free(raw_path);
    stbi_write_png(raw_path, xx WORLD_WIDTH, xx WORLD_HEIGHT, channels, *data, stride);
}

#scope_file
_room_assert :: (msg: string) #expand {
    assert(`success, "(%) %\n", `path, msg);
}

to_c_string :: (s: string) -> *u8 {
    result := cast(*u8)alloc(s.count + 1); // Add 1 for the zero.
    memcpy(result, s.data, s.count);
    result[s.count] = 0;

    return result;
}
