handle_power_conductivity :: () {
    for *context.entities {
        if !entity_has_props(it, .CONDUIT) continue;

        is_powered := entity_has_flags(it, .POWERED);
        if entity_valid(it.first_child) {
            children := entity_get_child_list(it.handle,, temp);
            for child_handle: children {
                child := entity_get(child_handle);
                if is_powered {
                    child.flags |= .POWERED;
                } else {
                    child.flags &= ~.POWERED;
                }
            }
        }
    }
}
