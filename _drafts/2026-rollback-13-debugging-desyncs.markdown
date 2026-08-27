---
layout: post
title:  "Rollback (13/13): Debugging desyncs (and the improvements I still want)"
categories: [gamedev, cpp]
series: rollback
---

A desync means the game is over. Not "it looks a bit off" — the simulation is no longer the same game on two machines, and there is nothing to do but stop. All you get to work with is two numbers that don't match.

<!--more-->

## What happens on a desync

- The client that detects a checksum mismatch broadcasts a desync packet to every other client.
- Everyone stops. There is no recovery — the states are no longer comparable, and continuing means two players playing two different games.
- Be honest here: at CppCon 2024 I demoed a build that desynced on stage and I hadn't found it yet.

![Desync](/images/2026/rollback/desync.png)

## Why it's hard

- The only information you have is two 32-bit values that differ, at a frame that is probably long after the actual cause.
- The cause can be anything from this whole series: a forgotten `Rollback`, an uninitialised byte in a struct (padding!), a `float` that slipped into the simulation, a hash map iteration order, a non-deterministic index allocation.

## Tool 1: log every confirm value

- Store the master's checksum per frame in a table — a SQLite table works fine.
- When a client desyncs, it uploads its own log, and you diff the two to find the *first* frame where they differ.
- That frame is where you start looking. Everything after is noise.

![Desync debugging](/images/2026/rollback/desync_debug_1.png)

## Tool 2: checksum per subsystem

- Instead of one checksum for the whole state, compute one per game system.
- Now the mismatch tells you *which* system diverged, which narrows it from "the game" to a few hundred lines.
- Cheap to add, and the single highest-value debugging investment in the whole project.

![Per-system checksums](/images/2026/rollback/desync_debug_2.png)

## Tool 3: check at rollback time

- Do the check when you perform a rollback, not only at the confirm frame: resimulate a frame you already simulated with inputs you already had, and assert you got the same state.
- This catches non-determinism *locally*, on one machine, without needing two clients — by far the fastest iteration loop.

## The bug worth telling

- The bomb system wasn't being rolled back. Result: a visual-only desync — the game state agreed, the screens didn't.
- Found it by setting up two screens side by side, because the checksum was never going to catch a system that wasn't in the checksum.
- Moral: what isn't in your checksum doesn't exist as far as your desync detection is concerned, and the View can still lie to your players.

## Improvements I want

### Rollback to the dirty frame, not the confirm frame

- Store state for every frame in the window, not just the confirmed one.
- On a misprediction at frame D, restore frame D instead of the confirm frame — resimulate fewer ticks.
- Trade: less CPU per rollback, more memory. Given that CPU spikes are what cap your playable ping, this is usually the right trade.

![Rollback to dirty frame](/images/2026/rollback/dirty_frame.png)

### Storing game state efficiently

- Options: full snapshot per frame, delta encoding against the previous frame, or copy-on-write per system.
- Numbers: how big is one frame of Splash Online / Beach Slap state, times the window size.

![Storing game state](/images/2026/rollback/storing_state.png)

### Replay

- If the whole game is (initial state + inputs), then a replay file is just the input log. Nearly free.
- And a replay that desyncs on playback is a deterministic, reproducible bug report — which turns the hardest class of bug in this series into a normal one.

![Replay](/images/2026/rollback/replay.png)

### And a small complaint

Sockets are still not in the C++ standard.

## Conclusion

For a successful fast-paced online multiplayer game:

- A deterministic simulation.
- Rollback on top of a simple, copyable software architecture (ECS-like).
- Checksums, per-system, logged — because you *will* desync, and the only question is how fast you find it.

## References

- Slides: <https://eliasfarhan.ch/CppCon2024> — <https://eliasfarhan.ch/ADDON2025>
- Splash Online: <https://github.com/EliasFarhan/SplashOnline>
- Beach Slap: <https://store.steampowered.com/app/3170110/Beach_Slap/>
