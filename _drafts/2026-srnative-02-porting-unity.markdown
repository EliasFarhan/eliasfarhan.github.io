---
layout: post
title:  "Soup Raiders Goes Native: Porting the demo from Unity"
categories: [gamedev, cpp]
series: soupraiders-native
---

![sr docks](/images/2026/sr/sr_docks_full.png)

A port is not "the same game in another engine" or "just an emulator. It is a long series of decisions about what to do with the original content (art, code, audio) to create a new version its own set of constraints. In this blog post, we will first introduce the variations of port and then see what I did on the port of Soup Raiders from Unity to my native engine.

<!--more-->

## Porting games

One might have heard of *Remastered* or *Remake* or even *Recompilation*, sometimes it can be confusing to know exactly what each entry in the taxonomy of porting is. There are nearly as many different types of porting than there is game ports. Let's explore some concrete examples before defining terms.

### Demon's Souls PS5 (2020)

![demonsousl](/images/2026/demonsouls.jpg)

For the release of the PS5, Bluepoint Games worked with Sony Japan Studio to remake the PS3 Demon's Souls by FromSoftware. There is a very nice documentary by /noclip ([here](https://www.youtube.com/watch?v=hCBJ2fiiUXk)) on this subject where they interview the team behind the game. From their [DF interview](https://www.youtube.com/watch?v=9O--CnN056E), the developers at Bluepoint described this port as a two-engine arragment in this way:

![Diagram showing the original Demon's Souls game systems running alongside Bluepoint technology](/images/2026/sr/demons_souls_bluepoint.svg)

This allow for the PS5 game looks radically different while combat feels extraordinarily close to the PS3 game. Visually, an enormous amount was rebuilt. On the technical part, one way Marco Brush (the CEO and also engineer) described it was to start compiling the codebase, one compile error at a time, and then run the game and fix one crash at a time. But they did not just take the old code and recompiled it, bnut also introduced things like modernized character creation, a photo mode, the mirrored Fractured World, quality-of-life adjustments, much faster loading, updated controls and other changes.

Bluepoint Games was acquired by SIE on September 30, 2021, and unfortunatley on February 2026, SIE announned that it would shut down the studio.

### Metal Wolf Chaos XD

![metal wolf](/images/2026/metal-wolf-chaos-xd-cover.jpg)

Hilarious game by FromSoftware released on Xbox original. You can watch a speedrun [here](https://www.youtube.com/watch?v=J1n0pVxS4sw) from SGDQ2014

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Count us in to help Metal Wolf Chaos get out to more gamers if From Software wants some help. <a href="https://x.com/hashtag/FreeMetalWolf?src=hash&amp;ref_src=twsrc%5Etfw">#FreeMetalWolf</a> <a href="https://t.co/867qay70j8">pic.twitter.com/867qay70j8</a></p>&mdash; Devolver Digital (@devolverdigital) <a href="https://x.com/devolverdigital/status/692330482176884736?ref_src=twsrc%5Etfw">January 27, 2016</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

![Diagram showing how General Arcade modernized the original Metal Wolf Chaos for PC, PS4, and Xbox One](/images/2026/sr/metal_wolf_chaos_xd_port.svg)

### Dusklight

![dusklight](/images/2026/dusklight.jpg)

I got a GameCube at the end of its lifetime (you can call me a patient gamer) and one of my favorite games on it (and in general) is The Legend of Zelda: Twilight Princess. Jump a few years when I discovered that the community had created a native version of this game release under the name Dusk in May 2026 and now called [Dusklight](https://twilitrealm.dev/posts/2026-05-09-dusk-v1-released/). 

But for Dusklight to simply exist, there was a other project that needed to decompile the original game *Twilight Princess* game. THis project is [ZeldaRET/tp](https://github.com/zeldaret/tp), which is not merely writing code that seems to behave similarly, but produce C/C++ code that produces the same machine instructions as the original executable.

![Diagram showing how community reverse engineering reconstructs source code that compiles to a matching GameCube executable](/images/2026/sr/dusklight_reverse_engineering.svg)

To reverse-engineer the PowerPC executable, they used [decomp-toolkit (or dtk)](https://github.com/encounter/decomp-toolkit), which is a tool that analyzed te original GameCube/Wii executable, discoverd functions, splits the binary into relocatable objects, generates linker information, symbols/splits, etc... This gives the pieces of the "puzzle" that the contributors needed to recreate the game. With each piece (compiled `.o`), they tried to recreate the C/C++ equivalent, then compiled it using the Metrowerks CodeWarrior compilers/linkers (used back in the days by Nintendo), which means regenerating PowerPC executable, comparing the resulting new `.o` with the origin game one using [objdiff](https://github.com/encounter/objdiff) and then reworking in a loop until both `.o` matches.

![Diagram showing the dtk, CodeWarrior, and objdiff loop used to recreate matching GameCube object files](/images/2026/sr/dusklight_matching_loop.svg)

But ZeldaRET is not a PC port, but it is that work that DUsklight uses to build upon. They use [Aurora](https://github.com/encounter/aurora) and its GX (and other) compatiblity layer to link all the game-derived code (from Nintendo's JKSystem), which greatly simplify the recompilation work as they don't need to refactor all the Nintendo's JKSystem call and add the library SDL3 to manage everything from input and graphics (I use the same library in Soup Raiders native port). In the end, this is how the architecture of Dusklight looks like: 

![Diagram of the Dusklight application, Twilight Princess framework, GameCube-style APIs, and Aurora compatibility layers](/images/2026/sr/dusklight_architecture.svg)


### Mega Man Legacy Collection

### Taxonomy

| Type | What usually happens | Typical examples |
|---|---|---|
| **Emulated re-release** | The original executable/ROM remains essentially intact and runs inside an emulator packaged for the modern platform. Modern UI, save states, controller support, filters, achievements, etc. may be added around it. | [SNK 40th Anniversary Collection](https://www.digitaleclipse.com/games/snk40) by Digital Eclipse; [Rocket Knight Adventures: Re-Sparked](https://limitedrungames.com/products/rocket-knight-adventures-re-sparked) using Limited Run's Carbon Engine |
| **Source port** | The original game's source code or game logic is compiled for a new platform. Platform-specific systems such as rendering, audio, input, filesystem access, and networking are replaced or abstracted while much of the original game remains intact. | [System Shock: Enhanced Edition](https://nightdivestudios.com/system-shock-enhanced-edition/) by Nightdive Studios, adapted to the KEX Engine |
| **Enhanced port** | Fundamentally the same game and implementation are brought to another platform, but with additions such as widescreen, higher resolutions, modern controls, improved performance, new save functionality, or quality-of-life features. | [Metal Wolf Chaos XD](https://generalarcade.com/projects/metal-wolf-chaos-xd/) by General Arcade / FromSoftware / Devolver Digital; General Arcade moved the 2004 Xbox game to PC, PS4 and Xbox One with 4K support and updated controls |
| **Remaster** | The original game remains substantially authoritative, but rendering, textures, models, lighting, audio, UI, controls or other presentation systems may be extensively upgraded. Portions of the engine can even be replaced without necessarily turning the project into a remake. | [Star Wars: Dark Forces Remaster](https://nightdivestudios.com/star-wars-dark-forces-remaster/) by Nightdive Studios, rebuilt for modern platforms using KEX with high-resolution assets, modern rendering and controller support |
| **Recompilation** | The original executable is translated or reconstructed into code that can be compiled for modern CPUs. This can range from automated static recompilation of machine code to decompilation-based projects that recover source code first and then adapt it for modern platforms. | [N64: Recompiled](https://github.com/N64Recomp/N64Recomp), used by projects such as [Zelda 64: Recompiled](https://github.com/Zelda64Recomp/Zelda64Recomp); [The Legend of Zelda: Twilight Princess decompilation](https://github.com/zeldaret/tp) by ZeldaRET, which became the basis for the native [Dusklight](https://twilitrealm.dev/) port |
| **Engine reimplementation / reverse-engineered port** | A new engine or runtime is written to reproduce the behavior of the original engine and interpret the original game's data files. The original executable itself may no longer be required, although the original assets usually are. | [OpenMW](https://openmw.org/) reimplements the engine used by *The Elder Scrolls III: Morrowind*; [OpenTTD](https://www.openttd.org/) began as a reimplementation of *Transport Tycoon Deluxe* |
| **Hybrid reconstruction** | Original gameplay code, logic or data remains authoritative, while substantial pieces of the technology and presentation are rebuilt: renderer, animation systems, assets, lighting, effects, etc. It sits between a remaster and a full remake. | [Shadow of the Colossus (PS4)](https://blog.playstation.com/2018/01/26/shadow-of-the-colossus-remaking-a-masterpiece/) by Bluepoint Games / Japan Studio; the game preserved the character and behavior of the original while its presentation and technology were massively reconstructed |
| **Faithful remake** | The original game is substantially rebuilt as a new implementation, typically with new rendering technology, assets and production pipelines, while attempting to preserve the original level design, mechanics, progression and overall experience. | [Demon's Souls (PS5)](https://www.playstation.com/games/demons-souls/) by Bluepoint Games / Japan Studio; [Shadow of the Colossus (PS4)](https://blog.playstation.com/2017/12/09/shadow-of-the-colossus-ps4-pro-enhancements-special-edition-revealed/) was officially described by Sony as a "full, ground up remake" |
| **Reimagining** | The older game serves as a creative blueprint rather than an implementation that must be preserved. Story, combat, camera, levels, mechanics, pacing or structure can be substantially redesigned. | [Final Fantasy VII Remake](https://ffvii-remake-intergrade.square-enix-games.com/) by Square Enix; [Resident Evil 2](https://www.residentevil2.com/) by Capcom |
| **Archival / documentary re-release** | Original games are preserved through emulation, but the release also acts as an interactive museum containing documents, prototypes, interviews, timelines, artwork and historical material. | [Atari 50: The Anniversary Celebration](https://www.digitaleclipse.com/games/atari50) by Digital Eclipse; Digital Eclipse describes its specialty as archival game re-releases and interactive documentaries |



## And Soup Raiders?

Let's go back to my Unity game with the view from the beginning of the demo in the docks of the Red Island:

![sr docks](/images/2026/sr/sr_docks_full.png)

### The audio

This is the easiest part of the game to port. On Unity, I was using [FMOD](https://www.fmod.com/), a middleware where a sound designer can add events on their FMOD editor and then generates the banks to be imported in the game.

Fortunatley, FMOD is not Unity-only and features native libs for PC and for Nintendo Switch (as well as all the other modern platforms like PS4/PS5 etc... even HTML5). So the port was about copying the banks and statically linking the libs.

### 3d models

![sr docks](/images/2026/sr/sr_static_mesh.png)


{% include image-comparison.html
  left_image="/images/2026/sr/sr_static_mesh.png"
  left_label="Without water"
  left_alt="Soup Raiders docks without the water"
  right_image="/images/2026/sr/sr_water_wit_meshes.png"
  right_label="With water"
  right_alt="Soup Raiders docks with the water"
  position=50
%}


### Billboards


![sr docks](/images/2026/sr/sr_billboards.png)

Adding 
![sr docks](/images/2026/sr/sr_all_characters.png)


### Skybox

{% include image-comparison.html
  left_image="/images/2026/sr/sr_water_wit_meshes.png"
  left_label="Without skybox"
  left_alt="Soup Raiders docks without the skybox"
  right_image="/images/2026/sr/sr_level_skybox.png"
  right_label="With skybox"
  right_alt="Soup Raiders docks with the skybox"
  position=15
%}

### Snap rails

In Soup Raiders, the players do not control the camera. 

![sr rails](/images/2026/sr/sr_rails.png)


### Source code

Use a C# interpreter versus rewrite everything in C++.

GameObject + MonoBehavior
What needs to be rewritten by hand:
- Source code (C# -> C++) which makes for a nice refactor opportunity


## Conclusion

Next step is the renderer.
