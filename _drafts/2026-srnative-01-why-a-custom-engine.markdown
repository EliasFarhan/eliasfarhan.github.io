---
layout: post
title:  "Soup Raiders Goes Native (1/11): The case for a custom engine"
categories: [gamedev, cpp]
series: soupraiders-native
---

![](/images/2026/game_engine_share_release.png)

According to VGInsights, about 10% of games released on Steam in 2024 used a custom engine, while back in 2012 it was 71%! So looking at this trend, why should anybody try to make their own game engine?

<!--more-->

But... 

![](/images/2026/game_engine_share_sold.png)

Those games represent 41% of units sold in 2024 and, even those are mostly AAA game engines, it still means that making your own game engine can still make sense business-wise. 

Indie games in the 2008 were largely made with their own game engines.

Unity came.

Then Unity runtime fee in 2024.

"Make a game or make a game engine" is a statement often thrown over the faces of computer science students who already dream of creating their MMO even before they finished their bachelor. But in 2024, when Unity tried to add runtime fee into its own engine, a lot of indie game developers were looking at godot or running their own game engine. 

But why?

## Learning

Making your own game engine can actually teach you how Unity or Unreal or any engines work. 

I learned about rendering by teaching opengl with learnopengl

Cascaded shadow map -> a setting in Unity

Occlusion culling -> in Beach Slap, we disabled because we see all the objects.


## Independence

Renderware

The Machinery

Unity runtime fee

## Game's Need

Sometimes, your game is just too crazy

Total war

## References
- [Noel Berry's Making Video Games in 2025 (without an engine)](https://noelberry.ca/posts/making_games_in_2025/)
- https://www.gdcvault.com/play/1034506/Independent-Games-Summit-A-Case
- https://www.gamedeveloper.com/programming/real-reasons-not-to-build-custom-game-engines-in-2024
- https://github.com/raysan5/custom_game_engines 
- https://encelo.github.io/CustomEnginesPresentation/#1
- https://handmade.network/manifesto
- https://www.gamesindustry.biz/a-case-for-building-your-own-tech-opinion

# Game-engine research: games in “Games That Used Their Own Tech”

This note records the best publicly available evidence for the games shown in
the supplied screenshot. “Own engine” is used carefully: a game can have
game-specific, in-house code while still relying on a framework (such as XNA or
MonoGame) and middleware (such as SDL, FMOD, Spine, or OpenGL). Those pieces
are not, by themselves, the game's engine.

## Don’t Starve

Klei says the engine is custom-built in C++. Most gameplay is written in Lua;
art was made largely in Adobe Flash and exported to Klei's own animation format;
FMOD provides the audio backend. It is a true in-house engine with middleware,
not a Unity game.

Source: [Klei administrator’s technical answer](https://kleiforums.com/forums/topic/80262-which-game-engine-build-dont-starve-unity3d-or-self-build-engine/).

## Into the Breach

The game uses Subset Games’ custom technology, generally identified as C++ with
Lua scripting. Inspection of the PC build has identified SDL2, OpenType, ImGui,
Lua/LuaBind, and FMOD as supporting libraries. Subset has not published a full
technical breakdown, so those implementation details should be treated as
well-supported community findings rather than a complete official specification.

Sources: [engine discussion and build-library inventory](https://steamcommunity.com/app/590380/discussions/0/3288067088098370816/), [custom-engine catalogue](https://encelo.github.io/CustomEnginesPresentation/).

## FTL: Faster Than Light

FTL uses an in-house C++ engine, commonly described as SDL-based. The same
studio later used custom technology for *Into the Breach*. There is no detailed
official engine postmortem, so a precise feature or middleware list cannot be
stated with high confidence.

Source: [custom-engine catalogue](https://encelo.github.io/CustomEnginesPresentation/).

## Starbound

Chucklefish explicitly describes *Starbound* as a custom engine built with C++
and Lua. A staff-posted stack lists SDL, OpenGL/GLEW, FreeType, libpng, zlib,
Ogg Vorbis, and SSL; those are dependencies beneath the in-house engine.

Sources: [official FAQ](https://playstarbound.com/help/), [staff discussion of libraries](https://community.playstarbound.com/threads/what-framework-does-starbound-use.22492/).

## Factorio

Wube's own press material identifies the engine as custom, the programming
language as C++, and modding/level creation as Lua-based. Official technical
posts further document C++ implementation and deterministic multiplayer testing
across x86 and ARM, a central requirement of its simulation-heavy design.

Sources: [Wube press-kit details, reproduced on its forum](https://forums.factorio.com/viewtopic.php?t=46670), [official C++ discussion](https://www.factorio.com/blog/post/fff-349), [official deterministic-multiplayer write-up](https://www.factorio.com/blog/post/fff-370).

## Darkest Dungeon

Red Hook used a lightweight, cross-platform custom C++ engine built for this
game. For character animation, it uses Spine’s C++ runtime plus Red Hook’s
custom reader for Spine's binary `.skel` data. The first game—not *Darkest
Dungeon II*—is the one using this proprietary engine.

Sources: [Red Hook development interview](https://80.lv/articles/red-hook-studios-talks-about-the-creation-of-darkest-dungeon), [Red Hook staff explanation of animation format/runtime](https://steamcommunity.com/groups/dd-workshop/discussions/0/135514800409348324/), [console-port technical profile](https://www.sickhead.com/ported-games/darkest-dungeon/).

## Shovel Knight

Yacht Club Games built a custom C++ engine. Its original technical answer says
it uses DirectX on PC and OpenGL on macOS/Linux; Tiled was used for level
editing. The engine is proprietary to the studio, rather than a released
general-purpose product.

Source: [archived Yacht Club answer](https://www.gamedev.net/forums/topic/658779-what-did-they-used-to-develop-shovel-knight/).

## Prison Architect

Introversion made *Prison Architect* with a custom C++ engine, consistent with
the studio’s earlier cross-platform internal technology. Community and developer
forum records point to an engine lineage through Uplink, Darwinia, and Defcon;
however, the precise ancestry and individual rendering libraries are less firmly
documented than the custom-C++ conclusion.

Sources: [Introversion forum: custom C++ engine](https://forums.introversion.co.uk/viewtopic.php?sid=815c193c40ec9fc7ff9bc551575ccd9d&t=20800), [discussion of the likely engine lineage](https://forums.introversion.co.uk/viewtopic.php?t=18089).

## This War of Mine

11 bit studios used its proprietary **Liquid Engine**, first developed for
*Anomaly: Warzone Earth* and evolved between projects. The studio said it used
in-house tools; a technical presentation lists PC, macOS, Linux, consoles, and
mobile targets. This is one of the clearest named in-house engines in the list.

Sources: [11 bit interview](https://www.gamedeveloper.com/design/road-to-the-igf-11bit-studios-i-this-war-of-mine-i-/), [“Under the hood” presentation](https://www.slideshare.net/slideshow/presentation-eng-48432454/48432454).

## Banished

Solo developer Luke Hodorowicz described the code as C++ and “self-integrated,”
which is strong evidence for bespoke technology rather than a third-party
engine. Its mod support exposes data-driven additions such as buildings and
resources, while some systems remain hard-coded in the engine.

Source: [developer interview](https://primagames.com/gaming/banished-interview-with-developer-luke-hodorowicz).

## Pixel Dungeon

The original *Pixel Dungeon* is open-source Java and is better described as a
custom, Android-oriented game codebase than as a game made in a commercial
engine. Its later desktop port uses libGDX, but that is a port/framework choice,
not evidence that the original Android game used libGDX. This distinction is
frequently lost in engine lists.

Sources: [original project repository](https://github.com/watabou/pixel-dungeon), [libGDX desktop-port repository](https://github.com/watabou/pixel-dungeon-gdx), [libGDX’s description of itself as a Java framework](https://libgdx.com/).

## Bastion

Supergiant says *Bastion* runs on its own proprietary tools and technology,
written in C# by co-founder Gavin Simon specifically for the game. The technical
base included Microsoft XNA: thus it is custom game technology built on a
framework, not a fully from-scratch replacement for every XNA service.

Source: [Supergiant’s official Bastion FAQ](https://www.supergiantgames.com/blog/bastion-faq/).

## Stardew Valley

*Stardew Valley* is C# code built on Microsoft XNA originally and MonoGame on
Linux/macOS; it later migrated to MonoGame broadly in 2021. It has extensive
custom game systems, but XNA/MonoGame are frameworks, so calling it a wholly
from-scratch engine would be misleading.

Sources: [Stardew Valley Wiki development history](https://wiki.stardewvalley.net/Stardew_Valley), [MonoGame’s explanation that it is a framework](https://monogame.net/presskit/).

## Legend of Grimrock

Almost Human made *Legend of Grimrock* with proprietary custom technology and
continued using and improving it for *Legend of Grimrock II*. The engine is
written in C++; the series has an editor and a Lua-based modding/dungeon
workflow. Public material does not provide a reliable exhaustive middleware
list.

Sources: [custom-engine catalogue](https://encelo.github.io/CustomEnginesPresentation/), [Almost Human modding documentation](https://www.grimrock.net/modding/), [developer discussion mentioning C++ source/compile workflow](https://www.gamebanshee.com/news/108523-legend-of-grimrock-project-in-development-editor-draws-nearer.html).

## Crypt of the NecroDancer

*Crypt of the NecroDancer* is consistently classified as using a custom engine;
reports describe it as C++ with Lua scripting. Brace Yourself Games has not
published enough primary technical documentation to confirm a full architecture
or dependency list, so that language breakdown remains lower-confidence than
the conclusion that it is custom technology.

Sources: [custom-engine catalogue](https://encelo.github.io/CustomEnginesPresentation/), [engine classification](https://steamrev.com/games/crypt-of-the-necrodancer).

## Summary

The screenshot is broadly accurate. The strongest “built our own engine” cases
are Don’t Starve, Starbound, Factorio, Darkest Dungeon, Shovel Knight, Prison
Architect, Liquid Engine/*This War of Mine*, Banished, Legend of Grimrock, and
Crypt of the NecroDancer. *Bastion* and *Stardew Valley* are more precisely
custom game technology built on XNA/MonoGame. *Pixel Dungeon* is a custom,
open-source Java codebase; its libGDX use belongs to a later desktop port.
