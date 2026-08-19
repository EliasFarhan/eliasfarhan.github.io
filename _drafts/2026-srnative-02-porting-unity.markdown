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

This allow for the PS5 game looks radically different while combat feels extraordinarily close to the PS3 game. Visually, an enormous amount was rebuilt. On the technical part, one way Marco Brush (the CEO and also engineer) described it was to start compiling the codebase, one compile error at a time, and then run the game and fix one crash at a time. But they did not just take the old code and recompiled it, but also introduced things like modernized character creation, a photo mode, the mirrored Fractured World, quality-of-life adjustments, much faster loading, updated controls and other changes. Because of the amount of work, I would say that Demon's Souls PS5 is a **remake**.

### Metal Wolf Chaos XD

![metal wolf](/images/2026/metal-wolf-chaos-xd-cover.jpg)

Hilarious game by FromSoftware released on Xbox original only in Japan in December 2004, where the player plays as the president of the USA on a mecha. You can watch a speedrun [here](https://www.youtube.com/watch?v=J1n0pVxS4sw) from SGDQ2014 with commentary explaining the gameplay. Funny enough, Devolver proposes to work with FromSoftware to rerelease the game out of the blue:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Count us in to help Metal Wolf Chaos get out to more gamers if From Software wants some help. <a href="https://x.com/hashtag/FreeMetalWolf?src=hash&amp;ref_src=twsrc%5Etfw">#FreeMetalWolf</a> <a href="https://t.co/867qay70j8">pic.twitter.com/867qay70j8</a></p>&mdash; Devolver Digital (@devolverdigital) <a href="https://x.com/devolverdigital/status/692330482176884736?ref_src=twsrc%5Etfw">January 27, 2016</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

And it actually worked! It took 16 months for the team of General Arcade (game page [here](https://generalarcade.com/projects/metal-wolf-chaos-xd/)) compsed by five software engineers, two QA engineers, producer, artist and two 3D modelers to make it. They used the PhyreEngine by Sony, C++ and FMOD and Direct3d 11 for Xbox One and GNM for PlayStation 4 to port the game.

![Diagram showing how General Arcade modernized the original Metal Wolf Chaos for PC, PS4, and Xbox One](/images/2026/sr/metal_wolf_chaos_xd_port.svg)

Because the CPU of the Xbox Original (an Intel Pentium III) is of the same family of our modern CPU on PC, PS4 and Xbox One (unlike the PS3 Cell processor) and probably that the amount of changes compare to the Xbox version is on the surface and not in the core, I would say *Metal Wolf Chaos XD* is a **remaster** and not a **remake**.

### Dusklight

![dusklight](/images/2026/dusklight.jpg)

I got a GameCube at the end of its lifetime (you can call me a patient gamer) and one of my favorite games on it (and in general) is The Legend of Zelda: Twilight Princess. Jump a few years when I discovered that the community had created a native version of this game release under the name Dusk in May 2026 and now called [Dusklight](https://twilitrealm.dev/posts/2026-05-09-dusk-v1-released/). 

But for Dusklight to simply exist, there was a other project that needed to decompile the original game *Twilight Princess* game. THis project is [ZeldaRET/tp](https://github.com/zeldaret/tp), which is not merely writing code that seems to behave similarly, but produce C/C++ code that produces the same machine instructions as the original executable.

![Diagram showing how community reverse engineering reconstructs source code that compiles to a matching GameCube executable](/images/2026/sr/dusklight_reverse_engineering.svg)

To reverse-engineer the PowerPC executable, they used [decomp-toolkit (or dtk)](https://github.com/encounter/decomp-toolkit), which is a tool that analyzed te original GameCube/Wii executable, discoverd functions, splits the binary into relocatable objects, generates linker information, symbols/splits, etc... This gives the pieces of the "puzzle" that the contributors needed to recreate the game. With each piece (compiled `.o`), they tried to recreate the C/C++ equivalent, then compiled it using the Metrowerks CodeWarrior compilers/linkers (used back in the days by Nintendo), which means regenerating PowerPC executable, comparing the resulting new `.o` with the origin game one using [objdiff](https://github.com/encounter/objdiff) and then reworking in a loop until both `.o` matches.

![Diagram showing the dtk, CodeWarrior, and objdiff loop used to recreate matching GameCube object files](/images/2026/sr/dusklight_matching_loop.svg)

But ZeldaRET is not a PC port, but it is that work that DUsklight uses to build upon. They use [Aurora](https://github.com/encounter/aurora) and its GX (and other) compatiblity layer to link all the game-derived code (from Nintendo's JKSystem), which greatly simplify the recompilation work as they don't need to refactor all the Nintendo's JKSystem call and add the library SDL3 to manage everything from input and graphics (I use the same library in Soup Raiders native port). In the end, this is how the architecture of Dusklight looks like: 

![Diagram of the Dusklight application, Twilight Princess framework, GameCube-style APIs, and Aurora compatibility layers](/images/2026/sr/dusklight_architecture.svg)

## And Soup Raiders?

I started to work on this Soup Raiders game with Unity 2017.4.1f1 in July 2018. I remember well because we were working on a demo that we could submit to [Pro Helvetia](https://prohelvetia.ch/en/find-support/game-design-emerging-talents-production/) (the Swiss Arts Council) to get some fundings to start the production of the game. At the time, the game looked like this:

![inital demo](/images/2026/sr/sr_old.png)

And I looked like this:

![elias pirate](/images/2026/elias_pirate.jpg)

After cancelling this project in mid-2019 and starting it again in march 2020 right when the COVID pandemic hit Europe. A new prototype started to form and looked like this:

<iframe width="560" height="315" src="https://www.youtube.com/embed/R-jQGsZWEio?si=NOOZ8W9sYOOb6Gqp" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

 The latest vertical slice (which is playable [here](https://teamkwakwa.itch.io/soup-raiders)) ran on Unity 2022.3.2f1 and featured three levels with three fights, one mini-boss and one boss. This is the view from the beginning of the demo in the docks of the Red Island:

![sr docks](/images/2026/sr/sr_docks_full.png)

A lot of things need to be migrated to my custom engine to have this same view and each of the composant of this demo have their specificities. Let's explore the different parts of this porting process. In this blog post, we will check what comes out of Unity from my game (and next blog post we will check how we put them in my game engine).

### The audio

This is the easiest part of the game to port. On Unity, I was using [FMOD](https://www.fmod.com/), a middleware where a sound designer can add events on their FMOD editor and then generates the banks to be imported in the game.

Fortunatley, FMOD is not Unity-only and features native libs for PC and for Nintendo Switch (as well as all the other modern platforms like PS4/PS5 etc... even HTML5). So the port was about copying the banks and statically linking the libs provided by FMOD. 

### 3d models

[Julie Baechtold](https://juba.artstation.com/) did an incredible work on Soup Raiders. She created the 3D models in Blender, and then put them in Unity to create the levels. As she was not familiar with `git`, I created a tool that would export her scene from Unity with all its dependencies for me to import them into my Unity project. 

Now there are several way to export back those models and the layout that Julie put in Unity:
1. Use Unity FBX Exporter package
2. Use Blender as an asset provider (exported as `.glb`) and Unity as the level composition
3. Parse `.unity` YAML file in my engine
4. Build a custom Unity scene exporter to generate `.glb` files (GLTF2) 

I went with solution 4. The script `ExportLevelGeometry.cs` is a Uniy Editor that will generate the GLB file of all the level. GLB files contains several parts:
- A JSON part describing the GLTF asset, the scenes, the nodes, the meshes, accessors, and buffers with their views.
- A Binary part contained all the positions, uv, indices of the meshes.

In the meantime, another script `ExportLevelRenderers.cs` exports the materials linked to the renderers, in short the visibility, textures, etc... All those are exported in to a simple `.json` file which allows to reference each textures that need to be exported as well. To join the renderer in both exporter, we use Unity **GlobalObjectId**. This allow us to export all those static meshes (including the static sprites):

![sr docks](/images/2026/sr/sr_static_mesh.png)

However, it's missing the brownish water of the Soup! Because this mesh is a bit special. It was not created on Blender, but created directly in Unity with a specific `ToonWater` shader (unlike a more Standard shader like the rest of the static level). It's actually simply four quads. It is exported also by `ExportLevelGeometry.cs` for the geometry (I want the same as Unity), but goes through `ExportDocksWater()` to generate `water_geometry.glb` and `water_instances.json`. Here it is now:

{% include image-comparison.html
  left_image="/images/2026/sr/sr_static_mesh.png"
  left_label="Without water"
  left_alt="Soup Raiders docks without the water"
  right_image="/images/2026/sr/sr_water_wit_meshes.png"
  right_label="With water"
  right_alt="Soup Raiders docks with the water"
  position=50
%}

### Colliders

Visual is nice, but my main character needs to walk on something. In the Unity demo, I spent a lot of time adjusting the physics boxes of each level to be sure the main character does not fall or does not get stuck in a wall or in stairs. For this to work as well on my engine, I needed to export the physics boxes as well. This goes through `ExportLevelCoilliders.cs` which export those colliders:
- Box colliders: emitted as hull (8 world corners)
- Convex mesh colldiers: hull (world vertices)
- Non-convex mesh colliders: mesh (vertices + triangles)
- Sphere colliders
- Capsule colliders

On top of the colliders, we also add the surface type from the GameObject tag: Wood -> 1, Stairs -> 2, ... Because the footsteps of the main character is different depending if they step on wood or stone. One other note is that the exporter excludes specific objects like moving characters (Dorothy has a collider, but it's not static). In the end, it looks like this:

![sr docks colliders](/images/2026/sr/sr_physics_box.png)

### Billboards

What makes the charm of Soup Raiders are those 2D animated characters. The main characters were animated by [Camille Bovey](https://camillebovey.com/) and Julie added a lot of those seagulls in the levels. They behave like billboard, always facing the camera. While the textures were already there for the export, like the placement of meshes in the level, we need to export the placement of those billboards. This is the job of `ExportLevelBillboards.cs` that exports the world position, the world lossy scale, the flipX, the texture, pixel rect, pivot Px (where are the foot of the character) and pixels per unit, as well as the single-frame talk icons of the talkative characters.

![sr docks](/images/2026/sr/sr_billboards.png)

There are two missing characters: 
- The main moving character that the player controls.
- Dorothy, who is also a cinematic moving character.

With them, the world more crowded:

![sr docks](/images/2026/sr/sr_all_characters.png)

### Skybox

As the skybox is already 6 textures, there is no need for Unity-side export. We will go more in details about the import of the skybox in my engine in the next blog post. But of course, it looks better with it:

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

In Soup Raiders, the players do not control the camera. Instead of using Cinemachine (I tend not to use all of Unity tools when I can do things myself), I implemented my own system that interpolate between snap points. Each of those points stored the camera position and direction as well as the character position (and character euler angles, but this is not exported), so the camera would move around, following the player. Those are exported as-is to a `.json` file.

I had an playmode snapshot recording system where I would move in the level with free orbit camera, then find a nice spot, and save the snapshot. The snap system would then connect the closest snap points with each other if they can raycast between each other. This looks like this in Unity (with the red spheres being the snap points and the red line the connection between them):

![sr rails](/images/2026/sr/sr_rails.png)

### Dialog


### Source code

174 files with 18421 lines.

Use a C# interpreter versus rewrite everything in C++.

GameObject + MonoBehavior
What needs to be rewritten by hand:
- Source code (C# -> C++) which makes for a nice refactor opportunity

Unity HLSL shaders to my engine GLSL shaders.

### Others
Ground Battle UI, Menu

## Conclusion

Next step is the Asset Compiler.
