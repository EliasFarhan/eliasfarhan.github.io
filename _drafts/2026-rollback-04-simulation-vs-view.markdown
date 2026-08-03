---
layout: post
title:  "Rollback (4/13): Simulation state vs view state"
categories: [gamedev, cpp]
series: rollback
---

The state you rewind and the state you look at are not the same state. Getting this separation wrong is exactly how I failed the first time.

<!--more-->

## Super Mario 64 as the illustration

- SM64 runs its physics on short integers while the graphics use floats.
- Integer overflow produces the "parallel universes" that speedrunners jump between — see pannenkoek2012, *Watch for Rolling Rocks - 0.5x A Presses*.
- Perfect proof that the internal simulation state and the thing on screen are different objects with different rules.

![Parallel universes in SM64](/images/2026/rollback/sm64_parallel_universes.png)

## An MVC-shaped architecture

- **Controller** — player inputs, local or from the network.
- **Model** — the rollback manager plus the internal game state (gameplay + physics). Must be deterministic.
- **View** — audio and graphics. Does *not* need to be deterministic.

![MVC-like architecture](/images/2026/rollback/mvc.png)

## The one rule for the View

- The View only *reads* the Model.
- Game systems must never depend on the View. No "the animation finished, so apply damage". No "spawn the explosion prefab, which happens to carry the hitbox".
- Corollary: the View can interpolate, lag, run at any framerate, and be wrong — none of it can desync the game.

## What went wrong in Splash Blast Panic

- Player character was one object: gameplay + physics + graphics + audio.
- Spawning a visual effect, a sound and a gameplay entity were the same call.
- So there was no state to copy, no boundary to rewind to, and interpolation/extrapolation was the only option left. It didn't work.

![The wrong way](/images/2026/rollback/the_wrong_way.png)

> Detail worth keeping: dash and stomp were the same action, renamed. Small example of how tangled that object had become.

## What this buys you

- The View can read a state that was just rewound and resimulated in the same frame and simply render the result.
- Non-deterministic things (particles, audio timing, screenshake) are free — they live outside the Model.
- Caveat for post (13): a system that is *visually* driven but forgotten in the rollback produces a visual-only desync, which is a real bug I shipped.

## References

- pannenkoek2012, *Watch for Rolling Rocks - 0.5x A Presses (Commentated)*
- Game Programming Patterns, Robert Nystrom: <https://gameprogrammingpatterns.com/>
