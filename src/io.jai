ROOMS_PATH :: "assets/rooms";
ASSET_VERSION: float32: 0.1;

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
    // Flags
    success = file_write(*file, *r.flags, size_of(Room_Flags));
    room_assert("Failed to write room flags!");
    // Exits
    success = file_write(*file, *r.exits, size_of(Room_Exits));
    room_assert("Failed to write room exits!");
    // Int Grid
    success = file_write(*file, *r.int_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Room_Tile));
    room_assert("Failed to write int_grid!");
    // Rune
    success = file_write(*file, *r.rune, size_of(Rune));
    room_assert("Failed to write room rune!");
    // Name
    success = file_write(*file, *r.name.count, size_of(int));
    room_assert("Failed to write name string length for room!");
    success = file_write(*file, r.name.data, r.name.count);
    room_assert("Failed to write room name!");
    // Extra Entity Data
    success = file_write(*file, *r.extra_data.count, size_of(int));
    room_assert("Failed to write extra entity data count!");
    if r.extra_data.count > 0 {
        success = file_write(*file, r.extra_data.data, size_of(Extra_Entity_Data) * r.extra_data.count);
        room_assert("Failed to write extra entity data!");
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
    room_assert("Failed to read room flags!");
    // Exits
    success = file_read(file, *r.exits, size_of(Room_Exits));
    room_assert("Failed to read room exits!");
    // Int Grid
    success = file_read(file, *r.int_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Room_Tile));
    room_assert("Failure when reading room int_grid!");
    // Rune
    success = file_read(file, *r.rune, size_of(Rune));
    room_assert("Failed to read room rune!");
    // Name
    name_length: int;
    success = file_read(file, *name_length, size_of(int));
    room_assert("Failed to read room name length!");
    r.name = alloc_string(name_length);
    success = file_read(file, r.name.data, name_length);
    room_assert("Failure when reading room name!");
    // Extra Entity Data
    entity_data_count: int;
    success = file_read(file, *entity_data_count, size_of(int));
    room_assert("Failure when reading entity data count!");
    if entity_data_count > 0 {
        array_reserve(*r.extra_data, entity_data_count);
        success = file_read(file, r.extra_data.data, size_of(Extra_Entity_Data) * r.extra_data.count);
        room_assert("Failure when reading entity data!");
    } else {
        print("No entity data in %, skipping reading it!\n", path);
    }

    img_path := tprint("%/%/%.png", ROOMS_PATH, subdir, r.name);
    replace_chars(img_path, " ", #char "_");
    texture_ok := texture_load_from_file(*r.texture, img_path);
    room_assert("Failure to load room texture!");

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

                table_add(context.room_table, room_hash, room);
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

                table_add(context.room_table, room_hash, room);
                print("Static Room: % | % has been added to the table\n", room.name, room_hash);
            }
        }
    }
}

#scope_file
room_assert :: (msg: string) #expand {
    assert(`success, "(%) %\n", `path, msg);
}

generate_room_png :: (r: *Room, path: string) {
    // Helper types/macros //////////////////////////
    Room_Color :: enum {
        COLOR_EMPTY;
        COLOR_WALL;
        COLOR_EXIT;
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
        case .COLOR_EXIT;
            `data[(`i * `channels)] = 255;
            `data[(`i * `channels) + 1] = 255;
            `data[(`i * `channels) + 2] = 0;
            `data[(`i * `channels) + 3] = 255;
        }
    }
    _has_exit :: (exit: Room_Exits) -> bool #expand {
        return `r.exits & exit == exit;
    }
    // /////////////////////////////////////////////

    channels: s32: 4;
    data: [(ROOM_WIDTH + 2) * (ROOM_HEIGHT + 2) * channels]u8;
    stride := xx (ROOM_HEIGHT + 2) * channels;

    i: int;
    for <y: 0..ROOM_HEIGHT + 1 {
        for x: 0..ROOM_WIDTH + 1 {
            if x == 0 || x == ROOM_WIDTH + 1 || y == 0 || y == ROOM_HEIGHT + 1 {
                // Drawing border
                is_wall: bool = true;

                if _has_exit(.NORTH_EAST) && (x == 21 || x == 22) && y == 23 then is_wall = false;
                if _has_exit(.NORTH) && (x == 11 || x == 12) && y == 23 then is_wall = false;
                if _has_exit(.NORTH_WEST) && (x == 1 || x == 2) && y == 23 then is_wall = false;

                if _has_exit(.SOUTH_EAST) && (x == 21 || x == 22) && y == 0 then is_wall = false;
                if _has_exit(.SOUTH) && (x == 11 || x == 12) && y == 0 then is_wall = false;
                if _has_exit(.SOUTH_WEST) && (x == 1 || x == 2) && y == 0 then is_wall = false;

                if _has_exit(.EAST_NORTH) && (y == 21 || y == 22) && x == 23 then is_wall = false;
                if _has_exit(.EAST) && (y == 11 || y == 12) && x == 23 then is_wall = false;
                if _has_exit(.EAST_SOUTH) && (y == 1 || y == 2) && x == 23 then is_wall = false;

                if _has_exit(.WEST_NORTH) && (y == 21 || y == 22) && x == 0 then is_wall = false;
                if _has_exit(.WEST) && (y == 11 || y == 12) && x == 0 then is_wall = false;
                if _has_exit(.WEST_SOUTH) && (y == 1 || y == 2) && x == 0 then is_wall = false;

                if is_wall {
                    _set_pixel(.COLOR_WALL);
                } else {
                    _set_pixel(.COLOR_EMPTY);
                }
            } else {
                // Drawing room internals
                value := check_tile_value(r, .{xx (x - 1), xx (y - 1)});
                if value == {
                case .WALL;
                    _set_pixel(.COLOR_WALL);
                case .EMPTY;
                    _set_pixel(.COLOR_EMPTY);
                }
            }
            i += 1;
        }
    }
    raw_path := to_c_string(path);
    defer free(raw_path);
    stbi_write_png(raw_path, xx (ROOM_WIDTH + 2), xx (ROOM_HEIGHT + 2), channels, *data, stride);
}

to_c_string :: (s: string) -> *u8 {
    result := cast(*u8)alloc(s.count + 1); // Add 1 for the zero.
    memcpy(result, s.data, s.count);
    result[s.count] = 0;

    return result;
}
