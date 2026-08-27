---
layout: post
title:  "Rollback (2/13): Deterministic simulation and deterministic lock-step"
categories: [gamedev, cpp]
series: rollback
---

If the simulation is deterministic, you stop sending game state and start sending inputs. That single property is what makes everything else in this series possible — and what makes it hard.

<!--more-->

## What determinism means here

- From the same initial state, running the same tick produces exactly the same resulting state — *to the bit*, on every platform.
- Not "close enough". Not "within an epsilon". Bit-identical, on Windows, Linux and Switch, on x86 and ARM.
- Consequence: two machines running the same inputs from the same start are the same game.

## Therefore: send inputs, not state

- The simulation will be identical on every player's device, so the only thing they can't derive locally is what the other players pressed.
- Bandwidth goes from "whole world state" to "a few bytes of buttons". Post (10) is about squeezing those few bytes further.

## Deterministic lock-step: the classic answer

- Age of Empires did exactly this — see Paul Bettner's *1500 Archers on a 28.8*.
- The game waits for every player's inputs before advancing the simulation.
- AoE applies inputs three "frames" later — that offset is *input delay*.
- Works beautifully for an RTS: hundreds of units, and a couple of hundred milliseconds of command latency is invisible when you're ordering archers around.

![Age of Empires lock-step diagram](/images/2026/rollback/lockstep.png)

## Why lock-step doesn't work for Splash Blast Panic or Beach Slap

- You are still waiting for all inputs before you can process and confirm the current frame.
- In a fighting/party/physics game, added input delay is felt immediately — the jetpack doesn't fire when you press the button.
- Cover the usual mitigation (input delay tuned to ping) and why it caps out.

## Where this leaves us

We want lock-step's bandwidth profile without lock-step's waiting. That's rollback — next post.

## References

- 1500 Archers on a 28.8: Network Programming in Age of Empires and Beyond, Paul Bettner: <https://www.gamedeveloper.com/programming/1500-archers-on-a-28-8-network-programming-in-age-of-empires-and-beyond>
