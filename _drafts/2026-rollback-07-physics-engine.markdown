---
layout: post
title:  "Rollback (7/13): Physics engines and deterministic indices"
categories: [gamedev, cpp]
series: rollback
---

The advice from the talk was blunt: don't use an off-the-shelf physics engine. Beach Slap is the counter-example that proves it, and Rocket League is the exception that explains it.

<!--more-->

## Why third-party physics engines fight you

- They own internal state you can't snapshot: broadphase structures, contact caches, warm-starting data, allocator state, internal IDs.
- Box2D is the concrete case: no supported way to copy the world's internal state, so there is nothing to roll back to.
- Even if you can restore positions and velocities, the solver's *history* is part of the simulation result. Restoring half the state gives you a simulation that diverges slowly, which is the worst kind of desync to debug.

## Write your own, with state copy as a first-class feature

- Design goal from day one: `PhysicsWorld` must be copyable and restorable.
- Scope it to what the game needs — Splash Blast Panic-style movement is not a AAA physics feature list.
- Rocket League is the counter-example at scale: they use a modified version of Bullet3. Modified being the operative word.

![Physics engine](/images/2026/rollback/physics_engine.png)

## Indices instead of pointers

- Bodies are referred to by `BodyIndex`, not `Body*`.
- Creation must be deterministic: if you create three bodies in two copies of the `PhysicsWorld`, both must produce the same `BodyIndices`.
- Pointers break under copy (they alias the source world). Indices survive a memcpy for free.
- Same argument as the ECS entity index in post (6) — this is the same idea applied to physics.
- Free-list / recycling policy has to be deterministic too, otherwise creation order after a rollback diverges.

![Using indices as pointers](/images/2026/rollback/indices.png)

## What Beach Slap did

- Describe what using a physics engine cost on Beach Slap and what the workaround/rewrite looked like. This is the part readers will want most — be concrete about the pain.

## Determinism inside the solver

- Iteration order over bodies and contacts must be fixed. Anything hash-map-ordered or pointer-address-ordered is a desync.
- Which leads straight to the arithmetic itself — post (8).
