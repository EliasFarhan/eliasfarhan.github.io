---
layout: post
title:  "Soup Raiders Native (1/11): Rebuilding a cancelled Unity game in my own C++ engine"
categories: [gamedev, cpp]
series: soupraiders-native
---

Opening hook: in December 2024 I wrote that Soup Raiders was over. In 2026 I came back to it — not in Unity, but as a native C++23 port on my own engine. This series is the writeup of that port.

<!--more-->

## Where the project was

- Soup Raiders: action-tactical-RPG, hand-drawn characters in a 3D world, Team KwaKwa. Demo on itch.io.
- Second version cancelled — link back to the [2024 post](/2024/12/23/soup-raiders-pause.html). Team dispersed, project shelved.
- I went and shipped other things (Beach Slap, Splash Online). Both of those taught me the C++ side.

## What the port actually is

- Target: **Neko3d**, my in-house C++23 engine — the same engine as the computer graphics editor I've written about.
- Replacing Unity piece by piece:
  - rendering/engine → Neko3d (SDL3 GPU backend + a Vulkan 1.4 backend)
  - physics → box3d
  - gameplay → EnTT, deliberately tiny (see post 7)
  - audio → **FMOD, unchanged** — same Studio project, same `.bank` files as the Unity build
- PoC (M0–M3) was one thing: a billboard-sprite character walking around `Level_docks`. Done 2026-07-06.
- Everything after that was scope growth on purpose. Today it plays boot → docks → tutorials → Seagulls → palace → the Dupont arc → push combo → FishPalace → the Red Bearon, both outcomes routed.

## What runs today

- Three levels: `Level_docks`, `Level_palace`, `Level_FishPalace` — rendered, walkable, baked collision, fade transitions.
- Snap-rail cinematic camera (the Unity original's editor-authored snapshot graph), `F1` for a free orbit debug camera.
- Water, skybox, per-level lighting, realtime directional shadows, static NPCs, positional ambients, island music.
- The YarnSpinner dialogs, played by a custom yarn compiler and a small C++ interpreter — no YarnSpinner dependency. This is also the first text/UI/glyph rendering in the repo.
- The whole GroundBattle system: initiative, every attack type, switching and combos, AI, VFX, HUD, both bosses, the tutorial chain.
- Platforms: Windows, Linux, macOS (Metal) and Nintendo Switch.
  - ⚠️ *Note for the rest of the series: console work is under NDA, so nothing beyond that line is going to be said about it. Where a post needs a constrained target to make sense, it says "the console" and stops there — no SDK, no tooling, no platform specifics.*
- Every asset read through PhysFS; five shipping archives.

## What stays cut, deliberately

- ENDING slideshow, `DemoVictory` credits, `DemoIntro`, TitleScreen.
- NavalBattle (the hex boat system) and open-water sailing.
- Baked-lightmap rendering, mouse input, Japanese text and localisation, EXPO mode, the pause menu, save/load of progression (session-only), every non-demo battle roster.
- Point worth making: a port's scope is a *list*, and the list has to be written down before it's a decision instead of a drift.

## Why do this at all

- The honest version: I wanted to own the decisions. In Unity a cascaded shadow is a setting somewhere; natively it's an algorithm you have to go and recover (post 2).
- One codebase I can profile end to end, on the platform I actually care about.
- A game I know intimately is the best possible test corpus for an engine — every feature request comes from real content, not from a wishlist.
- Counter-argument to be fair about: this is months of work to arrive at a game that already existed. The output is the engine and what I learned, not a better Soup Raiders.

## What this series is not

- Not "custom engines are better than Unity". They're not, for most people, most of the time.
- Not a tutorial. Every post is a measurement or a mistake.

## Next

Porting Unity faithfully — what I copied bug-for-bug, and what I deliberately let diverge.
