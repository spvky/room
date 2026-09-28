handle_power_conductivity :: () {
    for *context.entities {
        if !entity_has_props(it, .CONDUIT) continue;

        is_powered := entity_has_flags(it, .POWERED);
        if entity_valid(it.first_child) {
            child := entity_get(it.first_child);
            if is_powered {
                child.flags |= .POWERED;
            } else {
                child.flags &= ~.POWERED;
            }
            // array_add_if_unique(*visited, child.handle, handle_compare);
            child = entity_get(child.next_sibling);

            // while child {
            //     if !child break;
            //     if !contains(visited, child.handle) {
            //         if is_powered {
            //             child.flags |= .POWERED;
            //         } else {
            //             child.flags &= ~.POWERED;
            //         }
            //         array_add_if_unique(*visited, child.handle, handle_compare);
            //     }
            // 
            //     child = entity_get(child.next_sibling);
            // }
        }
    }
}

contains :: (a: []Entity_Handle, h: Entity_Handle) -> bool #expand {
    for a {
        if it == h return true;
    }
    return false;
}
