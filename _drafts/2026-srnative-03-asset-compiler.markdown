---
layout: post
title:  "Soup Raiders Goes Native: The asset compiler and loading time"
categories: [gamedev, cpp]
series: soupraiders-native
---

In my quest to get sub 3s to load each level of Soup Raiders on the Nintendo Switch, I got to learn a bunch of things.

<!--more-->

The original assets:
- 3d models
- Sprites/textures
- Fmod music
- Unity prefab/scenes data

level	assets	textures	mesh	data	stored	read
docks	87	68 (21.5 MB)	2 (8.4 MB)	17 (5.7 MB read)	31.76 MB	35.16 MB
palace	54	37 (14.0 MB)	1 (4.4 MB)	16 (1.0 MB read)	18.78 MB	19.39 MB
fishpalace	41	29 (12.5 MB)	1 (1.6 MB)	11 (0.2 MB read)	14.16 MB	14.29 MB
globeisland	27	17 (4.7 MB)	2 (0.2 MB)	8 (0.2 MB read)	4.89 MB	5.03 MB

The biggest single reads per level:

docks — LevelDocks_baked.glb 7.94 · docks_collision.bin 5.55 · battle_character_atlas.ktx2 5.15 (deferred) · bg_rock_01.ktx2 3.25 · skybox.ktx2 2.74 · ending_atlas.ktx2 1.44 (deferred)
palace — battle_character_atlas 5.15 (deferred) · LevelPalace_baked.glb 4.38 · skybox 2.74 · palace_collision.bin 0.90
fishpalace — battle_character_atlas 5.15 (deferred) · skybox 2.74 · LevelFishPalace_baked.glb 1.58
globeisland — skybox 2.74 · overworld_npc_atlas 0.60 · character_atlas 0.47

Read once at boot, not per level: FMOD banks 35.67 MB (4), title + logos 16.31 MB (180 files), shaders 47 × .spv (0.20 MB), loading widget 0.19 MB, registry + cost table 0.02 MB. Whole image: 99.59 MB, 461 entries.

What's in the Docks?

What's in the Palace?

What's in the Fish Palace Boss Battle?

Separating the assets into zip
Compression vs fast reading.

PNG vs KTX2

Single images vs atlases

PhysFS

3d models -> converted to GLB from Unity
JSON to binary with cereal
Sprites -> put into atlases and converted to KTX2/
Unity gameplay data -> JSON -> Serialized binary data (using cereal but could use C++26 static reflection instead).

## Next

Profiling with Tracy — including the part where the client had to run on a platform it had never seen.

- https://www.gdcvault.com/play/1022268/Streaming-in-Sunset-Overdrive-s
- https://www.gdcvault.com/play/1027205/Zen-of-Streaming-Building-and
- https://gdcvault.com/play/1012445/Data-is-a-Four-Letter
- https://web.archive.org/web/20120614235137/http://www.bitsquid.se/files/resource_management.html
- https://web.archive.org/web/20120507185423/http://www.bitsquid.se/presentations/cutting-the-pipe.pdf
- https://www.dominikgrabiec.com/posts/2025/11/13/accu_2025_review.html