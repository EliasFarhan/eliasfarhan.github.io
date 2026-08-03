---
layout: post
title:  "Soup Raiders Native (6/11): Rendering optimisation — culling, cutout silhouettes, depth sharing"
categories: [gamedev, cpp]
series: soupraiders-native
---

Opening hook: the docks ran at 13.4 ms a frame on the console at 720p, with 16% of frames dropping to 30 fps. Three waves of work later it's 8.98 ms and not one frame of 25 458 misses the refresh interval. None of the wins were clever.

<!--more-->

## The baseline

| GPU zone | before |
|---|---:|
| `frame` | 13.398 ms |
| `Main subpass` | 9.536 |
| `Shadow subpass` | 4.540 |
| `Depth prepass` | 1.000 |
| frames in the 30 fps bucket | **15.96% (3 733)** |

Measured on the target hardware with real GPU timestamps (post 4). Everything below is one variable at a time against that.

## Wave 0: nothing culled anything

- Every pipeline factory set `CullMode::NONE` **by hand**, so all three geometry passes rasterised both sides of every closed surface. Unity culls back faces on every level shader, so `back` is also the *faithful* state — this was a fidelity fix that happened to be free performance.
- Result: frame **13.398 → 11.650 ms (−13.05%)**, shadow subpass −15.96% (it's near-pure geometry with a trivial fragment stage, so it gains most). Dropped frames **15.96% → 2.11%**. Structurally: **p95 went 17.96 → 15.65 ms, inside the refresh interval for the first time.**

### It was blocked by an exporter bug

- The level baker folded each node's world matrix into its vertices and applied the linear part to the normals **without reversing the triangle index order**. Every renderer mirrored with a negative `localScale` baked normals-outward / winding-inward: **24 799 of 164 168 docks triangles — 15.11%** (9.85% palace, 10.59% FishPalace).
- Fixed in the exporter, plus a repair tool run over the committed GLBs in place rather than re-running the whole Unity → Blender → bake → compress chain. A `--check` mode re-reports the count and refuses the asset if it's ever non-zero.
- The repair is only safe because the cause is mirrored *instances*, not authored double-sided geometry — and that was **measured, not assumed**: no triangle in any level shares its three positions with another. 163 triangles sit near the threshold; 162 are sub-pixel slivers and exactly one is real geometry. The tool reports them rather than deciding silently.

### The rules that came out of it

- **A static bake has no runtime equivalent of Unity's per-draw front-face flip**, so the exporter must reverse the indices.
- ⚠️ **The prepass and shadow pipelines must match the main pass.** A prepass rasterising a back face writes a nearer depth that then rejects the real surface.
- Sprites and skybox stay `NONE` — sprite quads take a negative X scale at runtime for mirroring, which reverses winding per frame.
- `FrontFace` needed no assignment at all: SDL_GPU documents a Y-up NDC, implements it with a negative-height viewport, and passes the winding through untouched. This was presented as an empirical unknown and turned out to be a derivation.
- **`--cull` is a startup knob, not an ImGui toggle, and that's structural** — a pipeline is selected through a material index consumed once at scene load, and adding materials perturbs the sort the render pass depends on.

## Wave 1: five pieces, frame 11.650 → 9.310 ms (−20.1%)

### The cutout one (the headline)

- **Every alpha-cutout card is a Unity `Plane` — 200 triangles for what is visually a flat quad.** Together they are **62.7% of the docks' world surface area** (one background rock alone is 42.2%, across twelve cards), and **41% of that area is thrown away by the alpha test.**
- The fix: split each card into `inner` (grid cells where *every* texel passes, eroded one texel — drawn opaque, no texture fetch, no `discard`) plus `band` (the alpha edge, keeping the real test). The union is exactly what the alpha test covered, so the pass is **bit-identical**.
- Triangles: docks **164 168 → 118 712**, palace 66 001 → 57 393, FishPalace 23 242 → 19 948.
- Pixel change on the docks: **0.02%**, in a region measured at 0.00% run-to-run noise.

### The other four

- **The depth prepass was running on two levels for nobody.** Its only consumer is the water's foam depth, and a comment claiming the subpass "is kept empty" had been false since it was written — both levels drew their whole geometry into a full-res D32 target nobody sampled, at ~1.0 ms.
- **The prepass reused the main vertex shader**, which multiplies by the light matrix and writes five varyings no prepass fragment shader declares. A dedicated depth vertex shader is a five-line file.
- **The main pass is now ordered near-to-far**, derived from the camera snap rails. Two backgrounds totalling 59% of the docks' area were drawing at material index 13–16 of 65 and then being overdrawn by everything in front of them.
- **Static NPCs and talk icons became one SSBO batch per atlas per subpass**: docks **88 → 3 draws**, palace 71 → 3.

### Wave 1's traps

- ⚠️ **The planarity gate wasn't sufficient.** Five materials were already 2-triangle quads and got inflated **38×** until a "must reduce triangles" rule was added.
- ⚠️ **Prefer patching the committed asset to re-baking it.** The docks GLB was originally converted with Blender 2.83; a fresh 4.1 conversion keeps 97.9% of vertex positions but **moves 42% of vertex normals by >1° (max 120°)**, visibly reshading roofs and beams — 3.5% of a frame, larger than anything this work does. Re-baking a level is a content decision that needs its own A/B.
- An outer-hull variant serving the depth-only passes was **built, measured and rejected**: 11.9% of the palace frame repainted with squared-off shadow slabs.
- ⚠️ **One real bug logged nothing.** Merging the talk-icon slot into the NPC manifest rebased each icon's *clip* index but not its *batch* index, so every icon kept batch 0 — the NPC batch after the merge. The icons vanished and 54 records were copied into a 34-record buffer. Instance counts were right, the level rendered, the swap test passed, the material-order verifier was clean. **Caught only by cropping the same band out of a before/after screenshot.**

## Wave 2: depth sharing, frame 9.310 → 8.980 ms

```
prepass  ->  scene_depth
COPY         scene_depth -> backbuffer depth     (the one new engine capability)
main     ->  swapchain colour + backbuffer depth, load op LOAD
water    ->  samples scene_depth                 (unchanged)
```

- ⚠️ **The copy costs 0.498 ms and eats ~60% of the gross win.** A full-res 1280×720 D32 blit, pure bandwidth — mean 0.498, median 0.498, max 0.506. **Not a penalty of the design I picked**: the alternative would have paid exactly the same, because the water samples the depth the main pass draws against and SDL forbids sampling an attached texture.
- Non-negotiable detail: the depth format had to become stencil-free `D32_FLOAT` on every platform, because a depth-to-depth image copy needs *identical* formats.
- ⚠️ **The depth states belong at the pipeline call sites, not in the factory.** The docks pipeline factory also builds the player sprite and every batched NPC — neither of which is in the prepass — so both must keep writing depth or they stop occluding each other.
- ⚠️ **Where a per-scene reset lives decides whether the first load lies to you.** The scene manager calls `UnloadScene()` on the outgoing scene *after* the caller has configured the incoming one. Resetting in `UnloadScene` wipes the setting just made — and the *first* load, where there's nothing to unload, works fine. Correct on a direct boot, silently broken on every swap. A four-way level-swap test is what proves it.

## Measuring a rendering change is harder than making one

Both failure modes fail *toward passing*.

- Unity's `Graphics.CopyFromScreen` **cannot read a Vulkan swapchain** — it returned the ImGui overlay correctly and the entire 3D world black, in every configuration. Two such captures compare as identical.
- The engine's own screenshot API **segfaults**: it downloads from the swapchain texture, which SDL's Vulkan backend creates with colour-target usage only. That API had no consumer anywhere, which is why nobody had found out.
- What works: `PrintWindow` + `PW_RENDERFULLCONTENT`. **And always look at the image, not just the diff number.**
- ⚠️ **Captures aren't frame-deterministic, so a control pair is mandatory.** Settling is wall-clock, which leaves ~15% of a docks frame time-dependent (water, sprite, rail camera). Excluding only the differing pixels isn't enough — a foam pixel that happens to match in the control leaks through. **4 155 apparent differences collapsed to 12 real ones** as the exclusion radius went 0 → 12 px. Wave 2's real figure is 12 px of 552 193 (0.0022%), all isolated singletons: the absence of a contiguous blob is the positive evidence that no geometry went missing, which is the failure mode this change actually has.

## Rejected, with reasons

- Merging the shadow pass into spatial chunks — the light box has radius ~69 against a level spanning ~200, so a coarser cull rasterises more than the binds save.
- Cheapening the PCF filter — it's a faithful transliteration of Unity's 5×5 tent, so any reduction is a fidelity divergence (post 2).
- A 1024² shadow map — that's a knob, not a plan.
- **Docked 1080p is out of scope, with arithmetic**: the main pass alone goes 9.1 → ~20.5 ms at 2.25× the pixels, plus prepass and shadow, so ~26.6 ms against a 16.67 budget. Docked needs a PCF cut and/or dynamic resolution as its own work.
- Still on the table: giving the water its own subpass with no depth attachment, sampling depth directly and rejecting in its own shader — **zero copies**, roughly doubling wave 2's win. Set aside as needing more engine surface than it was worth at the time; at 0.5 ms of measured copy that trade looks different now.

## Sidebar: texture compression (KTX2/Basis)

- ⚠️ **Block compression needs multiple-of-4, not power-of-two.** Different constraint, commonly conflated.
- ⚠️ **The real atlas hazard is cells sharing a compression block**, not the atlas being large.
- ⚠️ **A silent gamma conversion** is waiting for you if the transfer function isn't assigned explicitly at bake.
- The black fringe around sprite atlas cells **is the art**, not a matting bug — do not dilate over it.

## Next

ECS — and why four independent surveys of my own codebase concluded I shouldn't write one.
