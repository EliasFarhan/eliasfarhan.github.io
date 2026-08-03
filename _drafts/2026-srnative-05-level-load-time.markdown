---
layout: post
title:  "Soup Raiders Native (5/11): Level load time — 32.7 s to 3.3 s, and how much of it was a build flag"
categories: [gamedev, cpp]
series: soupraiders-native
---

Opening hook: the worst thing about the game on console was a black screen between islands. I set out to cut it from 18 seconds. It turned out to be 32.7 seconds, and the single biggest win was not an optimisation at all.

<!--more-->

## Start with the measurement, because mine were all wrong

Three separate corrections, in the order I found them:

- **The 18.1 s everyone quoted was a *warm* second visit.** The cold cost was **32.7 s**. Cold boot (65.5 s) had never been measured at all.
- **A desktop number is not a bound.** An earlier note had concluded "the hitch is settled" off ~0.33 s of desktop re-cook and 0.7–1.7 s of desktop texture reload. The console was 10× worse. The mistake was treating a desktop number as a bound.
- ⚠️ **And then the big one: a development-format build reads its assets off the development PC**, over the debug link, rather than off the device's own storage. It boots, it runs, it plays, and it looks exactly like the real thing. The same build loaded the docks in **11.2 s packaged for shipping and 56.3 s in development format**. Every performance number I had taken before that discovery measured a USB cable, and it dwarfed every code change in this post. (More on this in post 10.)
- The habit that came out of it: **compare like-for-like packaging only**, one variable at a time, and date-stamp the boundary so no later table quietly spans it.

## What the load path actually did

- The app side had **zero threading** — no `std::thread`, no `std::async`, no job-system use anywhere. All parallelism lived in the engine's scene load.
- Three main-thread blocks: the app's 22-phase `LoadLevelContent`; the engine's "phase 0" (allegedly fast); and `GpuSetupJob`, which despite the name is scheduled to the main queue and runs as one uninterrupted main-thread block.
- Phase 0's comment claimed "fast: create GPU texture/sampler objects". It wasn't. Per texture it called `ProbeKtx2` → **a full read of the entire `.ktx2` into memory, to read a header**. The docks register ~99 scene textures, so that's 99 whole-file reads serialised through a process-wide filesystem mutex on the main thread *before a single job is scheduled*.

## The waste, itemised

| # | Waste | Extent |
|---|---|---|
| W1 | Every `.ktx2` read in full **twice** — once for a header, once to transcode | docks ~12.0 MB × 2 |
| W2 | Texture registration not deduplicated | 83 material textures from **65 unique paths**; the font atlas registered 3 extra times |
| W3 | Every transition re-transcodes and re-uploads everything | **28 of palace's 34 textures are byte-identical to docks** — 3.63 MB of 5.22 MB, 69% |
| W4 | Shaders and pipelines rebuilt every transition | ~16 shaders + ~13 pipelines, main thread |
| W5 | The font atlas JSON parsed **twice** per level load | 65.7 KB × 2, into a `std::map` |
| W6 | `docks_collision.json` is 3.33 MB — 91% of all JSON parsed per docks load, on the main thread | see post 3 |
| W7 | `UnloadScene` hard-spins on the main thread with an empty loop body | on a core-starved target |

- Plus: the platform's filesystem layer **chops every read into 4 KB**.
- Useful scale figure: the docks are 127.5 Mpx of texels including mips, 70 `.ktx2` files, 13.93 MB of GLB.

## What shipped, and what each thing actually bought

Shipping-format packaging throughout, one variable at a time:

| load (black ms) | after the double-read fix | + 4 KB read bypass | **+ texture dedup** |
|---|---:|---:|---:|
| boot/docks | 11 129 | 8 837 (−20.6%) | **7 645** (−13.5%) |
| docks→palace (cold) | 4 797 | 4 540 (−5.4%) | **3 613** (−20.4%) |
| palace→FishPalace | 4 097 | 3 962 (−3.3%) | **3 051** (−23.0%) |

- **Honestly ranked: the packaging change dominates everything else, and it was a build flag, not an optimisation.** Of the actual code changes, texture dedup beat the 4 KB bypass, which beat the double-read fix on the async phase (the double-read fix's win was in the *synchronous* phase, ~90% of it).
- Also fixed along the way: **a live data race in the Basis transcoder init**, whose failure mode was *silently wrong texels* — exactly what no automated run catches.

## Four confident code-read diagnoses, all killed by measurement

This is the real content of the post.

- **"Move the box3d cook off the main thread."** Measured: 9% of the synchronous half. Rejected.
- **"Two of three workers are spinning."** Verified in source — a job that isn't ready gets re-queued with a `yield()` rather than a condition wait, and two jobs sit in that spin for the whole load. Plausible, specific, and **wrong as a lever**: one worker came within 6% of three, twice.
- **"Mesh import must be expensive."** It is — `AssimpReadFile` is 87% of the import — but the whole thing is 2.65 s across three loads. Rejected.
- **"The archive `open` path duplicates an IO handle, ~30% of read cost."** This was my named suspect and the declared gate on everything else. Zoned: **`Open` costs 0.03 ms, 0.16%.** Dead.
- ⚠️ And the gap that hypothesis existed to explain **was never real**: the ~53 ms/read residual came from comparing means taken over *different call sets* (251 zones vs 410). **A residual computed across mismatched call sets is not a residual.**

## The final attribution, which closes to 0.7%

- Synchronous: 1 310.2 ms of zone against 1 312 ms measured. **99.9%.**
- `CollisionCook` is **87.0% of the synchronous phase**, of which the box3d cook itself is 70.3%.
- File access, fully zoned: `ReadBytes` 51.9%, **`LockWait` 43.6%**, `Exists` 4.2% (a *second* full path lookup on top of the one the open does immediately after, holding the process-wide mutex while it happens — small, but free to delete), `Open` 0.16%.

## The inversion: fix the reads and the bottleneck moves

| | before | after |
|---|---:|---:|
| the file read | **76%** | **25.6%** |
| the Basis transcode (pure CPU) | ~21% | **64.5%** |

- Thread count had been rejected *because* reads sat under one process-wide lock and couldn't respond to it. Now the parallelisable part is the bulk, so the rejected lever is back on the table.
- Measured parallelism: ≈**1.41× on a 2-worker pool** whose ceiling is 2.0×, and the main thread is idle behind a black screen for the whole phase.
- The general lesson: **a rejection is only valid against the composition you measured it in.** Three changes inverted mine.

## Two things nobody had on any list

- **FMOD bank reads are 22.1% of boot** — 1 534.7 ms for four banks, ~36 MB. **The single longest file read in the entire 6:46 run is a bank at 971.2 ms.** And they're read at the worst possible moment: the level content schedules the async texture decode *first*, then the audio init runs, so ~1.5 s of bank reading contends with the texture workers for the same process-wide mutex on a console with one storage path.
- **Pipeline creation is 512 ms per load on the main thread**, rebuilt on every transition — 20 pipelines at a mean of **25.6 ms each**, worst 72.9 ms, 73% of GPU setup and ~15% of the palace swap's black. The engine's own comment had guessed "tens of ms on one pipeline"; it's tens of ms on *all* of them.

## And one thing that turned out to cost nothing

- **Entering a battle: 3.4 ms across six battles.** The additive path appends the battle pools at level-build time, so a fight loads no scene at all. Worth scoping in anyway — it's now measured rather than assumed, and it's off the list for good.

## Where it landed

- docks→palace: **3.3 s of black**. FishPalace: 2.9 s. Boot: ~7 s.
- The target was "under 3 s" and it's met on two of three transitions. The remaining cost is no longer read-bound, so the next move is a different one from the one I planned.

## Next

Rendering: back-face culling, cutout silhouettes and depth sharing — 13.4 ms/frame to 8.98.
