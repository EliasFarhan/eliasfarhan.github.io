---
layout: post
title:  "Rollback (5/13): Fixed timestep and the anatomy of a tick"
categories: [gamedev, cpp]
series: rollback
---

Rollback needs to talk about "frame 542", not "10.42 seconds". That requires a fixed timestep, which requires separating your simulation update from your render update.

<!--more-->

## Fix your timestep

- Standard Glenn Fiedler setup: accumulate real time, run N fixed-size simulation ticks, render whenever.
- Negative feedback loop warning: if a tick is too slow, you accumulate more ticks to catch up, which makes you slower. On a rollback game this is worse, because a rollback frame runs `deltaFrame` ticks at once.
- Choosing the fixed delta time is a tradeoff: shorter tick = more precise simulation but more packets; longer tick = fewer packets but coarser gameplay. Give the actual numbers used in Splash Online and Beach Slap.

![Fixed timestep](/images/2026/rollback/fixed_timestep.png)

## Frame sequencing

- A fixed delta means every tick has an integer index. That index becomes the vocabulary of the whole netcode.
- "Frame 542" is something you can put in a packet; "10.42f seconds" is not.
- This index is also the sequence number of your protocol — see post (11).

![Frame sequencing](/images/2026/rollback/frame_sequencing.png)

## What happens inside one tick

Walk through the diagram step by step:

1. Gather local inputs.
2. Push all inputs (local and remote/predicted) into the rollback manager.
3. If `dirty` — i.e. we discovered a misprediction since the last tick — do the rollback: restore last confirmed state, resimulate up to now.
4. `GameSystems::Tick()` for the current frame.
5. Store the resulting state / checksum for this frame.
6. Send our own inputs out.

![Anatomy of a tick](/images/2026/rollback/tick.png)

- The `dirty` flag is the whole trigger mechanism: nothing rolls back unless a newly arrived input disagrees with what we predicted.

## The rollback (input) manager

- Every player's inputs go through it, including the local player's. No exceptions — the local player must be treated exactly like a remote one, or the resimulation won't match.
- Responsibilities: store inputs per frame per player, hand them back on request, and replicate (predict) inputs for frames that haven't arrived yet.
- Ring buffer sized to the maximum rollback window; decide what happens when a player falls outside it.

![Rollback manager](/images/2026/rollback/rollback_manager.png)

## References

- Fix Your Timestep!, Glenn Fiedler: <https://gafferongames.com/post/fix_your_timestep/>
