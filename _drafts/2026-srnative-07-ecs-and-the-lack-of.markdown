---
layout: post
title:  "Soup Raiders Native (7/11): ECS, and the ECS I decided not to write"
categories: [gamedev, cpp]
series: soupraiders-native
---

Opening hook: the plan was "expand EnTT into a real ECS". I sent four independent surveys through the codebase looking for the populations that would justify it. They found none, separately, and that is the most useful thing this work produced.

<!--more-->

## The yardstick: Anguelov's model, not an archetype ECS

Esoterica is deliberately *not* an archetype ECS, and its vocabulary is what made the audit possible:

| Concept | Definition | What it was in my code |
|---|---|---|
| **Entity** | a container of components + entity systems; no logic beyond activate/deactivate | did not exist |
| **Component** | data only, no virtual `Update` | 6 existed, 3 of them dead |
| **Entity system** | per-entity logic over that entity's components, at a declared stage | **existed, unnamed** |
| **World system** | global singleton; components register with it, so it owns a tight homogeneous array | **existed, unnamed** |
| **Declared update stages** | a fixed, named order the framework enforces | **did not exist — this was the gap** |

The argument Anguelov actually makes: gameplay logic is heterogeneous, branchy and low-count, so dissolving it into views over arbitrary component combos buys nothing and costs ordering clarity. Batching belongs in the few subsystems with genuinely thousands of homogeneous things.

## The measured population, which is the whole argument

| Collection | Peak | Already batched? |
|---|---:|---|
| Static billboards (NPC + talk icon) | **54** docks | ✅ 88 → 3 draws, one SSBO per atlas |
| Dialog trigger volumes | 28 | ✅ flat linear scan |
| Board tile / zone quads | 44 | ✅ flat pool, rebuilt per frame |
| Battle HUD quads / glyphs | ~101 / ~370 | ✅ immediate-mode into 2 SSBOs |
| Battle units, both sides | **14** | ✅ two uniform loops |
| Battle FX pool | 12 | ✅ flat pool |
| Scripted NPCs (Dorothy + guards) | **3** | totally divergent logic |
| Bombs / guards / bosses | ≤6 / 2 / 1 | 4-phase and 8-state `switch`es |

**Nothing clears the bar.** The two collections over 30 already had their world system. The rest is one-off heterogeneous gameplay logic where Anguelov would explicitly leave plain code — which is what it already was.

- ⚠️ And the one time someone narrowed a uniform loop, it shipped a bug: restricting the per-unit action drive to the two "current" units silently stranded any other unit holding an action. **Uniform iteration over the full roster isn't an optimisation here, it's the correctness property.**

## What EnTT actually was before this

- One registry, **one entity, six components, zero views**, 17 call-site lines — three of which exist only to feed a debug log.
- `Transform` / `Velocity` / `Grounded` were **write-only**. No read of any of the three existed anywhere. Deleting them changed no behaviour.
- The app grew **4 491 insertions across 59 files** without a single line touching the registry. It wasn't a model growing slowly; it was a scaffold from the PoC that never took.
- The "genuine handle" in there was a *third* mirror of the player's scene node index — the other two copies live 54 lines apart in the same file.

## Where it actually hurt, and none of it is memory layout

- **Update order: 13 constraints held by comment position.** No declaration, no enforcement.
- **The mode: 21 booleans with no definition of a legal state.**
- **The sprite render binding: six copy-pasted staging tails** (the surveys found four; implementation found two more), and 14 loose `int32_t` node/draw indices that are an un-modelled render binding — already the cause of one hang and two silent wrong-texture bugs.
- **Dorothy is an entity with no entity**: 24 loose members on the app class.
- **Lifetime: four hand-written reset functions, ~120 lines, two shipped bugs.**

## The estimate that was wrong by a factor of thirty

The decision to build one real view rested on "~128 sprite entities". The real population is **four** — the player, Dorothy and two palace guards. Of those 128, **98 were things the same plan separately said not to route through the view**: 54 billboards feeding an SSBO batch, 44 board tiles of a different shape, and the battle pools it explicitly declined to disturb.

If you take one thing from this post: **count the population before you pick the architecture, and count it in the shipping data, not in the design doc.**

## What I built instead

- **Declared update stages** — and it needed **two orders, not one**. Explore runs the camera *after* the simulation, because the mover leans its capsule toward the camera and must read the *previous* frame's pose (Unity does the `LookAt` at the end of `FixedUpdate`). Battle runs the camera *before* the narrative, because the battle owns the camera and the HUD projects through this frame's view-projection. One global order cannot describe both.
- **A deferred mode change**, with a computed `InvalidatesFrame()` — because **not every mode change may end the frame**. Opening a level dialog changes the mode and the frame must *continue*, with movement gated to zero. Only changes crossing the battle boundary invalidate anything.
  - The computed rule found a **fourth** "this call can start a battle mid-frame" site on its first full run. The three known instances all had bespoke hand-written re-checks; this one had nothing. That's the empirical argument for a computed condition over hand-placed guards.
  - ⚠️ And the guard's *placement is its meaning*. It closes the region where a mid-frame entry actually corrupts something. Placed at the bottom of the frame it fired twice for real, and both times the code was right and the assertion was wrong.
- Typed handles, one staging view, a `ScriptedNpc` type for Dorothy, and an entity lifecycle replacing the hand-written resets.

## The view shipped, and it fails its own gate

- The gate I wrote in advance: *if this is the only view, EnTT is carrying ~128 entities and one query and has earned its slot.* It carries **4 entities** (16 after widening to the FX pool), one query, four components.
- It also **added a failure mode the direct calls didn't have**: a view stages *last-published* state, so a hide that isn't published gets undone on the next frame — a battle-hidden sprite comes back on screen over the level.
- I kept it anyway, deliberately, and wrote the rule down: **a second view family needs a measured population argument.**

## Two lessons bigger than the ECS question

- ⚠️ **A green walkthrough does not cover rendering.** Two visual regressions shipped in this work and **both passed byte-identical automated walkthroughs**: characters left unstaged on every battle frame, and a stale sprite binding surviving a level load that destroyed its entity. A log cannot see a sprite frame.
- ⚠️ **And a green walkthrough doesn't cover the routes it doesn't take.** Three full walkthroughs and four swap tests passed clean — every level they visit builds Dorothy. Only a scripted-input run taking the *loss* route reached one that doesn't, and asserted on a dead entity.
- Also found along the way, unrelated and worse: **no battle frame had ever ticked FMOD.** `Studio::System::update()` had exactly one caller, and the battle update returned before reaching it. FMOD is initialised asynchronous, so `update()` is what submits queued commands. Whether that was audible needs an ear, not a log.

## Rules of thumb I'd keep

- Name the concepts you already have before inventing new ones. "Entity system" and "world system" existed; they just had no names.
- The 46 `⚠️` comments in that app aren't a symptom, they're an asset — nearly every one names the defect it prevents. Scope a restructure so none of them has to move.
- Deriving state beats storing it: a one-way derive can't drift the way a stored duplicate can.

## Next

`core::Result`, and exceptions only at startup.
