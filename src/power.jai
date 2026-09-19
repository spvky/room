handle_power_conductivity :: () {
    for *context.entities {
        if !entity_has_props(it, .CONDUIT) continue;
        if entity_valid(it.first_child) {
            child := entity_get(it.first_child);
            if entity_has_flags(it, .POWERED) {
                child.flags |= .POWERED;
            } else {
                child.flags &= ~.POWERED;
            }
        }

        if entity_valid(it.last_child) {
            child := entity_get(it.last_child);
            if entity_has_flags(it, .POWERED) {
                child.flags |= .POWERED;
            } else {
                child.flags &= ~.POWERED;
            }
        }
        // Maybe link siblings here
    }
}
