---
layout: post
title:  "Rollback (12/13): Creating and destroying game objects inside the time window"
categories: [gamedev, cpp]
series: rollback
---

A bullet fired on a mispredicted frame is a bullet that never existed. Creation and destruction are the two operations that don't survive a rewind naively, and the fix starts with not doing them at all.

<!--more-->

## First answer: don't create or destroy anything

- Pre-allocate a pool of game objects, each with an active/inactive flag.
- "Spawning" is flipping a flag on an existing slot; "destroying" is flipping it back.
- The pool is a flat array of PODs (post 6), so the whole thing is still a memcpy to roll back.
- This covers most of what a fast-paced game needs — bullets, particles-with-gameplay, pickups.
- Cost: a fixed maximum count, and you have to pick it. Say what happens on exhaustion (and make it deterministic!).

## When you really do need create/destroy

Creation inside the window between the confirm frame and the current frame is **temporary** — that object might turn out to never have existed.

- Keep the created object flagged as temporary until its creation frame is confirmed.
- On rollback past the creation frame: actually delete it.
- On confirmation of the creation frame: promote it to a normal object.
- The index/handle assigned must be deterministic (same argument as post 7), otherwise a resimulation assigns different indices and everything downstream diverges.

![Creating game objects](/images/2026/rollback/create_object.png)

## Deletion is the mirror image

- Deletion inside the window is also temporary — the object may need to come back.
- Keep a temporary list of "deleted" objects rather than freeing them.
- On rollback past the deletion frame: restore them.
- On confirmation: actually free.

![Deleting game objects](/images/2026/rollback/delete_object.png)

## Things that bite

- Any container whose iteration order depends on allocation (hash maps, pointer-keyed sets) turns "temporarily created" into "permanently desynced".
- Objects created by the View must never enter this machinery — spawn the explosion sprite, not the explosion entity (post 4).
- Test case worth building: force a rollback that spans a creation *and* a deletion of the same object.
