rune_atlas: Sprite_Atlas;

Rune :: struct {
    markings: Markings;
    encircled: bool;
}

operator == :: (a: Rune, b: Rune) -> bool {
    return a.markings == b.markings && a.encircled == b.encircled;
}

operator + :: (a: Rune, b: Rune) -> Rune {
    c: Rune;
    c.markings |= a.markings;
    c.markings |= b.markings;
    c.encircled = a.encircled || b.encircled;
    return c;
}

Markings :: enum_flags u16 {
    // Crescent
    DO :: 1 << 0;
    SO :: 1 << 1;
    KO :: 1 << 2;
    LO :: 1 << 3;
    // Slants
    EL :: 1 << 4;
    EN :: 1 << 5;
    EK :: 1 << 6;
    ET :: 1 << 7;
    // Tears
    TI :: 1 << 8;
    LI :: 1 << 9;
    KI :: 1 << 10;
    DI :: 1 << 11;
    // Orbs
    TA :: 1 << 12;
    DA :: 1 << 13;
    LA :: 1 << 14;
    KA :: 1 << 15;
}

make_rune :: (markings: Markings, encircled: bool = false) -> Rune {
    return Rune.{markings, encircled};
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
    if r & .LA == .LA then array_add(*indices, 14);
    if r & .KA == .KA then array_add(*indices, 15);

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
        if n & .DA == .DA then ir |= .LA;
        if n & .LA == .LA then ir |= .KA;
        if n & .KA == .KA then ir |= .DA;
        n = ir;
    }
    return Rune.{markings = n};
}

rune_contains :: (rune: Rune, markings: Markings) -> bool {
    return rune.markings & markings == markings;
}

render_rune :: (r: Rune, position: Vector2, size: Vector2, color: Vector4 = .{0, 0, 0, 1}) {
    for rune_indices_from_bits(r) {
        sprite := sprite_from_atlas(*rune_atlas, it);
        render_sprite(sprite, position, size, color = color);
    }

    if r.encircled {
        sprite := sprite_from_atlas(*rune_atlas, 16);
        render_sprite(sprite, position, size, color = color);
    }
}
