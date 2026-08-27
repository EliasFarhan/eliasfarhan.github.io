---
layout: post
title:  "Soup Raiders Goes Native: The asset compiler and loading time"
categories: [gamedev, cpp]
series: soupraiders-native
---

![tracy](/images/2026/sr/sr_tracy_profile.png)

My goal is to get sub-3s to load each level of Soup Raiders on the Nintendo Switch. But not all games do so on the Nintendo Switch...

<!--more-->

<blockquote class="twitter-tweet" data-media-max-width="560"><p lang="en" dir="ltr">Animal Crossing New Horizons Switch 1 VS Switch 2 load times... WOW <a href="https://t.co/D6WFxxgJE1">pic.twitter.com/D6WFxxgJE1</a></p>&mdash; NintenTalk (@NintenTalk) <a href="https://x.com/NintenTalk/status/1930656532636606865?ref_src=twsrc%5Etfw">June 5, 2025</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

Not to take a hit on *Animal Crossing* which is a game that I enjoyed a lot during the COVID-19 pandemic, but what is going on during 30 seconds? The Nintendo Switch has 4 cores (minmus 1 used by the OS) to do things and it has a *32 GB eMMC 5.1* that could theoricatlly load at max bus rate of 400 MB/s (yes, if your game is on a miroSD you can expect 70-90 MiB/s with a good card). 

Another example of crazy loading time is GTA V online with this blog post [here](https://nee.lv/2021/02/28/How-I-cut-GTA-Online-loading-times-by-70/) talking about how this modder (?) managed to optimize the loading time from ~6min flat to 1m 50s on his SSD. This teaches us that loading time is not just about loading files from the drive (CD, DVD, HDD, SSD) to the RAM (or VRAM), but how we do it. Let's go first on a trip into history.

## A little history of game loading times

Loading time like a lot of topics in games is a story of hardware constraints, techniques and game size. How is my games being distributed? On which support? What is the available space on this support? How fast can I read from this support? 

### Before the CD-ROM

![soup raiders jailbreak](/images/srjailbreak.png)

I made a small Gameboy game a few years ago (blog post [here](/gamedev/2016/10/17/soup-raiders-jailbreak-post-mortem-of-gbjam-5-doing-a-real-homebrew-gameboy-rom.html)). On this platform, there are several type of **Memory Bank Controller** (MBC). If you choose a **MBC5** mapper, you can have up to 8 MiB of data in the ROM (for example for Pokemon Trading Card Game [reference](https://gbhwdb.gekkio.fi/cartridges/DMG-AXQP-0/)). But earlier games used **MBC1** with up to 2 MiB ROM size, like Super Mario Land 1 ([reference](https://gbhwdb.gekkio.fi/cartridges/DMG-MLA-0/)) that has a 64 KiB ROM. So obviously, you don't have a lot of space to put a lot of assets, but there is also not a lot of CPU power to process and render too many sprites anyway. And coming back to our topic, loading time was not a problem (it was mostly invisible). 

### Some good and bad examples of CD-ROM games 

![kain](/images/2026/legend_kain.jpg)

Legacy of Kain: Soul Reaver — PlayStation, 1999 
- https://blog.playstation.com/archive/2012/10/12/behind-the-classics-legacy-of-kain-soul-reaver/
- https://blog.playstation.com/2024/11/19/the-legacy-of-kain-series-retrospective-with-original-developers/

![ridge racer](/images/2026/riraps0f.jpg)

Ridge Racer — PlayStation, 1994/95 (Christmas 2014 EDGE):
>> almost everything required for gameplay was loaded into RAM at startup.


### DVD-era

Jak and Dakter falling animation

### Installing the disk on the HDD

### SSD era


## What we got in Soup Raiders

From the previous blog post ([here](/gamedev/cpp/2026/08/20/srnative-02-porting-unity.html)), the original assets that we got from the Unity demo are:
- 3d models (exported as `.glb`),
- Sprites/textures (exported as `.png` and `.jpg`),
- Fmod music banks (exported as `.banks`),
- Unity prefab/scenes data and snap rails data (exported as `.json`).

## Asset compiler

### PNG to KTX2

### Atlases

### Json to binary

### Packing all in `.zip` files

## Loading sync and async

### PhysFS

Lock on read

Filesystem abstraction (normal vs on zip file)
>>

### LibKTX

### Assimp

| level |	assets |	textures |	mesh |	data |	stored |	read
| -- | -- |
| docks |	87 |	68 (21.5 MB) |	2 (8.4 MB) |	17 (5.7 MB read) |	31.76 MB	| 35.16 MB
| palace |	54 |	37 (14.0 MB) |	1 (4.4 MB) |	16 (1.0 MB read) |	18.78 MB	| 19.39 MB
| fishpalace |	41 |	29 (12.5 MB) |	1 (1.6 MB) |	11 (0.2 MB read) |	14.16 MB |	14.29 MB
| globeisland	| 27 |	17 (4.7 MB) |	2 (0.2 MB) |	8 (0.2 MB read) |	4.89 MB |	5.03 MB

The biggest single reads per level:

docks:
- LevelDocks_baked.glb 7.94 
- docks_collision.bin 5.55 
- battle_character_atlas.ktx2 5.15 (deferred) 
- bg_rock_01.ktx2 3.25 
- skybox.ktx2 2.74 
- ending_atlas.ktx2 1.44 (deferred)

palace:
- battle_character_atlas 5.15 (deferred)
- LevelPalace_baked.glb 4.38 
- skybox 2.74 
- palace_collision.bin 0.90

fishpalace:
- battle_character_atlas 5.15 (deferred)
- skybox 2.74 
- LevelFishPalace_baked.glb 1.58

globeisland:
- skybox 2.74 
- overworld_npc_atlas 0.60 
- character_atlas 0.47

Read once at boot, not per level: FMOD banks 35.67 MB (4), title + logos 16.31 MB (180 files), shaders 47 × .spv (0.20 MB), loading widget 0.19 MB, registry + cost table 0.02 MB. Whole image: 99.59 MB, 461 entries.

What's in the Docks?
![](/images/2026/sr_docks.png)

What's in the Palace?
![](/images/2026/sr/sr_palace.png)

What's in the Fish Palace Boss Battle?
![](/images/2026/sr/sr_boss.png)

Separating the assets into zip
Compression vs fast reading.

PNG vs KTX2

Single images vs atlases

PhysFS

3d models -> converted to GLB from Unity
JSON to binary with cereal
Sprites -> put into atlases and converted to KTX2/
Unity gameplay data -> JSON -> Serialized binary data (using cereal but could use C++26 static reflection instead).

<!-- MERGED: everything below up to "## Next" came verbatim from
     _drafts/2026-srnative-05-level-load-time.markdown (post 05), which you asked to fold
     into this post. Nothing was reworded. Two things to resolve by hand:
       1. the four bullets immediately below duplicate the format-comparison bullets above;
       2. post 05's own "## Next" (pointing at the rendering post) was dropped, since this
          post's "## Next" already points at Tracy / post 04. -->


FBX vs OBJ vs GLB
PNG vs KTX2 with basisu
JSON vs Binary format
Using PhysFS vs read each file one after the other.


## Next

Profiling with Tracy — including the part where the client had to run on a platform it had never seen.

- https://www.gdcvault.com/play/1022268/Streaming-in-Sunset-Overdrive-s
- https://www.gdcvault.com/play/1027205/Zen-of-Streaming-Building-and
- https://gdcvault.com/play/1012445/Data-is-a-Four-Letter
- https://web.archive.org/web/20120614235137/http://www.bitsquid.se/files/resource_management.html
- https://web.archive.org/web/20120507185423/http://www.bitsquid.se/presentations/cutting-the-pipe.pdf
- https://www.dominikgrabiec.com/posts/2025/11/13/accu_2025_review.html
- https://www.resetera.com/threads/jak-daxter-the-precursor-legacy-appreciation-thread.108718/
- https://mropert.github.io/2020/07/26/threading_with_physfs/ 

---

<!-- ============================================================================
     RESEARCH SCAFFOLDING — NOT FOR PUBLICATION. Delete this whole block once the
     prose is written. Source: Jason Gregory, *Game Engine Architecture*, 3rd ed.,
     A K Peters/CRC Press, 2018. Page numbers are printed book pages.
     Organised as the contrast you asked for: what the textbook prescribes vs what
     the Switch actually measured. Quotes are verbatim.
     ============================================================================ -->

## NOTES: Gregory, *Game Engine Architecture* (2018) — textbook vs the Switch

Everything relevant sits in **Ch. 7 "Resources and the File System"** (pp. 481–522) and
**§16.3–16.4 "World Chunk Data Formats" / "Loading and Streaming Game Worlds"** (pp. 1062–1075).
Also useful: §1.7 (pp. 61–65) for the tools overview, §15.4.2.1 (p. 1036) for where in the
pipeline the platform-specific step happens.

### The load-cost model the book is built on — and the sentence that dates it

> "When loading data from files, the three biggest costs are **seek times** (i.e., moving the read
> head to the correct place on the physical media), **the time required to open each individual
> file**, and **the time to read the data** from the file into memory. Of these, the seek times and
> file-open times can be nontrivial on many operating systems." — §7.2.2.2, **p. 505**

> "Solid-state drives (SSD) do not suffer from the seek time problems that plague spinning media
> like DVDs, Blu-ray discs and hard disc drives (HDD). **However, no game console to date includes
> a solid-state drive as the primary fixed storage device (not even the PS4 and Xbox One). So
> designing your game's I/O patterns in order to minimize seek times is likely to be a necessity
> for some time to come.**" — **p. 505**

**Contrast material — what the Switch numbers say about that three-term model:**

| Gregory's term | 2018 rationale | What we measured |
|---|---|---|
| seek time | dominant, spinning media | not a term at all — NAND |
| file-open cost | "nontrivial on many operating systems" | `Open` = **0.03 ms, 0.16%** of file access. The named suspect, and dead. |
| read time | third | `ReadBytes` **51.9%** — but next to it, **`LockWait` 43.6%** on a process-wide filesystem mutex, which is *not in his list at all*, and a platform layer chopping every read into **4 KB** |

- The term that replaced seek time is **contention**, not transfer: one process-wide mutex, one
  storage path, `Exists` doing a second full path lookup while holding it (4.2%).
- His conclusion (batch into one archive, lay it out sequentially) still comes out right on the
  Switch — but for the file-open and syscall-count reasons, not the head-movement reason. Worth
  saying out loud: *the right answer survived its own justification going obsolete.*

### Archives: PhysFS is the OGRE model, described almost exactly

Four benefits of ZIP, §7.2.2.2, **p. 506** — (1) open format, (2) virtual paths, (3) compression,
(4) modularity:

> (2) "The virtual files within a ZIP archive 'remember' their relative paths. This means that a
> ZIP archive **'looks like' a raw file system** for most intents and purposes… a game programmer
> needn't be aware of the difference in most situations."

> (3) "ZIP archives may be compressed… **more importantly, it again speeds up load times, as less
> data need be loaded into memory** from the fixed disk. This is especially helpful when reading
> data from a DVD-ROM or Blu-ray disk, as the data transfer rates of these devices are much slower
> than a hard disk drive. **Hence the cost of decompressing the data after it has been loaded into
> memory is often more than offset by the time saved in loading less data from the device.**"

> (4) modularity → his example is localisation: one ZIP per region, swap the archive.

Unreal contrast, same page: "**all resources must be contained within large composite files known
as packages** (a.k.a. 'pak files'). No loose disk files are permitted."
Downside he names (p. 498): package files are binary, so **two people can't edit the same package
at once** — only one can lock it.

**Contrast material for "Compression vs fast reading":** claim (3) is the one that inverts. It
holds while the device is the bottleneck. Ours stopped being the device:

| | before | after |
|---|---:|---:|
| file read | 76% | 25.6% |
| Basis transcode (pure CPU) | ~21% | **64.5%** |

Once the reads are fixed, "decompress rather than read" is no longer free money — the decompress
*is* the bill. Gregory's trade-off is stated as a one-way inequality; it's really a ratio that
moves, and three changes moved ours past the crossover. (This is the same shape as the
"a rejection is only valid against the composition you measured it in" point above.)

### "Only one copy of each unique resource" — his responsibility #1, our biggest code win

The very first bullet in his list of runtime resource manager responsibilities, §7.2.2.1, **p. 504**:

> "• **Ensures that only one copy of each unique resource exists in memory at any given time.**"

Mechanism, §7.2.2.5, **p. 508**: a registry dictionary keyed by GUID; on request, look up, return
the pointer if present. And across levels, ref-counting, §7.2.2.6, **p. 510**:

> "**We don't want to unload a resource when level X is done, only to immediately reload it because
> level Y needs the same resource.**" — then Table 7.2 walks the ref counts for levels X and Y
> sharing resources B and C.

**Contrast material:** this is textbook item #1 and it was the single largest code win.
W2 = 83 material textures from **65 unique paths** (+ font atlas registered 3 extra times);
W3 = **28 of palace's 34 textures byte-identical to docks**, 3.63 MB of 5.22 MB, **69%** — which is
literally his X/Y ref-counting diagram with the counting not implemented. Dedup bought
**−13.5% boot, −20.4% docks→palace, −23.0% palace→FishPalace**, more than either other change.

### Do it offline — the asset conditioning pipeline

§7.2.1.4, **p. 501–502**. The ACP (a.k.a. resource conditioning pipeline, a.k.a. **the tool chain**)
is three stages, explicitly analogised to compiling and linking a C++ program:

1. **Exporters** — plug-ins that get data out of the DCC's native format (Maya C++ SDK / MEL / Python).
2. **Resource compilers** — "'massage' the raw data… rearrange a mesh's triangles into strips, or
   compress a texture bitmap, or calculate the arc lengths of… a Catmull-Rom spline."
3. **Resource linkers** — "Multiple resource files sometimes need to be combined into a single
   useful package prior to being loaded… **this process is sometimes called resource linking**."

The design rule, §7.2.2.3, **p. 507**:

> "many game engines endeavor to do **as much offline processing as possible in order to minimize
> the amount of time needed to load and process resource data at runtime**. If the data needs to
> conform to a particular layout in memory, for example, a raw binary format might be chosen so
> that the data can be laid out by an offline tool (rather than attempting to format it at runtime
> after the resource has been loaded)."

Two-step, platform-independent then platform-specific, §15.4.2.1, **p. 1036**:

> "First, the asset is exported from the DCC application to a **platform-independent intermediate
> format** that only contains the data that is relevant to the game. Second, the asset is processed
> into a format that is **optimized for a specific platform**."
> Where engines differ is *when* step 2 runs: UnrealEd on import; "the Source engine and the Quake
> engine pay the asset optimization cost **when baking out the level** prior to running the game";
> Halo converts on first load and **caches the result**.

Build dependencies, **p. 503** — worth citing for the Unity-prefab-to-binary story:

> "**If the format of the files used to store triangle meshes changes, for instance, all meshes in
> the entire game may need to be reexported and/or rebuilt.**" … "an asset may contain a version
> number, and the game engine may include code that 'knows' how to load and make use of legacy
> assets. The downside… asset files and engine code tend to become bulky. **When data format
> changes are relatively rare, it may be better to just bite the bullet and reprocess all the
> files.**"
> And: "I've witnessed countless hours wasted in tracking down problems that could have been
> avoided had the asset interdependencies been properly specified."

**Contrast material:** our `.glb` / `.ktx2` / cereal-binary pipeline is exactly stages 1–3, and the
Unity source is the DCC. The place we *didn't* obey him is `CollisionCook` — **87.0% of the
synchronous phase**, of which the box3d cook itself is 70.3% — a resource-compiler-stage job
(his stage 2) still running at load time. He predicts this cost by name.

### JSON / XML parse cost, cereal, and the reflection wish

§16.3.2, **p. 1064**:

> "**XML is notoriously slow to parse, which can increase world chunk load times. For this reason,
> some game engines use a proprietary binary format that is faster to parse and more compact than
> XML text.**" — JSON then named as the modern replacement, "used ubiquitously for data
> communication over the World Wide Web."

Two ways to implement serialisation in C++, same page:

> "• We can introduce a pair of virtual functions called something like `SerializeOut()` and
> `SerializeIn()`… • **We can implement a reflection system for our C++ classes.** We can then
> write a generic system that can automatically serialize any C++ object for which reflection
> information is available."
> "**The tricky part of a C++ reflection system is generating the reflection data** for all of the
> relevant classes. This can be done by encapsulating a class's data members in `#define` macros…"

Binary object images, §16.3.1, **p. 1063** — the caveat that matters for gameplay data:

> "binary object images are **inflexible and not robust to making changes**. Gameplay is one of the
> most dynamic and unstable aspects of any game project… **the binary object image format is not
> usually a good choice for storing game object data (although this format can be suitable for more
> stable data structures, like mesh data or collision geometry).**"

**Contrast material:** direct confirmation, with a number he'd have liked —
`docks_collision.json` at **3.33 MB is 91% of all JSON parsed per docks load**, on the main thread;
plus W5, the font atlas JSON parsed **twice** per level, 65.7 KB × 2 into a `std::map`.
And the "could use C++26 static reflection instead" line in the draft is the direct answer to his
"the tricky part is generating the reflection data" — the macro/codegen workaround he describes in
2018 becomes a language feature. Note his split, too: he'd endorse binary for collision and mesh
and warn against it for the Unity gameplay data.

### The endgame past cereal: pointer fix-ups and load-in-place

§7.2.2.9, **pp. 518–520**. Serialise the object graph contiguously into the file, rewrite every
pointer as a file offset, and store the offsets' locations in a **pointer fix-up table** written
alongside:

> "**In effect, an offset is the binary file equivalent of a pointer in memory.**"
> `ConvertOffsetToPointer(offset, pAddressOfFileImage) { return pAddressOfFileImage + offset; }`

Constructors, **p. 520** — two options: restrict yourself to **PODS** ("C structs and C++ structs
and classes that contain no virtual functions and trivial do-nothing constructors"), or store a
table of non-PODS offsets + class ids and run placement new over them.

Portability warning, **p. 519** — relevant to a desktop-to-console pipeline:

> "**Do be aware of the differences between your development platform and your target platform.**
> If you write out a memory image on a 64-bit Windows machine, its pointers will all be 64 bits
> wide and the resulting file won't be compatible with a 32-bit console."
> (Endianness gets the same treatment at pp. 140–143 and 1063.)

**Sectioned resource files**, §7.2.2.7, **p. 516** — this is the textbook fix for `ProbeKtx2`:

> "A typical resource file might contain between one and four sections… One section might contain
> data that is destined for main RAM, while another section might contain video RAM data. **Another
> section could contain temporary data that is needed during the loading process but is discarded
> once the resource has been completely loaded.** Yet another section might contain debugging
> information."

**Contrast material:** W1 is reading a whole `.ktx2` twice, once *just to get a header* — ~99 scene
textures in the docks, ~12.0 MB read twice. A sectioned file (or any header the loader can read
without the payload) is a 2018 textbook answer to a 2026 bug.

### Post-load initialization — his name for `GpuSetupJob`

§7.2.2.10, **pp. 521–522**. Naughty Dog calls it "**logging in**" a resource (and "logging out" for
tear-down). Two flavours, and the second is the one to quote:

> "• In some cases, post-load initialization is an **unavoidable** step. For example, on a PC, the
> vertices and indices that describe a 3D mesh are loaded into main RAM, but **they must be
> transferred into video RAM before they can be rendered.**"
> "• In other cases, the processing done during post-load initialization is **avoidable (i.e., could
> be moved into the tools), but is done for convenience or expedience**… Later, when the
> calculations are perfected, **this code can be moved into the tools, thereby avoiding the cost of
> doing the calculations at runtime.**"

**Contrast material:** our GPU setup is his "unavoidable" bullet almost word for word. But
**pipeline creation at 512 ms per load, 20 pipelines at a mean 25.6 ms, worst 72.9 ms, 73% of GPU
setup, rebuilt every transition** is squarely his *avoidable* bullet — a pipeline cache is exactly
"move it into the tools". Same for W4 (shaders + pipelines rebuilt every transition). Useful line:
he wrote the taxonomy in 2018 and both of our worst main-thread blocks land in it, one in each bin.

### Chunk sizes, and the 4 KB read

§7.2.2.7, **p. 514**:

> "at Naughty Dog, we use a chunky resource allocator as part of our resource streaming system, and
> our **chunks are 512 KiB in size on the PS3 and 1 MiB on the PS4**. You may also want to consider
> **selecting a chunk size that is a multiple of the operating system's I/O buffer size to maximize
> efficiency when loading individual chunks**."

**Contrast material:** he's telling you to size reads *up* to the I/O granularity. Our platform
layer chopped every read *down* to **4 KB** regardless. Bypassing that was worth **−20.6% on boot**
and it's the same principle read from the other end — the whole "chunky" section assumes you
control the read size, and the interesting failure mode in 2026 is a middleware layer that quietly
takes that control away. 512 KiB vs 4 KB is a **128×** gap worth putting in a sentence.

### Memory: LSR / global resources, and the stack allocator

§7.2.2.6, **pp. 509–510** — resource lifetimes come in three bands:

- **Global / load-and-stay-resident (LSR)**: "loaded when the game first starts up and must stay
  resident in memory for the entire duration of the game… **Any resource that is visible or audible
  to the player throughout the entire game (and cannot be loaded on the fly when needed) should be
  treated as a global resource.**" His examples: player character mesh/materials/textures/core
  animations, HUD textures and fonts, standard-issue weapons.
- **Level-lifetime**: "must be in memory by the time the level is first seen… can be dumped once
  the player has permanently left the level."
- **Shorter than the level**: in-game cinematics, streamed audio in two chunks (playing + next).

Stack allocator, §7.2.2.7, **p. 512** (fig. 7.3, repeated as fig. 16.11 on p. 1071) — valid when
"the game is linear and level-centric" and "each level fits into memory in its entirety": load LSR,
mark the stack top, load the level above it, free back to the marker.
Also the Bionic Games ping-pong trick on the same page:

> "load a compressed version of level B into the upper stack, while the currently active level A
> resides (in uncompressed form) in the lower stack… **Decompression is generally much faster than
> loading data from disk, so this approach effectively eliminates the load time** that would
> otherwise be experienced by the player between levels."

**Contrast material:** the draft's "read once at boot, not per level" list — FMOD banks 35.67 MB,
title + logos 16.31 MB / 180 files, 47 shaders, loading widget, registry — *is* his LSR block, and
Soup Raiders is exactly the "linear and level-centric" game his stack allocator assumes. Worth
naming it with his term. And the ping-pong quote is another instance of the
decompress-is-cheaper-than-read assumption that our transcode numbers break.

### Async I/O — and his priority rule, which we violated exactly

§7.1.3, **p. 489**:

> "**Streaming refers to the act of loading data in the background while the main program continues
> to run.**" … "In order to support streaming, we must utilize an asynchronous file I/O library."

§7.1.3.1, **p. 492**:

> "It's important to remember that **file I/O is a real-time system, subject to deadlines just like
> the rest of the game.** Therefore, asynchronous I/O operations often have varying priorities. For
> example, **if we are streaming audio from the hard disk or Blu-ray and playing it on the fly,
> loading the next buffer-full of audio data is clearly higher priority than, say, loading a
> texture** or a chunk of a game level."

§7.1.3.2, **p. 492**: "Asynchronous file I/O works by handling I/O requests in a separate thread.
The main thread calls functions that simply place requests on a queue and then return immediately."

Also **p. 487**, an anecdote in the same spirit as our findings: the Red Alert 3 team at EA found
log writes were "causing significant performance degradation", buffered them in memory and "moved
the buffer dump routine out into a separate thread to avoid stalling the main game loop."

**Contrast material:** two things here.
1. The app side had **zero threading** — no `std::thread`, no `std::async`, no job-system use. His
   §7.1.3 is the baseline we didn't have.
2. **FMOD banks are 22.1% of boot** (1 534.7 ms, four banks, ~36 MB; single longest read in the
   whole 6:46 run is a bank at **971.2 ms**) and they're issued *after* the async texture decode is
   scheduled, so ~1.5 s of bank reading fights the texture workers for the one process-wide mutex.
   Gregory's rule is that audio outranks textures. We had no priorities at all, and the ordering
   we happened to get was the inverse of the one he prescribes.

### Loading screens, air locks, streaming — the ladder we're on the bottom rung of

§16.4.1, **p. 1070** — simple level loading, one chunk at a time, stack allocator, 2D loading screen.
Drawbacks he lists: no seamless world, and "**during the time the level's resource data is being
loaded, there is no game world in memory. So, the player is forced to watch a two-dimensional
loading screen.**"

§16.4.2, **pp. 1071–1072** — **air locks**: one large block + one small block; the player is held in
a corridor/puzzle/fight in the small chunk while the next large chunk streams in.
> "**Halo for the Xbox used a technique similar to this.** As you play Halo, watch for confined
> areas that prevent you from back-tracking — you'll find one roughly every 5–10 minutes of
> gameplay. **Jak 2** for the PlayStation 2 used the air lock technique as well."
> Note also: "an air lock system **does not free us from displaying a loading screen whenever a new
> game is started**, because during the initial load there is no game world in memory."

§16.4.3, **pp. 1072–1073** — full streaming: uniform chunks + pool allocator, and Naughty Dog's
**level load regions** (convex volumes, each listing the chunks that must be resident; take the
union of the regions containing the player).

**Contrast material / good closing frame:** Soup Raiders is squarely §16.4.1, the 1990s rung, and
the goal was never to climb it — it was to make the rung short enough (**under 3 s**) that climbing
it doesn't matter. Landed at 3.3 s docks→palace, 2.9 s FishPalace, ~7 s boot. His own note that the
*first* load always shows a screen even in an air-lock design is a fair defence of that choice.

### One thing the book has no answer for

The dev-format build reading assets off the PC over the debug link — 11.2 s packaged vs **56.3 s in
development format**, same build. Gregory covers tool chains, resource databases, and platform
differences in detail, and never mentions that your *development configuration* can be the single
largest term in your load time. Reasonable: it's a per-platform SDK behaviour, not an architecture
question. But it dwarfed every code change in the post, and no amount of reading Ch. 7 would have
found it. (Post 10.)

### Citation

Jason Gregory, *Game Engine Architecture*, 3rd edition, A K Peters/CRC Press, 2018 —
Ch. 7 "Resources and the File System" (pp. 481–522), §15.4.2.1 (p. 1036),
§16.3–16.4 "Runtime Gameplay Foundation Systems" (pp. 1062–1075).

<!-- ===================== END RESEARCH SCAFFOLDING ===================== -->
