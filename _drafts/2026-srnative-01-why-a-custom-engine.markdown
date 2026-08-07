---
layout: post
title:  "Soup Raiders Goes Native (1/?): The case for a custom engine"
categories: [gamedev, cpp]
series: soupraiders-native
---

![](/images/2026/game_engine_share_release.png)

According to VGInsights, about 10% of games released on Steam in 2024 used a custom engine, while back in 2012 it was 71%! So looking at this trend, why should anybody try to make their own game engine?

<!--more-->

But... 

![](/images/2026/game_engine_share_sold.png)

Those games still represent 41% of units sold in 2024 and, even if those are mostly AAA game engines, it still means that making your own game engine can still make sense business-wise. So this blog post is about the why should you make a game engine.

However, before answering this question, we need to define what a game engine is, because even Anthropic thinks Claude Code is a custom game engine:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Most people&#39;s mental model of Claude Code is that &quot;it&#39;s just a TUI&quot; but it should really be closer to &quot;a small game engine&quot;.<br><br>For each frame our pipeline constructs a scene graph with React then<br>-&gt; layouts elements<br>-&gt; rasterizes them to a 2d screen<br>-&gt; diffs that against the…</p>&mdash; Thariq (@trq212) <a href="https://x.com/trq212/status/2014051501786931427?ref_src=twsrc%5Etfw">January 21, 2026</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

## What's a game engine and what do we mean by custom?

A game engine is a software that allows to create and run a computer game. It sits between the actual game code (gameplay logic) and the operating system (Windows, SteamOS, Android): 

![](/images/2026/game_engine_stack.svg)

In this position, the game engine role is to make sure that the game loop is running by interacting with the OS accordingly. This game loop runs as follow:

![](/images/2026/game_loop.svg)

- **Event Polling**: window resizing, keyboard/mouse/controller input changes, exiting the game, ...  
- **Gameplay**: physics, calling the gameplay code
- **Rendering**: generating the commands to be sent to the GPU to then present the new images on the screen.

But that's not all what a game engine is supposed to do, it also needs to load all the assets that the game need (3d models, animations, sprites, music and sounds) and all of this is work that is not implementing the specifics of the actual game. 

So it's no wonder that at the beginning of any project, the question of developing our own game engine arise. Technically, the goal of commerical game engines like Unreal or Unity is to sell you the game engine such that you only have to focus on making your game. While making a custom game engine is implementing this part by hand or at least gluing frameworks and libraries together to make this under-the-hood engineering. Here are some examples:

- I use Unity, but I develop a lot of internal tools <- **not** a custom game engine.
- I use SDL3 + assimp to make a 3d <- this is a custom game engine.
- I use Unreal, but I rewrote the renderer <- **not** a custom game engine.
- I use SFML to make a simple 2d networking game <- this is a custom game engine.
- I use Godot and extended it with C++ <- **not** a custom game engine.
- I handwrote from scratch the renderer in DX12 and I open a window with the Windows API <- this is a custom game engine.


So now it's good to look at a list of games that have a custom game engine. I still remember "Indie Game: The Movie" where all the games shown in the documentary were made with custom engines as well.  But also all those very successfull games:

| Game                     | Studio                | Release Date      | Engine / Technology                 |
| ------------------------ | --------------------- | ----------------- | ----------------------------------- |
| Don't Starve             | Klei Entertainment    | April 23, 2013    | Custom C++ engine, Lua              |
| Into the Breach          | Subset Games          | February 27, 2018 | Custom C++ engine, Lua, SDL2        |
| FTL: Faster Than Light   | Subset Games          | September 14, 2012 | Custom C++ engine, SDL              |
| Starbound                | Chucklefish           | July 22, 2016     | Custom C++ engine, Lua, SDL, OpenGL |
| Factorio                 | Wube Software         | August 14, 2020   | Custom C++ engine, Lua              |
| Darkest Dungeon          | Red Hook Studios      | January 19, 2016  | Custom C++ engine, Spine            |
| Shovel Knight            | Yacht Club Games      | June 26, 2014     | Custom C++ engine, DirectX/OpenGL   |
| Prison Architect         | Introversion Software | October 6, 2015   | Custom C++ engine                   |
| This War of Mine         | 11 bit studios        | November 14, 2014 | Liquid Engine                       |
| Banished                 | Shining Rock Software | February 18, 2014 | Custom C++ engine                   |
| Pixel Dungeon            | Watabou               | November 29, 2012 | Java (later ported with libGDX)     |
| Bastion                  | Supergiant Games      | July 20, 2011     | Custom C# technology, Microsoft XNA |
| Stardew Valley           | ConcernedApe          | February 26, 2016 | C#, Microsoft XNA/MonoGame          |
| Legend of Grimrock       | Almost Human          | April 11, 2012    | Custom C++ engine, Lua              |
| Crypt of the NecroDancer | Brace Yourself Games  | April 23, 2015    | Custom C++ engine, Lua              |


But then of course, it does not mean that all the successfull indie games have their own custom game engine. Unity took a big market share in mobile game development as well as indie games. For example, here is a list of games made with Unity:

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


But we still have this "Make a game or make a game engine" statement that we throw over the faces of computer science students who already dream of creating their MMO even before they finished their bachelor. Because like Tyrel Gaiel puts it (in this blog post [here](https://medium.com/geekculture/how-to-make-your-own-game-engine-and-why-ddf0acbc5f3)): 
> You think you can just make something better than Unity or Unreal (or Godot or GameMaker) in general. You can’t. It’s possible to make something that is better than these for specific use cases [...], but you, as an individual or a tiny team, are not going to compete with these for general purpose stuff. Especially if you have never made your own game engine before.

Our goal with this Soup Raiders Native Port is not to make Unity or Unreal, but it is to make a game engine that supports this specific game. So now that we know what a custom game engine is, we can try to answer the question of why making a game engine.

## Learning

Making your own game engine can actually teach you how Unity or Unreal or any engines work. 

I learned about rendering by teaching OpenGL with learnopengl.

Cascaded shadow map -> a setting in Unity

Occlusion culling -> in Beach Slap, we disabled because we see all the objects.


## Independence



| Event                                          | Simple summary                                                                                                                                                                                                | Year / Timeline         | Reference                                                                                                                                                                                                                                                                                  |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **RenderWare no longer available**             | **2004–2007:** After EA acquired Criterion in **2004**, RenderWare was gradually withdrawn as commercial middleware and effectively disappeared from the market by **2007**. ([Wikipedia][1])                 | **2004 → 2007**         | EA acquisition: [GameSpot – EA assimilates Criterion](https://www.gamespot.com/articles/ea-assimilates-criterion/1100-6103640/?utm_source=chatgpt.com) · History: [RenderWare overview](https://en.wikipedia.org/wiki/RenderWare?utm_source=chatgpt.com)                                   |
| **The Machinery shut down**                    | **2022:** Our Machinery announced it was ending development of **The Machinery** game engine and instructed users to delete source code and binaries. ([NME][2])                                              | **August 2022**         | [NME – The Machinery game engine cancelled](https://www.nme.com/news/gaming-news/the-machinery-game-engine-cancelled-as-developers-told-to-delete-all-source-code-3283633?utm_source=chatgpt.com)                                                                                          |
| **Unity Runtime Fee introduced then canceled** | **2023–2024:** Unity announced the Runtime Fee in **September 2023**, faced major community backlash, revised the policy, and ultimately canceled it entirely in **September 2024**. ([Unity Discussions][3]) | **Sep 2023 → Sep 2024** | Announcement: [Unity pricing update (2023)](https://discussions.unity.com/t/unity-plan-pricing-and-packaging-updates/927079?utm_source=chatgpt.com) · Cancellation: [Unity is canceling the Runtime Fee](https://unity.com/blog/unity-is-canceling-the-runtime-fee?utm_source=chatgpt.com) |

[1]: https://en.wikipedia.org/wiki/Criterion_Games?utm_source=chatgpt.com "Criterion Games"
[2]: https://www.nme.com/news/gaming-news/the-machinery-game-engine-cancelled-as-developers-told-to-delete-all-source-code-3283633?utm_source=chatgpt.com "The Machinery game engine cancelled as devs told to delete source code"
[3]: https://discussions.unity.com/t/unity-plan-pricing-and-packaging-updates/927079?utm_source=chatgpt.com "Unity plan pricing and packaging updates - News & General Discussion - Unity Discussions"


Costs:

| Engine              |                                               Upfront Cost | Revenue Share / Royalty                                                  | Notes                                                                                                                                                                            |
| ------------------- | ---------------------------------------------------------: | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Unity**           | Personal: Free<br>Pro: Paid per seat (annual subscription) | **None**                                                                 | Runtime Fee was cancelled in 2024. Unity now uses a traditional seat-based subscription model. Existing Pro/Enterprise pricing increased slightly in 2025–2026. ([The Verge][1]) |
| **Unreal Engine 5** |                                                       Free | **5% royalty** after the first **US$1M lifetime gross revenue per game** | Revenue earned through the Epic Games Store is royalty-free. Non-game commercial users over US$1M annual revenue pay **US$1,850/seat/year** instead. ([Unreal Engine][2])        |
| **GameMaker**       |                                    Free for non-commercial | **US$99.99 one-time** for commercial games                               | Enterprise (console exports) is **US$79.99/month** or **US$799.99/year**. ([GameMaker][3])                                                                                       |
| **CRYENGINE**       |                                                       Free | **5% royalty**                                                           | First **US$5,000/year/project** is royalty-free. Full source code included. ([CRYENGINE][4])                                                                                     |
| **Godot**           |                                                   **Free** | **None**                                                                 | MIT license. No royalties, subscriptions, or revenue limits. ([Godot Engine][5])                                                                                                 |

[1]: https://www.theverge.com/2024/9/12/24242937/unity-runtime-fee-cancelled-subscription-pricing?utm_source=chatgpt.com "Unity has eliminated its controversial runtime fee"
[2]: https://www.unrealengine.com/license?utm_source=chatgpt.com "Unreal Engine (UE5) licensing options - Unreal Engine"
[3]: https://gamemaker.io/en/help/articles/november-2023-pricing-terms-change-faq?utm_source=chatgpt.com "November 2023 Pricing/Terms Change FAQ"
[4]: https://www.cryengine.com/support/view/licensing?utm_source=chatgpt.com "CRYENGINE | Support: Licensing"
[5]: https://godotengine.org/license/?utm_source=chatgpt.com "License – Godot Engine"


## Specialization

Sometimes, your game is just too crazy

Total war, Factorio

## Modding


No modding for Splash Blast Panic.
For Beach Slap, we have a custom level editor in the game, but we don't let the possibility through a tool to change the content of the game.

## Conclusion

Making a game has a lot of good, but at a time cost. We control how we load and upadte our game (to the specific need of our game), we owe no license to anybody, and we learn a bunch about asset compilation, rendering, and optimization. In the rest of the series, we will detail in the implementation details of the Soup Raiders Native Port and how we can target 60Hz in the Switch with sub-3s loading time.   

## References
- [Noel Berry's Making Video Games in 2025 (without an engine)](https://noelberry.ca/posts/making_games_in_2025/)
- https://www.gdcvault.com/play/1034506/Independent-Games-Summit-A-Case
- https://www.gamedeveloper.com/programming/real-reasons-not-to-build-custom-game-engines-in-2024
- [Raysan5's list of custom game engines](https://gist.github.com/raysan5/909dc6cf33ed40223eb0dfe625c0de74)
- https://encelo.github.io/CustomEnginesPresentation/#1
- https://handmade.network/manifesto
- https://www.gamesindustry.biz/a-case-for-building-your-own-tech-opinion
- https://norikitech.com/posts/make-your-game/ 
- https://medium.com/geekculture/how-to-make-your-own-game-engine-and-why-ddf0acbc5f3 
- https://lisyarus.github.io/blog/posts/so-you-want-to-make-a-game-engine.html 