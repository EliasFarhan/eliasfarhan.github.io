---
layout: post
title:  "Soup Raiders Goes Native (10/11): Porting to a closed platform, and the trap that invalidated every number I had"
categories: [gamedev, cpp]
series: soupraiders-native
---



<!--more-->

Console platforms constrained:
- Access to filesystem (load/save)
- Inputs
- Network (important for profiling)

Advantages:
- Knowing exactly the CPU and GPU (specific optimization enabled)
- Documentation

*Everything about the platform itself is under NDA — the SDK, its tooling, its APIs, its hardware. So this post is about the parts that would be true of any closed platform, and about the mistakes, which were all mine.*

## Three plans, split on purpose

- **Build system** — cross-compile, link, package a loadable image.
- **Engine port** — the whole application links, with every third-party dependency.
- **Runtime port** — assets, network, profiler, command line; what it takes to actually run.
- The split is at a real seam: **the compile-and-link surface is almost entirely third-party build wiring, while the runtime surface is almost entirely first-party filesystem/input/memory work.** Two very different kinds of work, and interleaving them makes both harder to reason about. If you only take one structural idea from this post, take that one.

## Why I cancelled a build-system migration to do it

- I had a whole plan to move off CMake, and its entire reason to exist was one sentence: *"vcpkg has no triplet for this platform."*
- That is true of vcpkg — and it always will be, since console tooling is NDA-gated and vcpkg is a public port registry — but it is **not true of CMake**. The platform ships a documented command-line pipeline (compiler, archiver, linker, plus image-authoring tools) that any build system can drive. That is exactly what a toolchain file is for.
- The port drops vcpkg for that target anyway, so the stated blocker evaporated. The migration was **cancelled, not deferred**.
- Generalisable: **check whether your blocker is a property of the tool you're replacing, or a property of the thing you're porting to.** Mine was the former, and I nearly spent a month on it.

## What went right, so you know where the surprises weren't

- **Every translation unit compiled first try.** The only failure in the entire engine port was three undefined symbols from ImGui's shell helper.
- Binary size was flagged as a risk and is a non-issue: ~6 MB of code with assimp, libktx, SDL, FMOD, box3d and ImGui all statically linked.
- The job system and the engine core cross-compiled unchanged. Most of the "untested first-party pieces" risk closed with no work at all.
- Worth writing down when it happens. A risk register that only records what went wrong teaches you to over-estimate the wrong things.

## The single real bug was in my own CMake

Worth the whole section, and it has nothing to do with the platform.

- A helper dispatched `if(MSVC) ... elseif(UNIX)` to locate host shader tools. Under a cross toolchain, **`WIN32`, `UNIX`, `APPLE` and `MSVC` are all false**, so neither branch ran and the tool paths stayed empty.
- **CMake silently drops an empty `VERBATIM COMMAND`** rather than erroring. Every shader rule collapsed to its `make_directory` step, ninja reported all **324 steps successful**, and the staged data directory came out with **zero compiled shaders**. Nothing said a word.
- Fixed by dispatching on the *host* platform — these are host tools, so the dispatch was on the wrong axis — plus a configure-time `FATAL_ERROR` if either tool is missing.
- **That guard is the real fix.** The defect wasn't a wrong path; it was that a build rule was allowed to exist with no program behind it.
- The general rule that came out of it: **every platform-dispatching `if()` in a cross-compiling project needs an explicit branch for the new target, and a failing `else`.** I'd written that rule down before this happened. Writing it down is not the same as applying it.

## Third-party wiring, and one rule about it

- The platform port of SDL is an **overlay, not a fork** — a dozen platform sources and a build config, no copy of SDL itself. So my CMake **parses its project file at configure time** rather than restating a 177-entry source list that would rot on the first bump. Generating your build inputs from the vendor's own manifest beats transcribing them.
- ⚠️ **Pin the upstream to an exact release.** A later tag resolved all 177 paths and compiled clean, then **failed at link** on a symbol upstream had added after the overlay's last sync. **A file list resolving is necessary but not sufficient; the real compatibility test is a link.**
- That's also why the on-hardware check app calls into SDL's video and audio driver enumeration rather than something simpler: those walk the bootstrap tables and drag the platform backends into the link, where a broken port would otherwise sail through a build.
- PhysFS self-gates on predefined platform macros and compiled cleanly; its own build script doesn't survive a cross toolchain, so it got a thin first-party wrapper. **A library being portable and its build system being portable are two different claims.**
- FMOD ships static archives on this target, so the desktop "copy the shared library" build step becomes a **no-op rather than being absent** — a difference that matters when someone later asks why the step exists.
- ⚠️ The documented link recipe was **incomplete**. Two required inputs weren't in it, and nothing links without them. Vendor docs are a starting point, not a specification.

## The runtime shape that's genuinely different

Stated at the level of "things that are true of constrained platforms generally":

- **There is no working directory.** Every asset mount had to resolve against the filesystem's base directory rather than a relative path — and on that target the base directory is a read-only mount that the filesystem layer establishes for itself during init.
- ⚠️ And SDL's base-path implementation establishes the *same* mount under the same name, so calling `SDL_GetBasePath()` anywhere would make one of the two fail. Nothing does, and now there's a comment saying why. **Two libraries independently mounting the same thing is a class of bug worth looking for.**
- **The loader has the command line, not the entry point.** SDL hands `main` an argc of 0; the arguments have to be fetched from the platform. The entire debug surface (`--level`, `--walkthrough`, `--load-threads`, `--cull`) depends on that one call, and everything in posts 5 and 6 depends on the debug surface.
- The network comes up **only in a profiling build**, behind a bounded wait, and failure is a named warning — never fatal. A profiler that can bring down the game is worse than no profiler.
- The profiler's socket pool is sized down hard rather than left at the sample default: **a profiler taking megabytes from the heap it is measuring is the wrong default.**
- **The engine check app became a five-rung on-hardware ladder** — filesystem, network, frame, input, GPU timestamp. **Run it before pointing the game at a device**: a game that doesn't boot could be failing any of the five, plus a dozen things of its own. A minimal known-good binary is the cheapest debugging tool on a platform where you cannot attach anything familiar.

## The trap: I profiled a USB cable for a week

- **A development-format build reads its assets off the development PC**, over the debug link, instead of off the device's own storage. It boots, it runs, it plays. It looks exactly like the real thing.
- Same build: **11.2 s to load the docks packaged for shipping, 56.3 s in development format.**
- Everything I had measured before finding this — every load number, every capture — measured the debug link. It **dwarfed every code change** in post 5, and it flattered nothing: it made my optimisations look better than they were, because I was shaving milliseconds off a bottleneck that didn't exist in a real build.
- ⚠️ It got worse: a build directory had cached the packaging format, so switching it didn't take until the directory was wiped — and it silently went on measuring the cable.
- Two captures that could have explained an 18-second mystery months earlier had been taken on a *different* device and never opened. They'd have been misleading anyway, for exactly this reason.
- **The standing rule now: every capture predating the day I found this is void.** Not "suspect" — void, and deleted from the record. A number you cannot attribute to a known configuration is not a number.
- The generalisable version: **know exactly what your dev configuration does differently from your shipping one, and write it down before you profile anything.** Every platform has one of these. It is never in the section of the docs you were reading.

## The console keeps catching things the desktop doesn't

- A member named `main` gets rewritten by the preprocessor, because SDL `#define`s `main` to `SDL_main`. Compiled fine on every desktop preset; six errors on the console build only.
- That was the **second** time in one refactor that the console build was the only thing that caught a defect. It belongs in the *gate*, not at the end of the queue — the extra build time is cheaper than the class of bug it finds.
- ⚠️ And a toolchain bump is a **runtime** event, not a build event. A compiler major-version jump that lands green on a build gate proves nothing about behaviour on hardware. That verification is still owed.

## What's still open

- The heap has never been sized or measured (post 9).
- The swapchain image count: nothing in the repo sets one, or a frames-in-flight value. Owed to a human, on hardware.
- A thread sanitizer run has **never happened** — the GPU driver on my workstation kills it, and it needs a software-rasteriser machine I don't have set up. Nothing about the job system or the texture-decode workers has independent confirmation from a race detector, and the live data race in post 5 says that matters.

## Next

The future of Soup Raiders: keep Unity as a level editor, or build my own?
