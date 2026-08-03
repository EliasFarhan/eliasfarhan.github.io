---
layout: post
title:  "Rollback (1/13): Why fast-paced online multiplayer is hard"
categories: [gamedev, cpp]
series: rollback
---

Opening hook: I shipped Splash Blast Panic in 2018 without online multiplayer, because I tried to add it and failed. This series is the writeup of what I learned building it properly the second time, from my CppCon 2024 and ADDON 2025 talks.

<!--more-->

## The series

- (1) Why fast-paced online multiplayer is hard
- (2) Deterministic simulation and deterministic lock-step
- (3) What a rollback system actually does
- (4) Simulation state vs view state
- (5) Fixed timestep and the anatomy of a tick
- (6) ECS-like game systems, or how to make state copyable
- (7) Physics engines and deterministic indices
- (8) Floating-point determinism
- (9) Fixed-point numbers
- (10) Input compression
- (11) The confirm frame and the Adler-32 checksum
- (12) Creating and destroying game objects inside the time window
- (13) Debugging desyncs (and the improvements I still want)

## How I got here

- Splash Blast Panic (2018, Steam / Xbox One / PS4 / Switch): local multiplayer, physics-based movement, jetpack + watergun, cartoony characters.
- Tried to bolt online onto it with Unity + Photon PUN, with interpolation/extrapolation, after a year of development. Failed miserably — unplayable online even in good conditions.
- Root cause was architectural, not networking: the player character was a single object mixing gameplay, physics, audio and graphics. Spawning a VFX and spawning a hitbox were the same code path.
- Splash Online (2024): C++20 reimplementation of the core gameplay for PC and Switch. SDL2, Spine, Photon, FMOD, Dear ImGui. Repo: <https://github.com/EliasFarhan/SplashOnline>
- Beach Slap: the commercial game where these ideas got their second, better iteration. <https://store.steampowered.com/app/3170110/Beach_Slap/>

> Note to self: possible sidebar about the `Timer` class and non-type template parameters — wanted a compile-time period, my own type wasn't structural, `float` NTTP worked on MSVC but not clang 17, so I ended up with integer milliseconds plus a dividend. Maybe cut, it's a C++ anecdote rather than a rollback one.

## What "fast-paced" means

- Fighting games, FPS, football-with-cars, anything physics-driven at low latency.
- Contrast with an RTS: many entities but tolerant of input delay. Fast-paced is the opposite — few entities, zero tolerance for delay.

## Problem 1: latency is made of four things that add up

- Propagation delay — speed of light, non-negotiable.
- Processing delay — every router on the path handles the packet.
- Queuing delay — your packet waits behind other packets.
- Transmission delay — bandwidth limit.
- They accumulate into the latency budget you have to design around.

## Problem 2: you are always simulating with inputs from the past

- Unlike local multiplayer, this delay has gameplay consequences.
- *Current frame*: where the local player is right now.
- *Last confirm frame*: the most recent frame for which you have every player's real inputs.
- You may hold some inputs from other players in between, but only the confirm frame has all of them.
- That window between confirm frame and current frame is the whole problem. Everything in this series is about what you do inside it.

![Confirm frame and current frame diagram](/images/2026/rollback/confirm_current_frame.png)

## Problem 3: what do you even send?

- Sending the whole internal game state every frame is the naive answer and it doesn't scale.
- Goal is to minimise bytes on the wire — which leads directly to the next post.

## Next

Deterministic simulation, and why it lets you send almost nothing.

## References

- 8 Frames in 16ms: Rollback Networking in Mortal Kombat and Injustice 2, Michael Stallone (NetherRealm), GDC 2018: <https://www.youtube.com/watch?v=7jb0FOcImdg>
- It IS Rocket Science! The Physics of Rocket League Detailed, Jared Cone (Psyonix), GDC 2018: <https://www.youtube.com/watch?v=ueEmiDM94IE>
- Overwatch Gameplay Architecture and Netcode, Timothy Ford (Blizzard), GDC 2017: <https://www.youtube.com/watch?v=W3aieHjyNvw>
- Slides: <https://eliasfarhan.ch/CppCon2024> and <https://eliasfarhan.ch/ADDON2025>
