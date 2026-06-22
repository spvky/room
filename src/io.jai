ROOMS_PATH :: "assets/rooms";
save_room_to_file :: (r: Editor_Room) {
    path := tprint("%/%.room", ROOMS_PATH, r.name);
    replace_chars(path, " ", #char "_");
    file, ok := file_open(path, true);
    assert(ok, "Failed to open %\n", path);
    defer {
        file_close(*file);
        print("Finished writing to %\n", path);
    }
    success := file_write(*file, *r.name.count, size_of(int));
    assert(success, "Failed to write name string length for room to %\n", path);
    success = file_write(*file, r.name.data, r.name.count);
    assert(success, "Failed to write room name to %\n", path);
    success = file_write(*file, *r.int_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Room_Tile));
    assert(success, "Failed to write int_grid to %\n", path);
    success = file_write(*file, *r.entities.count, size_of(int));
    assert(success, "Failed to write entity count to %\n", path);
    for *r.entities write_editor_entity_to_file(*file, it);
    success = file_write(*file, *r.colliders.count, size_of(int));
    assert(success, "Failed to write collision entity count to %\n", path);
    for *r.colliders write_editor_collider_to_file(*file, it);
}

write_editor_entity_to_file :: (file: *File, entity: *Editor_Entity) {
    entity_info := cast(*Type_Info_Struct)type_info(Editor_Entity);
    for entity_info.members {
        should_skip: bool;
        for field_note: it.notes if equal(field_note, "ignore_serialize") should_skip = true;
        if should_skip continue;

        success := file_write(file, (cast(*u8)entity) + it.offset_in_bytes, it.type.runtime_size);
        assert(success, "Failed to write Entity field %\n", it.name);
    }
}

write_editor_collider_to_file :: (file: *File, collider: *Editor_Collider) {
    collider_info := cast(*Type_Info_Struct)type_info(Editor_Collider);
    for collider_info.members {
        success := file_write(file, (cast(*u8)collider) + it.offset_in_bytes, it.type.runtime_size);
        assert(success, "Failed to write Collider field %\n", it.name);
    }
}

load_editor_room_from_file :: (filename: string) -> Editor_Room {
    path := tprint("%/%", ROOMS_PATH, filename);
    file, ok := file_open(path);
    assert(ok, "Failed to open file % for reading!\n", path);
    defer {
        file_close(*file);
        print("Finished reading room from %\n", path);
    }
    room: Editor_Room;
    name_length: int;
    success := file_read(file, *name_length, size_of(int));
    assert(success, "Failed to read room name length from %!\n", path);

    print("Name Length: %\n", name_length);
    room.name = alloc_string(name_length);

    success = file_read(file, room.name.data, name_length);
    assert(success, "Failure when reading room name\n");
    success = file_read(file, *room.int_grid, size_of([ROOM_WIDTH * ROOM_HEIGHT]Room_Tile));
    assert(success, "Failure when reading room int_grid\n");
    entity_count: int;
    success = file_read(file, *entity_count, size_of(int));
    assert(success, "Failure when reading entity count\n");
    print("Entity Count %\n", entity_count);
    array_reserve(*room.entities, entity_count);
    room.entities.count = entity_count;
    if entity_count > 0 {
        success = file_read(file, room.entities.data, size_of(Editor_Entity) * entity_count);
        assert(success, "Failed to write entity data!\n");
    }

    collider_count: int;
    success = file_read(file, *collider_count, size_of(int));
    assert(success, "Failure when reading collider count\n");
    array_reserve(*room.colliders, collider_count);
    room.colliders.count = collider_count;
    if collider_count > 0 {
        success = file_read(file, room.colliders.data, size_of(Editor_Collider) * collider_count);
        assert(success, "Failed to write collider data!\n");
    }

    print("Colliders: %\n", room.colliders);

    return room;
}
