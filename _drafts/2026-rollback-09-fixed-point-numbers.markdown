---
layout: post
title:  "Rollback (9/13): Fixed-point numbers"
categories: [gamedev, cpp]
series: rollback
---

An integer with an agreed-upon binary point. Integer arithmetic is bit-identical everywhere, so if the whole simulation runs on fixed-point, cross-platform determinism stops being a worry and starts being a property.

<!--more-->

## The representation

- A fixed-point number is an integer whose value is scaled by a fixed power of two.
- Example from the talk: a `std::int32_t` with an exponent of 16 — 16 bits of integer part, 16 bits of fraction. The stored integer `-81921` is a value, not a count.
- *You* choose the underlying integer type (`int8/16/32/64`, signed or unsigned) and the exponent. Precision and range are a design decision per use case, not a given.

```cpp
template<typename T, int Exponent>
class Fixed
{
    T value_;
public:
    constexpr Fixed(float f);   // convenient, but keep it out of the hot path
    constexpr Fixed(int i);
    // ...
};
```

![Fixed-point number](/images/2026/rollback/fixed_point.png)

## The operations

- `+` and `-`: trivial, just integer addition/subtraction — the exponents already line up.
- `*`: cast up to the wider type (`int32` → `int64`), multiply, then shift right by the exponent.
- `/`: cast up to the wider type, shift left by the exponent, then integer-divide.
- Overflow is now *your* problem, and it's a silent one. Talk about how you catch it (debug asserts, saturating variants).

![Fixed-point operations](/images/2026/rollback/fixed_point_ops.png)

## The missing functions

You don't get `sqrt`, `sin`, `cos`, `atan2` for free. Three options:

1. Implement a formula (Newton-Raphson for `sqrt`, CORDIC or polynomial approximations for trig).
2. Build a lookup table with all the values.
3. Generate that table with a script — I used Python to emit the array.

- On the LUT: `#embed` would have been nice here (C23, and C++26). Currently a generated header.
- Tradeoff: LUT size vs precision vs cache. Give the actual numbers used.

![Fixed-point LUT](/images/2026/rollback/fixed_point_lut.png)

## Living with fixed-point

- Everything in the simulation must be fixed-point; the moment one float sneaks in, determinism is gone.
- Conversion happens only at the View boundary (post 4) — fixed-point in, float out, never back.
- It also gives you free input compression, since a `fixed8` is one byte. See post (10).
- Honest downsides: readability, debugging (your watch window shows `-81921`), and the constant fear of overflow.

## Fixed-point or deterministic floats?

Splash Online v1 used fixed-point; the current version uses 6it's deterministic floats. Compare: implementation effort, performance, precision, and how much of the codebase each one touches.
