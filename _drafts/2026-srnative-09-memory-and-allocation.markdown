---
layout: post
title:  "Soup Raiders Goes Native (9/11): Fixed-capacity containers, and the heap nobody has ever sized"
categories: [gamedev, cpp]
series: soupraiders-native
---

Opening hook: I converted ~60 container sites to fixed-capacity types, and the most valuable outputs were a UB bug in my own container library and two rules that made most of the conversions unnecessary.

<!--more-->

## The audit

- **277 distinct declaration sites** catalogued behind ~750 raw grep occurrences, across four parallel read-only sweeps of the app and three engine layers.
- `std::string` (2 094 sites) **deliberately excluded** — SSO makes most of them a non-issue and the rest is a different project.
- ~60 sites with a compile-time-knowable bound converted to `SmallVector` / `SmallFlatMap`: rosters and render pools, HUD/dialog quad buffers, FX and tile pools, per-unit paths, trigger volumes, the snap-rail graph, dialog variable tables, per-frame AI/BFS/animation scratch.
- Framing that matters: **general allocation hygiene, not a response to a memory crisis.**

## The tool was broken, and unused

- ⚠️ The plan claimed `SmallVector` was "already used elsewhere in the engine". A grep across four repos returned **zero uses**.
- ⚠️ **`clear()` was UB for any non-trivially-destructible `T`.** Storage is a `std::array<T, Capacity>`, so every slot is a live object and `push_back` *assigns* — but `clear()` and shrinking `resize()` called `~T()` on the live slots anyway, the array destroyed them a **second** time at scope end, and any `push_back` after a `clear()` assigned into a destroyed object. Measured with a lifetime counter: **live count −2 after one clear.** `resize()` also grew past `Capacity` unchecked.
- ⚠️ And the library's own unit test **asserted the broken behaviour**.
- The storage invariant now lives in the header, because it decides whether the container is appropriate at all: `T` must be default-constructible and assignable, `Capacity` objects are constructed up front, and a copy copies all `Capacity` slots.

## `std::flat_map` is not an option, on two independent counts

- One of my target toolchains ships a libc++ old enough to **have no `<flat_map>`**, and every site in scope compiles for it. Same class of problem as the missing header in post 8 — a compile error, not a fallback.
- Independently: it's `std::vector`-backed by default, so it buys **locality, not allocation-freedom** — which was the actual goal.
- Replaced with a `SmallVector` of pairs, linear scan, heterogeneous `find`.

## The plan's value ordering was inverted

- `clear()` retains capacity. So **every member that is cleared and refilled was already allocation-free in steady state** — the quad buffers, the pools, the rosters, the path buffer. Converting those buys inline locality and a truthful comment, not per-frame churn.
- **The real per-frame `malloc` traffic was in the function locals** — the damage-position cells, the AI candidate list, the BFS predecessor map, the hit tallies, and a dozen animation-event scratch buffers. Those were ranked *last* in the plan. Implementation led with them.
- Generalisable: **"it's a `std::vector` in a hot loop" is not a finding. "It reallocates every frame" is.**

## And one "obvious" allocation that wasn't there

- A per-draw uniform override map looked like two heap allocations per draw. It isn't: the map node and inner vector are allocated once per (draw, uniform name) and reused, and the per-call `std::string` key is **SSO'd** — the whole codebase uses **9 distinct uniform names, the longest 13 characters**. Steady-state allocations: **zero**.
- It was still worth converting for locality, and it turned up a real defect the audit had missed: a lookup taking `.data()` off a `string_view`, which is not guaranteed null-terminated. It survives only because every caller passes a literal.
- ⚠️ Its sibling map should **not** go flat: built once per pipeline from shader reflection and holding ~126 scalars, a linear scan would lose to a hash. It needed a transparent comparator, not a different container.

## The one that would have blown up in production

- ⚠️ **The app object was on the stack.** `SmallVector` storage is inline, so the conversion as written would have put ~100 KB into `main()`'s frame — the HUD's two quad buffers alone are 64 KB — against a 1 MB default stack on Windows.
- The app is heap-allocated now, which also removes the ceiling for every future conversion.

## Four places `std::array` is wrong

The "exactly N ⇒ use `std::array`" rule misses the same thing four times: **emptiness is a state.**

- The palace guards are empty off the palace.
- `bossUnits.size() < N` **is** the "not built yet" test.
- The guards' cursor list is rebuilt per frame from the living guards only.
- `facePaths.size() == 6` **is** the is-this-a-cubemap test.

## Capacities measured, not guessed

- The docks carry **28** trigger points, not the 22/23 the plan assumed — the proposed capacity of 32 would have left four slots of headroom. It's 48.
- Max damage-cell footprint **across all shipped content** is 8, so the capacity is 16.
- Two open questions were answerable from the sources rather than by guessing margin: there is no such identifier anywhere in the Unity project for one of them, and a comment in my own header proves the other's bound (a throw takes 1.167 s and its shell lives 0.2 s from t = 0.667 — there is provably never a second one in the air).

## Overflow policy

- `PushClamped` / `InsertClamped`: **assert in Debug, drop + warn-once in Release**, over a non-throwing `try_push_back`. The Debug half earns its keep because the walkthrough and every smoke run are Debug builds.
- **Warn-once is load-bearing** — the log sink is ~100 ms a line.
- ⚠️ **Sites where `N` is a true invariant keep throwing.** A silently dropped BFS predecessor is a *wrong path*, not a missing pixel.

## Two engine-side rules worth more than all the conversions

- **When engine code seems to need a guessed `N`, check whether the API underneath already enforces one.** SDL_GPU's own limits (8 colour targets, 4 uniform buffers per stage, 8 storage buffers per stage) supplied exact bounds for framebuffer attachments and pipeline buffer lists — cited in comments, never included, since they live in a private header.
- **In generic engine code, hoist a reused buffer rather than pick an `N`.** The scene tree's depth-first rebuild allocated a fresh vector *per branch node*, purely to push children in reverse. Children are now appended forward and reversed in place, with the stack hoisted out of the loop: the allocation is **gone**, not bounded. A fixed capacity would have been wrong — "scene-graph fan-out is reliably small" is an assumption about *content*, and this is generic code an editor runs over arbitrary user scenes.
  - Order-equivalence proved differentially over **2 000 random forests / 181 944 nodes** plus star shapes at fan-out 16/100/1500, because the order must keep every parent ahead of its children or transforms compose against a stale parent matrix.

## The half that's still owed: nobody knows what this game allocates

- The console build has **never had its heap configured or measured** — no startup hook anywhere in the repo, no sizing, nothing. It is running on whatever the platform default happens to be, and I have no idea what the game's peak actually is.
- Meanwhile the code's own comments already claim heap-free behaviour that isn't true.
- The plan: `std::pmr` containers bound to *accounting* memory resources, per-category live/peak/count, third-party hooks routed (SDL, ImGui, FMOD, box3d, stb, PhysFS, EnTT — all expose one), reported through Tracy memory pools. **Measure first; arenas are a separate plan written against the numbers.**
  - `<memory_resource>` is available and *links* on every target — checked header, language-version guard and runtime symbol, by the method in post 8, before planning anything on top of it.
  - ⚠️ Callstack attribution is desktop-only; on the constrained target the **categories are** the attribution (post 4).
  - No global `operator new` override, so there is consequently **no process total to check the categories against**. An accepted blind spot, stated rather than discovered later.
- What it is *not*: the heap is **not** a load-time bottleneck. The suspected global-allocator lock serialising texture decode was measured at **0.3%** of texture load time and cleared.
- One symptom worth chasing: the post-battle return to docks measured **31.2 s** against **6.6 s** for the same transition minutes earlier on the same device and build. Fragmentation after a long session of multi-MB decode allocations is one of the few explanations that fits. If that's it, this stops being a measurement exercise and becomes a bug fix.

## Next

Porting to a closed platform — and the trap that invalidated every performance number I had.
