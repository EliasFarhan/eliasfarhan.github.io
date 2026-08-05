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

Those games represent 41% of units sold in 2024 and, even those are mostly AAA game engines, it still means that making your own game engine can still make sense business-wise. Even Anthropic thinks Claude Code is a game engine:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Most people&#39;s mental model of Claude Code is that &quot;it&#39;s just a TUI&quot; but it should really be closer to &quot;a small game engine&quot;.<br><br>For each frame our pipeline constructs a scene graph with React then<br>-&gt; layouts elements<br>-&gt; rasterizes them to a 2d screen<br>-&gt; diffs that against the…</p>&mdash; Thariq (@trq212) <a href="https://x.com/trq212/status/2014051501786931427?ref_src=twsrc%5Etfw">January 21, 2026</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

So while we can think that most indie games are made with Unity or Unreal, actually there is a big list of them who have custom engines, among others:

| Game                     | Studio                | Release Year | Engine / Technology                 |
| ------------------------ | --------------------- | ------------ | ----------------------------------- |
| Don't Starve             | Klei Entertainment    | 2013         | Custom C++ engine, Lua              |
| Into the Breach          | Subset Games          | 2018         | Custom C++ engine, Lua, SDL2        |
| FTL: Faster Than Light   | Subset Games          | 2012         | Custom C++ engine, SDL              |
| Starbound                | Chucklefish           | 2016         | Custom C++ engine, Lua, SDL, OpenGL |
| Factorio                 | Wube Software         | 2020         | Custom C++ engine, Lua              |
| Darkest Dungeon          | Red Hook Studios      | 2016         | Custom C++ engine, Spine            |
| Shovel Knight            | Yacht Club Games      | 2014         | Custom C++ engine, DirectX/OpenGL   |
| Prison Architect         | Introversion Software | 2015         | Custom C++ engine                   |
| This War of Mine         | 11 bit studios        | 2014         | Liquid Engine                       |
| Banished                 | Shining Rock Software | 2014         | Custom C++ engine                   |
| Pixel Dungeon            | Watabou               | 2012         | Java (later ported with libGDX)     |
| Bastion                  | Supergiant Games      | 2011         | Custom C# technology, Microsoft XNA |
| Stardew Valley           | ConcernedApe          | 2016         | C#, Microsoft XNA/MonoGame          |
| Legend of Grimrock       | Almost Human          | 2012         | Custom C++ engine, Lua              |
| Crypt of the NecroDancer | Brace Yourself Games  | 2015         | Custom C++ engine, Lua              |



I still remember "Indie Game: The Movie" where all the games shown in the documentary were made with custom engines as well. But then of course, Unity came and here is a list of games made with Unity:

| Game | Studio | Release Date | 
|------|--------|--------------| 
| Hollow Knight | Team Cherry | February 24, 2017 | 
| Outer Wilds | Mobius Digital | May 28, 2019 | 
| Cuphead | Studio MDHR | September 29, 2017 | 
| Subnautica | Unknown Worlds Entertainment | January 23, 2018 | 
| Untitled Goose Game | House House | September 20, 2019 | 
| INSIDE | Playdead | June 29, 2016 | 
| Risk of Rain 2 | Hopoo Games | August 11, 2020 (1.0) | 
| The Forest | Endnight Games | April 30, 2018 (1.0) | 
| Neon White | Angel Matrix | June 16, 2022 | 
| Unpacking | Witch Beam | November 2, 2021 |

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

## Modding



## References
- [Noel Berry's Making Video Games in 2025 (without an engine)](https://noelberry.ca/posts/making_games_in_2025/)
- https://www.gdcvault.com/play/1034506/Independent-Games-Summit-A-Case
- https://www.gamedeveloper.com/programming/real-reasons-not-to-build-custom-game-engines-in-2024
- https://github.com/raysan5/custom_game_engines 
- https://encelo.github.io/CustomEnginesPresentation/#1
- https://handmade.network/manifesto
- https://www.gamesindustry.biz/a-case-for-building-your-own-tech-opinion
