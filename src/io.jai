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

save_room_to_file :: (r: Room) {
	escaped_name := copy_string(r.name);
  replace_chars(escaped_name, " ", #char "_");
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

#import "Basic";
#import "Math";
#import "File";
#import "String";
*/
