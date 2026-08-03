---
layout: post
title:  "Rollback (8/13): Floating-point determinism"
categories: [gamedev, cpp]
series: rollback
---

We gamedevs love floats. They're easy and they're fast. They are also the reason your simulation gives two different answers on two machines, and this could be an entire conference on its own.

<!--more-->

## The problem statement

IEEE 754 says what an individual operation returns. It says nothing that stops your *compiler*, your *libm* or your *CPU* from taking a different route to the answer.

## The four sources of divergence

Following Yossi Kreinin's *Consistency: how to defeat the purpose of IEEE floating point*:

- **Algebraic compiler optimisations** — reassociation, contraction, `-ffast-math`. `(a+b)+c` becomes `a+(b+c)` and the last bit changes.
- **"Complex" instructions** — FMA fusing a multiply and an add with a single rounding, available on one machine and not the other.
- **x86-specific pain** — x87 and its 80-bit intermediate results; whether a value stayed in a register or spilled to memory changes the result.
- **Buggy or simply different implementations** — `sin`, `cos`, `sqrt`, `atan2` are not specified to the bit. Different libm, different answer. This is the one that will get you cross-platform (Windows vs Switch).

## Why this is fatal for rollback specifically

- One differing bit in one frame, amplified by a physics integrator, becomes a visibly different game a second later.
- And you don't find out until the checksums disagree (post 11) — far from where it happened.

## What can be done

- Compiler flags: `-ffp-contract=off`, no fast-math, forcing SSE2 over x87. Necessary, not sufficient.
- Never call the standard library's transcendental functions from the simulation. Ship your own.
- SG14 is working on this: **P3375R0** attempts to address it in the standard.
- Sherry Ignatchenko, *Cross-Platform Floating-Point Determinism Out of the Box*, CppCon 2024: <https://www.youtube.com/watch?v=7MatbTHGG6Q>
- At 6it we implemented several deterministic float types — that's what the latest version of Splash Online uses. Describe the approach and what it costs.

![Floating-point determinism](/images/2026/rollback/float_determinism.png)

## The other option

Give up on floats entirely and use fixed-point integers. That's what the first version of Splash Online did, and it's the next post.

## References

- Yossi Kreinin, Consistency: how to defeat the purpose of IEEE floating point: <https://yosefk.com/blog/consistency-how-to-defeat-the-purpose-of-ieee-floating-point.html>
- P3375R0, SG14
