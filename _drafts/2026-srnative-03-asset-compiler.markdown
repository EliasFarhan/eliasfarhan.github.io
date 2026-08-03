---
layout: post
title:  "Soup Raiders Native (3/11): The asset compiler — JSON is an intermediate, not a shipping format"
categories: [gamedev, cpp]
series: soupraiders-native
---

Opening hook: the game shipped 4.77 MB of JSON and spent 390 ms per level load parsing it on the console. Replacing it with a compiled binary was the obvious move — and two of my four reasons for doing it turned out to be wrong.

<!--more-->

## The inventory

- **16 schemas, 31 files, 4.77 MB of shipped JSON.**
- `docks_collision.json` alone is **3.33 MB — 95% of the docks' JSON**.
- The three collision files together are **4.0 MB of the 4.77 MB, i.e. 84%.** Everything else together is 0.75 MB.
- Consequence: any step ordering that doesn't put collision first is optimising the wrong 16%. Collision was the pilot.

## Four motivations. Two died on measurement, before a line of code

This is the part I want to keep: I measured the premises *first*, because a previous plan had nearly shipped three steps on premises that didn't survive.

- ❌ **Shipped size — essentially zero.** Deflate compresses decimal text very well and raw `float32` arrays very badly. On `docks_collision.json`: 3 333 609 → 742 335 as JSON in the archive, 2 121 636 → 667 584 as binary. A **36% raw win collapses to 10% inside the zip**, i.e. 75 KB against a 155 MB image. And the raw ratio is only 1.6×, not the 4–6× "text vs binary" intuition suggests — this JSON is compact, short-decimal and payload-dominated. String-heavy schemas do worse still.
- ❌ **Compile time — oversold.** Removing `nlohmann/json.hpp` shrinks the PCH build, not the per-TU cost the PCH already amortises. The PCH still carries `novus/scene.h` (4.14 s), `engine/scene.h` (3.57 s) and entt (2.70 s). A few seconds off a clean build, not a transformation.
- ✅ **Load time — 390 ms/load, measured on hardware.** `LoadJsonAsset` 40 calls / 1.396 s, of which `::Parse` is **1.171 s** and `::Read` only 0.198 s. That is **43% of the entire synchronous load segment** (2697 ms across three loads). And it is a *lower bound* — the zone covers read+parse only; each loader's copy-out walk and the DOM's destruction (hundreds of thousands of node frees for the collision asset) happen outside it.
- ✅ **Heap churn + code simplification.** nlohmann allocates per node — every object, every array, every string — and then every loader copies out of it. Cereal reads straight into the final vectors. And ~2 000 lines of hand-written `.at()`/`.value()` parsing across 13 `.cpp` files collapse into one `serialize()` per struct.
- Worth saying plainly: JSON parsing looked prominent *because* the load-time work had fixed everything around it, not because it got worse.

## The design, in one idea

- A schema exists **once**: one struct, one `serialize()`, two consumers — the compiler and the runtime. A mismatch is a **compile error**.
- **The existing parsing code isn't deleted, it's moved.** Every `.at()` walk becomes the compiler's front end, essentially verbatim. The risky, fiddly, Unity-quirk-encoding half keeps working exactly as it does — it just runs on a PC at bake time instead of on the console at load time.
- Shape: a C++ host tool (`asset_compiler`, `EXCLUDE_FROM_ALL`) driven by a Python wrapper, mirroring the existing `ktxtools` / `compress_textures.py` pattern.

## The thing that will bite you: cereal binary fails silently

- JSON fails loudly. A cereal binary archive is **not self-describing**. Read a v1 blob with a v2 `serialize()` and it doesn't error — it reads the *next* field's bytes as this field's value and carries on.
- A `float` becomes garbage. A container's `size_type` becomes an arbitrary `uint64`, and the very next thing that happens is `resize()` on it. On a console that is an **OOM abort, not an exception**.
- Hence a fixed, uncompressed, validated header ahead of every payload:

| Field | Width | Why |
|---|---|---|
| magic `SRAB` | 4 B | truncated read, wrong file, unexpected mount |
| container version | `uint32` | the header's own format |
| asset kind | `uint32` | catches "loaded `palace_collision.bin` into a `FontAtlas`" |
| schema version | `uint32` | the existing content version, unchanged in meaning |
| source hash | `uint64` | hash of the source JSON — the staleness guard |
| payload bytes | `uint64` | bounds-check *before* `resize` |

- Two of the sixteen had no version gate at all under JSON (`water.json` carries none; snap rails carries one nobody read). Latent bug under JSON, unbounded `resize` under cereal.

## Staleness is a brand new way to lose an afternoon

- Editing the JSON now changes **nothing** until the compiler runs. Three layers, cheapest first:
  1. The compiler is idempotent and hash-stamped — re-running it is free, so running it is the default habit.
  2. **`pack_assets.py` verifies the stamp.** A `.bin` whose stamp doesn't match the `.json` beside it fails the pack. This is the load-bearing layer, because packing is on the path to every archive that ships.
  3. The compiler runs in the exporters' wake, documented as the step that follows every Unity export.
- Not a build dependency: one of my targets can't build a host tool at all, so the `.bin` files are **committed artifacts** like every other baked asset. Making desktop depend on the compiler while that target consumed a committed copy would let the two diverge, which is worse than neither.

## One engine fix that the whole thing rested on

- `ReadCerealFromBuffer` copied the payload **twice** — into a `std::string`, then into an `std::istringstream` — before reading a byte. On a 3.33 MB asset that's two extra multi-MB allocations inside the function whose entire purpose is to reduce allocation. Replaced with a zero-copy `std::streambuf` over the existing buffer.

## Results

- **~9× on the whole asset read path, ~50× on decode alone.**
- The synchronous load segment went **2697 ms → 1490 ms on hardware, from collision alone**.
- By the end of the pilot the load-time motivation was *spent*: the remaining fifteen schemas parsed in ~32 ms/load combined. The other fifteen shipped for simplification and heap, and the acceptance criteria were rewritten to say so.

## What I haven't done yet

The compiler is where load-time work goes to die, and I've only used it for translation so far. Still on the list:

- Emit collision meshes already welded and indexed, so box3d's two expensive flags can be turned off (⚠️ needs verifying that box3d permits it — a silently un-welded mesh is a collision bug, not a crash).
- Resolve clip names → indices; resolve talk-icon → NPC linkage at bake instead of by position.
- Flatten the dialog line table and the font atlas glyph map; turn Unity GUID maps into dense indices.

## Next

Profiling with Tracy — including the part where the client had to run on a platform it had never seen.
