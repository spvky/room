damper_exact :: (a: float32, b: float32, halflife: float32, delta: float32, eps := 0.00001) -> float32 {
    return lerp(a, b, 1 - fast_neg_exp(0.693147180 * delta) / (halflife + eps));
}

// Fast negative exponent by Danny Chapman sourced from at theorangeduck.com (Daniel Holden)
fast_neg_exp :: (v: float32) -> float32 {
    return 1 / (1 + v + 0.48 * v * v + 0.235 * v * v * v);
}
