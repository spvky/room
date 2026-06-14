rune_atlas: Sprite_Atlas;

Rune :: struct {
    markings: Markings;
}

Markings :: enum_flags u16 {
    // Crescent
    DO :: 0b0000_0000_0000_0001;
    SO :: 0b0000_0000_0000_0010;
    KO :: 0b0000_0000_0000_0100;
    LO :: 0b0000_0000_0000_1000;
    // Slants
    EL :: 0b0000_0000_0001_0000;
    EN :: 0b0000_0000_0010_0000;
    EK :: 0b0000_0000_0100_0000;
    ET :: 0b0000_0000_1000_0000;
    // Tears
    TI :: 0b0000_0001_0000_0000;
    LI :: 0b0000_0010_0000_0000;
    KI :: 0b0000_0100_0000_0000;
    DI :: 0b0000_1000_0000_0000;
    // Orbs
    TA :: 0b0001_0000_0000_0000;
    DA :: 0b0010_0000_0000_0000;
    // Sun
    SU :: 0b0100_0000_0000_0000;
}

create_rune :: (markings: Markings) -> Rune {
    return Rune.{markings = markings};
}

operator == :: (a: Rune, b: Rune) -> bool {
    a16 := cast(u16)a.markings;
    b16 := cast(u16)b.markings;
    if a16 == b16 return true;
    do_ko_mask: u16 = 0b0000_0000_0000_0101;
    so_lo_mask: u16 = 0b0000_0000_0000_1010;

    if (a16 & do_ko_mask == do_ko_mask && b16 & so_lo_mask == so_lo_mask) || (b16 & do_ko_mask == do_ko_mask && a16 & so_lo_mask == so_lo_mask) {
        a16 &= ~(do_ko_mask | so_lo_mask);
        b16 &= ~(do_ko_mask | so_lo_mask);
        return a16 == b16;
    }

    return false;
}

rune_indices_from_bits :: (rune: Rune) -> [..]int {
    indices: [..]int;
    indices.allocator = temp;
    r := rune.markings;

    if r & .DO == .DO then array_add(*indices, 0);
    if r & .SO == .SO then array_add(*indices, 1);
    if r & .KO == .KO then array_add(*indices, 2);
    if r & .LO == .LO then array_add(*indices, 3);
    if r & .EL == .EL then array_add(*indices, 4);
    if r & .EN == .EN then array_add(*indices, 5);
    if r & .EK == .EK then array_add(*indices, 6);
    if r & .ET == .ET then array_add(*indices, 7);
    if r & .TI == .TI then array_add(*indices, 8);
    if r & .LI == .LI then array_add(*indices, 9);
    if r & .KI == .KI then array_add(*indices, 10);
    if r & .DI == .DI then array_add(*indices, 11);
    if r & .TA == .TA then array_add(*indices, 12);
    if r & .DA == .DA then array_add(*indices, 13);
    if r & .SU == .SU then array_add(*indices, 14);

    return indices;
}

rotate_rune :: (rune: Rune, rot: int) -> Rune {
    if rot == 0 then return rune;

    n := rune.markings;

    for 1..rot {
        ir: Markings;
        // Crescents
        if n & .DO == .DO then ir |= .SO;
        if n & .SO == .SO then ir |= .KO;
        if n & .KO == .KO then ir |= .LO;
        if n & .LO == .LO then ir |= .DO;
        // Slants
        if n & .EL == .EL then ir |= .EN;
        if n & .EN == .EN then ir |= .EK;
        if n & .EK == .EK then ir |= .ET;
        if n & .ET == .ET then ir |= .EL;
        // Tears
        if n & .TI == .TI then ir |= .LI;
        if n & .LI == .LI then ir |= .KI;
        if n & .KI == .KI then ir |= .DI;
        if n & .DI == .DI then ir |= .TI;
        // Orbs
        if n & .TA == .TA then ir |= .DA;
        if n & .DA == .DA then ir |= .TA;
        // Sun
        if n & .SU == .SU then ir |= .SU;

        n = ir;
    }
    return Rune.{markings = n};
}

render_rune :: (r: Rune, position: Vector2, size: Vector2, color: Vector4 = .{0, 0, 0, 1}) {
    for rune_indices_from_bits(r) {
        sprite := sprite_from_atlas(*rune_atlas, it);
        render_sprite(sprite, position, size, color = color);
    }
}
