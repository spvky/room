ROOMS_PATH :: "assets/rooms";

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
    // Flags
    success := file_write(*file, *r.flags, size_of(Room_Flags));
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

load_room :: (filename: string, static := false) -> Room {
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
    // Flags
    success := file_read(file, *r.flags, size_of(Room_Flags));
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

    return r;
}

load_all_rooms :: () {
    // Load placable rooms
    for file_list("assets/rooms/placeable",, temp) {
        _, _, extension, filename := path_decomp(it);
        if equal(extension, "room") {
            room := load_room(filename); // Put the room into the map from here
            room_hash := djb2_hash(room.name);

            table_add(context.room_table, room_hash, room);
            print("Room: % | % has been added to the table\n", room.name, room_hash);
        }
    }

    // Load static rooms
    for file_list("assets/rooms/static",, temp) {
        _, _, extension, filename := path_decomp(it);
        if equal(extension, "room") {
            room := load_room(filename, true); // Put the room into the map from here
            room_hash := djb2_hash(room.name);

            table_add(context.room_table, room_hash, room);
            print("Room: % | % has been added to the table\n", room.name, room_hash);
        }
    }
}

#scope_file
room_assert :: (msg: string) #expand {
    assert(`success, "(%) %\n", `path, msg);
}

// Writes a passed (static) struct to file
write_struct_to_file :: (file: *File, t: *$T) {
    struct_info := cast(*Type_Info_Struct)type_info(T);
    for struct_info.members {
        should_skip: bool;
        for field_note: it.notes if equal(field_note, "ignore_serialize") should_skip = true;
        if should_skip continue;

        success := file_write(file, (cast(*u8)t) + it.offset_in_bytes, it.type.runtime_size);
        assert(success, "Failed to write struct field %\nin file %\n", it.name, file);
    }
}

generate_room_png :: (r: *Room, path: string) {
    channels: s32: 4;
    data: [ROOM_WIDTH * ROOM_HEIGHT * channels]u8;
    stride := xx ROOM_HEIGHT * channels;

    i: int;
    for <y: 0..ROOM_HEIGHT - 1 {
        for x: 0..ROOM_WIDTH - 1 {
            value := check_tile_value(r, .{xx x, xx y});
            if value == {
            case .WALL;
                data[(i * channels)] = 255;
                data[(i * channels) + 1] = 255;
                data[(i * channels) + 2] = 255;
                data[(i * channels) + 3] = 255;

            case;
                data[(i * channels)] = 80;
                data[(i * channels) + 1] = 115;
                data[(i * channels) + 2] = 240;
                data[(i * channels) + 3] = 255;
            }
            i += 1;
        }
    }

    // for 0..ROOM_WIDTH * ROOM_HEIGHT - 1 {
    //     r.int;
    //     if it < xx ROOM_WIDTH {
    //         data[it * channels] = 255;
    //     }
    //     data[(it * channels) + 1] = 125;
    //     data[(it * channels) + 2] = 125;
    //     data[(it * channels) + 3] = 255;
    // }
    // Get output path, but the writing here works
    raw_path := to_c_string(path);
    defer free(raw_path);
    stbi_write_png(raw_path, xx ROOM_WIDTH, xx ROOM_HEIGHT, channels, *data, stride);
}

to_c_string :: (s: string) -> *u8 {
    result := cast(*u8)alloc(s.count + 1); // Add 1 for the zero.
    memcpy(result, s.data, s.count);
    result[s.count] = 0;

    return result;
}
