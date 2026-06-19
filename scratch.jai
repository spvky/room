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
    test_string := alloc_string(name_length);

    success = file_read(file, *test_string, name_length);
    assert(success, "Failure when reading string\n");

    print("%\n", test_string); // Crashes at this print
    return room;
}
