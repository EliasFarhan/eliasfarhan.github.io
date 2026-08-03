---
layout: post
title:  "Soup Raiders Native (4/11): Profiling with Tracy, including on a console"
categories: [gamedev, cpp]
series: soupraiders-native
---

Opening hook: before this, the only performance instrument in the whole project was one hand-rolled `std::chrono` timer around the box3d mesh cook. Everything in posts 5 and 6 exists because Tracy went in first.

<!--more-->

*Console specifics are under NDA. The second half of this post is about getting a profiler onto a constrained target in general — no platform, no SDK, no API names.*

## The starting position

- Two presets: `debug` and `release`. Neither is usable for profiling — Debug is far too slow to be representative, Release has no symbols.
- No way to attribute load cost at all: scene graph build, GPU upload, mesh cook, audio bank load were one undifferentiated blob.

## The wiring, and why it was almost free

- `externals/tracy` as a submodule, pinned to **v0.13.1** (client and server negotiate an exact protocol version and refuse to connect across a mismatch — pin it).
- `ENABLE_PROFILING` declared **before `project()`**, and wired **before** the engine's `core/` subdirectory is added. **Ordering is load-bearing.**
- The trick: Neko3d's `core/CMakeLists.txt` already contains `if(ENABLE_PROFILING) target_link_libraries(Core PUBLIC Tracy::TracyClient) ... TRACY_ENABLE=1` — upstream it gets Tracy from vcpkg via a manifest feature and a `find_package` in a top-level CMakeLists this repo never executes. Defining the option and providing the target from a submodule satisfies the engine's existing wiring **directly**. No vcpkg feature, no `find_package`, no fake config shim.
- Payoff: the engine's ~412 existing zones light up for free, and `TRACY_ENABLE=1` propagates `PUBLIC` so app zones need no wiring of their own.
- New `relwithdebinfo` preset with its own binary dir (Ninja is single-config).

## Decisions worth explaining

- **On-demand mode.** The client stays dormant and its memory flat until a server connects, instead of buffering from process start. Tradeoff: load-time zones only appear if you connect *before* launch. Chosen because unbounded buffering in every profiling run whether or not anyone connects is the worse default for a build people leave lying around.
- **No wrapper macro.** Raw `#ifdef TRACY_ENABLE` / `ZoneScopedN("ns::Class::Method")` / `#endif`, by hand, because that's the engine's house style and there were ~412 existing instances to match. Verbose beats inconsistent.
- Fully-qualified zone names so app and engine zones sort together.
- A predicted macro-redefinition warning (`C4005`, fatal under `/W4 /WX`) **turned out not to exist** — MSVC's `/D` without a value defines to `1`, so the two definitions are token-identical. The planned suppression was dropped rather than kept speculatively. Small thing, general habit.

## Two zone tiers, and why you need both

- **Tier 1**: per-frame and per-load zones plus `TracyPlot` counters. Cheap enough to leave running for a whole 96-spot walkthrough.
- **Tier 2** (`ENABLE_PROFILING_DETAILED`): zones whose count scales with scene content — per draw call, per node, per texture, per pipeline, per file read. On the docks' ~1300 mesh nodes that's a **10–20× zone-volume multiplier**. Short targeted runs only.
- Counters that earned their keep: `gpu.swapchainWaitMs` / `gpu.submitMs`, `render.drawCalls` / `.nodesDrawn` / `.nodesCulled`, `fs.lockWaitMs` / `fs.readBytes`, `load.textureBytesDecoded`.
- Scale of a real capture: **23 990 frames, 5 358 981 zones, 6:46**.

## The rule that matters under a hard vsync: frame time carries no information

This is not console-specific — it applies anywhere you cannot present immediately.

- With no immediate-present mode, frames are pinned to the refresh rate. **A frame doing twice the work has the same duration until it misses entirely.** And never quote a run-wide average framerate anyway: it folds in the multi-second load stalls.
- Headroom is the **swapchain wait**. Work that gets more expensive doesn't lengthen the frame, it *shortens the wait*. When the wait approaches zero you're at budget; then check submit time — if that grew too, the CPU is the wall; if only the wait vanished while CPU zones stayed flat, the GPU is.
- It's a proxy, and it's honest to say so: the call conflates vsync pacing with GPU backpressure and cannot separate them. It's still the right first thing to read where real timestamps are unavailable.

## Getting a profiler onto a constrained target

Generalised: a 64-bit target with no `mmap`, no callstack unwinding, no sampling, no hardware cycle counter, and a standard library you don't control.

- **The pleasant surprise: a complete POSIX socket layer was already there.** Tracy's entire network and threading layer linked with **no work at all**. Worth checking before budgeting weeks for it — and worth knowing before porting any other networked middleware to the same target.
- **Pick the cheapest platform lie.** Tracy has to believe it's on *something*. `__OpenBSD__` appears in exactly two places in the whole client, pulls in no extra headers (`__linux__` wants `<sys/syscall.h>`, `__QNX__` wants `<sys/neutrino.h>`), and doesn't define `BSD` — so Tracy's callstack, system-time and system-tracing backends all switch themselves off with no `TRACY_NO_*` needed. Its one required symbol is a thread id, answered honestly from a real kernel thread id rather than by truncating a `pthread_t`.
- ⚠️ **The trap: libc++ dispatches on the same platform macros.** Defining the lie on the command line breaks the *standard library*, not Tracy — the OpenBSD locale variant collides with the platform's own `<stdlib.h>`, arriving via `<chrono>`. The fix is a force-included shim that **pre-includes every affected header and only then tells the lie**, so the include guards are already closed. **This generalises: no platform-macro fake is viable through a bare `-D` if your libc++ reads the same macros** — it would have killed `__linux__` and `__FreeBSD__` equally.
- **The libc gaps, replaced by macro rename inside the shim**, never by defining the real names — squatting on `mmap` would silently retarget any other consumer in the link, and these implementations are only defensible in the profiler's context.
  - `mmap`/`munmap` → the platform's virtual-address-region API, which is a direct analogue of the Win32 path rpmalloc was written against.
  - ⚠️ **`madvise` must be a no-op, not the literal translation.** rpmalloc calls the *non-releasing* unmap on subspans while the master span's header stays live in the same reservation and its counter keeps being read — and freed subspans are re-served out of that reserve **without going back through `memory_map`**. Actually decommitting there faults on the next touch. POSIX `MADV_DONTNEED` keeps the mapping (pages come back zero-filled), which is why rpmalloc gets away with it. Keeping pages resident is always a legal answer to advice, so the no-op costs peak footprint and nothing else.
  - `gethostname` / `getlogin_r` → constants. There is no login on this target, and the device nickname is user data with no business going to a profiler.
  - `pipe` → two invalid descriptors. Tracy's self-pipe is purely a fault-safe memcpy, and its only three callers are disabled here, so a failing write degrades exactly as Tracy already handles a faulting pointer.
- **Why a shim at all**: Tracy hard-enables rpmalloc and calls `rpmalloc_initialize()` with no config, so rpmalloc's own injectable hooks are unreachable — **the OS mapper is the only way in.** That's not a workaround, it's the right layer: keeping the profiler's pool inside its own reservation matters, because perturbing the heap you're measuring is precisely the failure mode to avoid.
  - The one semantic assumption, load-bearing: the platform's region-release call takes a base with no length, exactly like `VirtualFree(MEM_RELEASE)` — and that's safe for the same reason, since rpmalloc's default mapper is written to the `MEM_RELEASE` contract and always passes the exact base and full length. A future rpmalloc that partially released a region would corrupt.
- **No hardware cycle counter** on this architecture, so timestamps fall back to `high_resolution_clock` at ~52 ns each. Fine, just not `rdtsc`-cheap.
- Frame images and source transfer are off: they reach the dead self-pipe, the compression thread isn't affordable, and source transfer would serve host paths baked into a shipped binary anyway.

## The consequence nobody warns you about

⚠️ **Where sampling and callstacks are unavailable, manual zones are the only signal.** Uninstrumented code is not low-resolution, it is **absent** — a starved, descheduled or spinning thread looks identical to one doing slow work. Two of the wrong diagnoses in post 5 come straight out of that, and it's the single best argument for instrumenting the load path *before* you go looking for a load-time bug.

## And GPU time, which I'd written off

- SDL_GPU exposes no timestamp, query or occlusion API at all, and the Vulkan renderer's Tracy context was out of reach because that backend is off on the target in question. I wrote down "GPU time is invisible and will stay that way."
- That was wrong. Real GPU timestamps now come off the device through a `vkGetInstanceProcAddr` interposer — the first GPU cost this project ever measured on the target, and the entire basis of post 6.
- The pattern is worth stealing: when an abstraction layer hides something you need, the layer underneath it may still be reachable.

## Next

Load time: 32.7 s to 3.3 s, and how much of that was actually a build flag.
