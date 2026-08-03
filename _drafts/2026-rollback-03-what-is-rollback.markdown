---
layout: post
title:  "Rollback (3/13): What a rollback system actually does"
categories: [gamedev, cpp]
series: rollback
---

Rollback netcode — what used to be called GGPO — is one idea: guess the inputs you don't have yet, and rewind when you guessed wrong.

<!--more-->

## The trick

- Don't wait for remote inputs. Predict them, simulate immediately, and correct later if the prediction was wrong.
- Used in Injustice 2, Overwatch, Rocket League, Rivals of Aether.
- Best fit: fast games with few entities. Explicitly *not* an RTS — the resimulation cost scales with entity count.

## Input prediction

- Simplest possible predictor: repeat the last input we received from that player for every subsequent frame.
- Works because a human physically cannot change their inputs every frame.
- Correct roughly 80–90% of the time. (CppCon deck says 90%, ADDON deck says 80% — pick one and be honest that it depends on the game and the tick rate.)

![Input prediction diagram](/images/2026/rollback/prediction.png)

## Misprediction

- The remaining 10–20%: the real input arrives and it isn't what we assumed.
- Everything we simulated since that frame is now wrong.

## The rollback itself

1. Copy the last confirmed frame's state back into the game systems.
2. Compute `deltaFrame = currentFrame - lastConfirmFrame`.
3. For each of those frames: fetch the (now real, or newly predicted) inputs from the rollback manager, push them into the game systems, `Tick()`.
4. You're back at the current frame, with a corrected state, in the same visual frame.

![Rollback diagram](/images/2026/rollback/rollback.png)

- Cost: `deltaFrame` extra simulation ticks in a single frame. This is the CPU budget that decides your maximum playable ping.

## What this demands from your codebase

Foreshadow the rest of the series — rollback is easy to describe and hard to implement, because it requires:

- A simulation state that is cheaply copyable (posts 4, 6).
- A simulation that is bit-deterministic (posts 8, 9).
- Everything decoupled from audio/graphics (post 4).
- A way to know you got it wrong (post 11) and to find out why (post 13).

## References

- GGPO: <https://www.ggpo.net/>
- 8 Frames in 16ms, Michael Stallone, GDC 2018: <https://www.youtube.com/watch?v=7jb0FOcImdg>
