ROOMS_PATH :: "assets/rooms";
/*
	Editor_Room :: struct {
		name: string
		int_grid: Grid of entity types
		extra_entity_data: [..]Extra_Entity_Data
	}
*/
save_room :: (r: Editor_Room) {
    path := tprint("%/%.room", ROOMS_PATH, r.name);
    replace_chars(path, " ", #char "_");
    file, ok := file_open(path, true);
    assert(ok, "Failed to open % for writing!\n", path);
    defer {
        file_close(*file);
        print("Finished writing room to %\n", path);
    }
    success := file_write(*file, *r.name.count, size_of(int));
    room_assert("Failed to write name string length for room!");
    success = file_write(*file, r.name.data, r.name.count);
    room_assert("Failed to write room name!");
    success = file_write(*file, *r.int_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Room_Tile));
    room_assert("Failed to write int_grid!");
    success = file_write(*file, *r.extra_data.count, size_of(int));
    room_assert("Failed to write extra entity data count!");
    if r.extra_data.count > 0 {
        success = file_write(*file, r.extra_data.data, size_of(Extra_Entity_Data) * r.extra_data.count);
        room_assert("Failed to write extra entity data!");
    } else {
        print("No entity data in %, skipping writing it!\n", path);
    }
    success = file_write(*file, *r.flags, size_of(Room_Flags));
    room_assert("Failed to write room flags!");
    success = file_write(*file, *r.rune, size_of(Rune));
    room_assert("Failed to write room rune!");
}

load_room :: (filename: string) -> Editor_Room {
    // Helper for logging loading errors
    path := tprint("%/%", ROOMS_PATH, filename);
    file, ok := file_open(path);
    assert(ok, "Failed to open % for reading!\n", path);
    defer {
        file_close(*file);
        print("Finished reading room from %\n", path);
    }
    r: Editor_Room;
    name_length: int;
    success := file_read(file, *name_length, size_of(int));
    room_assert("Failed to read room name length!");
    r.name = alloc_string(name_length);
    success = file_read(file, r.name.data, name_length);
    room_assert("Failure when reading room name!");
    success = file_read(file, *r.int_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Room_Tile));
    room_assert("Failure when reading room int_grid!");
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
    success = file_read(file, *r.flags, size_of(Room_Flags));
    room_assert("Failed to read room flags!");
    success = file_read(file, *r.rune, size_of(Rune));
    room_assert("Failed to read room rune!");
    return r;
}

#scope_file

room_assert :: (msg: string) #expand {
    assert(`success, "(%)[%] %\n", `path, msg);
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
