gameplay_update :: () {
    dynamic_entities: [..]*Entity;
    static_entities: [..]*Entity;
    dynamic_entities.allocator = temp;
    static_entities.allocator = temp;
}
