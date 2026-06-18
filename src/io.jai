/*
main :: () {
    room := Room.{name = "A long short walk"};
    entities: [..]Entity;
    array_add(*entities, .{
                           props = .STATIC,
                           first_bytes = .[12, 23],
                           final_bytes = .[12, 23]});
    array_add(*entities, .{
                           props = .RENDERABLE,
                           first_bytes = .[2, 2],
                           final_bytes = .[2, 2]});

    file, ok := file_open("entities.dat", true);

    if ok {
        for *entities write_entity_to_file(*file, it);
    }
    // ent_info := cast(*Type_Info_Struct)type_info(Entity);
    // for ent_info.members {
    //     print("%: %\n", it.name, it.type.runtime_size);
    //     for note: it.notes print("%\n", note);
    //     print("----------\n");
    // }
}

*/
save_room_to_file :: (r: Editor_Room) {
    path := tprint("%.room", r.name);
    replace_chars(path, " ", #char "_");
    file, ok := file_open(path, true);
    assert(ok, "Failed to open %\n", path);
    success := file_write(*file, *r.name.count, size_of(int));
    assert(success, "Failed to write name string length for room to %\n", path);
    success = file_write(*file, *r.name.data, r.name.count);
    assert(success, "Failed to write room name to %\n", path);
    success = file_write(*file, *r.entities.count, size_of(int));
    assert(success, "Failed to write entity count to %\n", path);
    for *r.entities write_entity_to_file(*file, it);
}

write_entity_to_file :: (file: *File, entity: *Entity) {
    entity_info := cast(*Type_Info_Struct)type_info(Entity);
    for entity_info.members {
        should_skip: bool;
        for field_note: it.notes if equal(field_note, "ignore_serialize") should_skip = true;
        if should_skip continue;

        success := file_write(file, (cast(*u8)entity) + it.offset_in_bytes, it.type.runtime_size);
        assert(success, "Failed to write Entity field %\n", it.name);
    }
}

read_entity_from_file :: (file: *File, entity: *Entity) {
    entity_info := cast(*Type_Info_Struct)type_info(Entity);
    for entity_info.members {
        should_skip: bool;
        for field_note: it.notes if equal(field_note, "ignore_serialize") should_skip = true;
        if should_skip continue;
        success := file_read(file.*, (cast(*u8)entity) + it.offset_in_bytes, it.type.runtime_size);
        assert(success, "Failed to read Entity field %\n", it.name);
    }
}
