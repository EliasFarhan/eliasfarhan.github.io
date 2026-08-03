---
layout: post
title:  "Soup Raiders Native (2/11): Porting Unity faithfully — the quirks I reproduced and the ones I refused"
categories: [gamedev, cpp]
series: soupraiders-native
---

Opening hook: a port is not "the same game in another engine". It is a long series of decisions about which of the original's accidents are features. Here is how I made those decisions, and what it cost when I got them wrong.

<!--more-->

## The rule that came first: never reconstruct Unity state by matching names

- Paid for by the docks material fix. Names collide, names are editor-local, names lie.
- Instance names in the palace are not unique — **22 of 30 collide**. Talk icons were matched to NPC parents *by position* at load because of it.
- Read the YAML, resolve the fileIDs, honour prefab instance overrides. A synthesised Unity object silently loses everything its prefab **transform** carried.

## Ground truth is in the project files, not in the docs

- "Meters" is a misnomer: this world is authored at ≈ **0.34 m/unit**. Every physics constant that looks wrong is right.
- Active quality tier is index 6, "Default" — and **every** build target in the project maps to it, so there is one shadow configuration to port, not a matrix.
- The project is **Built-in RP, not URP**. There is no URP package in `manifest.json` at all. Anything reasoning from URP docs is reasoning about a different renderer.

## Worked example: recovering Unity's soft directional shadows

The single best example of "a setting in Unity is an algorithm natively".

- What the data said: `shadowCascades: 1`, `shadowProjection: 0` (CloseFit), `shadowResolution: 1`, `shadowDistance: 80`, light bias `0.05` / normal bias `0.4`, `m_Lightmapping: 4` (Realtime). One cascade is why a single shadow map is an **exact** match, not a simplification.
- **"Looks too hard" was a sampler problem, not a kernel-width problem.** 9 binary `step()` taps against a `NEAREST`, non-comparison `sampler2D` can only produce 10 discrete edge values on texel-shaped stair-steps. No amount of widening fixes that. The answer is a hardware comparison sampler (`sampler2DShadow`, `LINEAR` filters, compare-then-bilinear per tap) — which SDL_GPU already exposed, so it cost zero engine work.
- The kernel is a 45°-slope tent, and it is **platform-dependent**: 7×7 (16 bilinear fetches) on desktop, 5×5 (9 fetches) on the mobile path. Native forces 5×5 **everywhere**, so every build looks the same and desktop Unity's penumbra is very slightly wider than mine by design. The tent's trick is sub-texel fetch placement — each bilinear tap is nudged inside its 2×2 group so one fetch reproduces the correct weighting of the two texels it straddles.
- Unity biases **on the caster only**, never at sample time, and both sliders are scaled by the shadow texel's world size × the filter kernel radius. No slope-scale bias on the caster pass.
- Filtering happens in the screen-space collector, not the lit pass. Natively there is no collector, so the filter moved into the receiver fragment shaders — same result, one pass fewer.
- **Three things that look load-bearing and are not**, each of which cost real time to disprove: `_ShadowOffsets` is spot-light/mobile legacy and never used by directional shadows; `receiverPlaneDepthBias` is always exactly zero because `UNITY_USE_RECEIVER_PLANE_BIAS` is never defined in Unity 6; the Gaussian filter variants in `UnityShadowLibrary.cginc` are dead code.
- Where the source lives is itself a trap — Unity 6 moved CGIncludes to `Editor/Data/Resources/CGIncludes`, and `Internal-ScreenSpaceShadows.shader` ships only in the builtin_shaders zip.
- Two values are **fitted, not read**, and live as ImGui sliders: the fade start fraction and whether the kernel-radius bias multiplier really applies to BiRP. Say so out loud rather than pretending they were derived.

## Quirks I reproduced bug-for-bug

Each one has a code comment naming the decision, so nobody "fixes" it later:

- The cannonball's arc feeds **degrees to radian trig**. The trajectory is wrong and it is the trajectory players know.
- The bomb's parabola with `b = 0`, plus its ~2-unit landing snap.
- The phase-2 bomb's nested damage loop (it double-counts, on purpose).
- `ROLL` repeats and then teleports.
- The rule: if a quirk is visible in play, it is content. Fixing it is a design change, not a port.

## Divergences I chose, and wrote down

- **The collision capsule leans toward the camera**, faithfully — Unity's `CapsuleCollider` rides the transform its `LookAt` drives. Two departures: it pivots about the character's **feet** rather than Unity's `+3.09` collider centre, and it is lifted so its lowest point stays at `position.y` under any lean. Otherwise the rest height, and with it the sprite, rides up and down with the rail camera's elevation (measured at 0.16 u on the docks spawn). Clamped to 45°, because the debug camera's pitch is unclamped and Unity's camera never drops below the character.
- **Movement is analog natively, digital in the original** — Unity returns 9 discrete directions, so traversal speed differs slightly.
- **The battle keeps the deck visible.** Unity's battle camera culls the Default layer entirely (`m_CullingMask 12086`); native renders the battle additively over the live overworld, so battle tiles are lifted `+0.15/+0.18/+0.21` above the anchor and battle sprites are lit with the *docks* constants.
- **The win/defeat banner auto-continues** after 3 s; Unity's press-to-continue gate and its 1.28 s slide are not ported.
- **Island music pauses for a battle and resumes**; Unity restarts it.
- **The HUD shakes with the camera.** Unity moves a render-texture canvas in screen pixels; native converts px → world and offsets the camera, so a world-projected HUD rides along where a canvas HUD does not.
- **The Bearon win resumes DocksTheme** — Unity never switches because it locks into the cut ENDING dialog, so the victory theme would loop over free-roam forever.

## The billboard problems

- The two kinds of billboard are not interchangeable. `LookAt` is **pitch and yaw**, and flattening it is only invisible under a shallow camera.
- Talk icons are *children* of the NPC, and the editor transform is not the runtime one.
- Battle facing has a sign convention and two separate authoring conventions behind it.

## Things I got wrong and how I found out

- Sprites are lit. `MovingCharacter.mat` uses the built-in **Standard** shader (cutout 0.5), so the billboard is genuinely lit in Unity — the old "unlit, lighting baked into frames" comment in my own shader was wrong.
- The camera's `fovY` was fed degrees where radians were wanted, which quietly invalidated every side-by-side comparison until it landed.
- A node's local matrix is `T · S · R` — the scale is applied *after* the rotation. Worth a sentence; it eats an afternoon.

## The takeaway

A divergence you wrote down is a port decision. A divergence you didn't is a bug, and you will find it six weeks later in a screenshot.

## Next

The asset compiler — and why the game stopped being able to read JSON at all.
