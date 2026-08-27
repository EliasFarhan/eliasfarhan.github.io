---
layout: post
title:  "Soup Raiders Goes Native (11/11): The future "
categories: [gamedev, cpp]
series: soupraiders-native
---

Now that my CppCon talk is finally done, what is going to happen to Soup Raiders 3rd iteration?

<!--more-->

## Where it stands

- The whole demo arc runs natively: docks → tutorials → palace → the Dupont arc → FishPalace → the Red Bearon, both outcomes routed, on all four target platforms.
- 720p on the console is inside the frame budget with margin (post 6). Load times are ~3 s between islands (post 5).
- What that *isn't*: new content. Every level, every dialog, every battle roster in the native build came out of the Unity project through an exporter.

## How content gets in today

A chain of Python tools sitting between the Unity project and the game:

- the level baker (geometry, materials, collision), the snap-rail camera exporter, the flipbook exporter, the yarn compiler, the texture compressor, the cutout silhouette splitter, the material order tool
- → JSON intermediates → **the asset compiler** (post 3) → binary → the packer → five archives.
- It works. It also means keeping a Unity install pinned to an exact version as an authoring tool for a game that no longer runs in Unity.

## Option A: keep Unity as the level editor

**For:**
- It already works, and it's the tool artists know. Scene layout, prefabs, the transform hierarchy, the camera snapshot graph — all of it authored in an editor I did not have to write.
- The asset compiler is a clean seam: anything that emits the 16 schemas is a valid front end. Unity is just one.

**Against:**
- ⚠️ Every editor upgrade is a re-validation of the whole chain. The exporters have not been run since the last version bump, and "the editor opens" is not the test.
- ⚠️ The pipeline has silent failure modes by construction. A stale manifest paired with a fresh atlas produces garbled output and no error; the version gate is the only thing that catches it. Every one of those gates exists because something got through once.
- Anything Unity doesn't model has to be side-channelled into a JSON file with no editor support, which is how you end up hand-editing coordinates.
- And it's a dependency on a company's licensing decisions for a project whose entire point was owning the stack.

## Option B: build my own editor

This is the other half of Neko3d — the computer graphics editor I've been writing about separately.

What it would actually have to do before it replaced Unity here:

- **Scene authoring**: transform hierarchy, prefab-equivalent instancing, the camera snapshot graph, trigger volume placement.
- **The asset back end already exists.** The compiler, the schemas, the header/version/staleness machinery — that's done, and it's the hard part nobody thinks about.
- **Hot reload**, which is a handle-system property more than an editor feature (generational handles, indices + generations + validation).
- **Serialization and reflection**, which is the real question: today it's hand-written `serialize()` per struct. The options are macros, an external code generator, or waiting for C++26 reflection (P2996) — and even that doesn't remove everything that has to be done by hand.
- Honest cost estimate here. This is a year of evenings, and it competes directly with making a game.

## Option C: neither

- The demo was a demo. The port was the point. The engine now has a shadow implementation, an asset pipeline, a job system, a console backend and a profiler — all validated against real content instead of a test scene.
- The next thing could be a *different* game on the same engine, and Soup Raiders stays what it is: the best test corpus I've ever had.
- Worth saying out loud rather than letting it happen by default.

## What I want either way

- **The asset compiler is the seam and it should stay the seam.** Whatever authors content, the game reads sixteen versioned binary schemas and nothing else.
- **More work moves to bake time.** Pre-welded collision, resolved indices, flattened tables — the compiler is where load-time cost goes to die and I've barely used it for that yet (post 3).
- **The measurement discipline stays.** Every claim in this series is a number from a device, and about a third of the things I was certain about turned out to be wrong (posts 5, 7, 9). That habit is more valuable than any of the optimisations.

## The list I owe a human

Because a series like this makes a project look tidier than it is:

- The heap: never sized, never measured.
- The swapchain image count: nothing sets one.
- A thread sanitizer run: has never happened.
- A 1080p docked pass: out of scope, with the arithmetic that says it needs its own work.
- The docks water renders solid orange in one route, and has no bug report yet.
- And a long list of things that need eyes on pixels, because no automated run substitutes for looking at the screen. If there's one theme in this series, it's that.

## Closing

- What I'd tell someone considering the same thing: port a game you know, keep a written list of your divergences, and measure on the target platform before you believe anything.
- Where to follow the engine work: the computer graphics editor posts.
