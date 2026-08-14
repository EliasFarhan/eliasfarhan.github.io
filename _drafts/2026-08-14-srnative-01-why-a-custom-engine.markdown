---
layout: post
title:  "Soup Raiders Goes Native: What You Gain by Building Your Own Game Engine"
categories: [gamedev, cpp]
series: soupraiders-native
---

![](/images/2026/game_engine_share_release.png)

According to VGInsights, about 10% of games released on Steam in 2024 used a custom engine, down from 71% in 2012. So looking at this trend, why should anybody try to make their own game engine?

<!--more-->

But... 

![](/images/2026/game_engine_share_sold.png)

Those games still accounted for 41% of units sold in 2024. Even if most were AAA games built with custom engines, the figure shows that developing your own engine can still make business sense. So this blog post is about why you should make a game engine.

However, before answering this question, we need to define what a game engine is. The term is broad enough that Claude Code has even been compared to a small game engine:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Most people&#39;s mental model of Claude Code is that &quot;it&#39;s just a TUI&quot; but it should really be closer to &quot;a small game engine&quot;.<br><br>For each frame our pipeline constructs a scene graph with React then<br>-&gt; layouts elements<br>-&gt; rasterizes them to a 2d screen<br>-&gt; diffs that against the…</p>&mdash; Thariq (@trq212) <a href="https://x.com/trq212/status/2014051501786931427?ref_src=twsrc%5Etfw">January 21, 2026</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

## What's a game engine and what do we mean by custom?

A game engine is a reusable software framework that lets you create and run a computer game. It sits between the actual game code (gameplay logic) and the operating system (Windows, SteamOS, Android):

![](/images/2026/game_engine_stack.svg)

The game engine's primary role is to keep the game loop running and handle interactions with the operating system. This game loop runs as follows:

![](/images/2026/game_loop.svg)

- **Event Polling**: window resizing, keyboard/mouse/controller input changes, exiting the game…
- **Gameplay**: physics, calling the gameplay code
- **Rendering**: generating the commands to be sent to the GPU to then present the new images on the screen

A game engine must do much more: it also loads the game's assets—3D models, animations, sprites, music, and sound—yet none of these systems implements the game's specific rules or content. We will go into more detail in the next blog posts about each part and how it is implemented in Soup Raiders Native.

At the beginning of any game project, then, the question of whether to build a custom engine naturally arises. The goal of commercial game engines like Unreal or Unity is to sell you the game engine so that you only have to focus on making your game, whereas making a custom game engine means implementing that part by hand, or at least gluing frameworks and libraries together to do this under-the-hood engineering yourself. Here are some examples:

- I use Unity, but I develop a lot of internal tools <- **not** a custom game engine.
- I use SDL3 + Assimp to make a 3D game <- this is a custom game engine.
- I use Unreal, but I rewrote the renderer <- **not** a custom game engine.
- I use SFML to make a simple 2D networking game <- this is a custom game engine.
- I use Godot and extend it with C++ <- **not** a custom game engine.
- I handwrote the renderer from scratch in DX12 and opened a window with the Windows API <- this is a custom game engine.


It is worth looking at some games built with custom engines. I still remember *Indie Game: The Movie*, in which every featured game was built with a custom engine. Many other successful games have also been built with custom engines:

| Game                     | Studio                | Release Date      | Engine / Technology                 |
| ------------------------ | --------------------- | ----------------- | ----------------------------------- |
| Bastion                  | Supergiant Games      | July 20, 2011     | Custom C# technology, Microsoft XNA |
| Legend of Grimrock       | Almost Human          | April 11, 2012    | Custom C++ engine, Lua              |
| FTL: Faster Than Light   | Subset Games          | September 14, 2012 | Custom C++ engine, SDL              |
| Pixel Dungeon            | Watabou               | November 29, 2012 | Java (later ported with libGDX)     |
| Don't Starve             | Klei Entertainment    | April 23, 2013    | Custom C++ engine, Lua              |
| Banished                 | Shining Rock Software | February 18, 2014 | Custom C++ engine                   |
| Shovel Knight            | Yacht Club Games      | June 26, 2014     | Custom C++ engine, DirectX/OpenGL   |
| This War of Mine         | 11 bit studios        | November 14, 2014 | Liquid Engine                       |
| Crypt of the NecroDancer | Brace Yourself Games  | April 23, 2015    | Custom C++ engine, Lua              |
| Prison Architect         | Introversion Software | October 6, 2015   | Custom C++ engine                   |
| Darkest Dungeon          | Red Hook Studios      | January 19, 2016  | Custom C++ engine, Spine            |
| Stardew Valley           | ConcernedApe          | February 26, 2016 | C#, Microsoft XNA/MonoGame          |
| Starbound                | Chucklefish           | July 22, 2016     | Custom C++ engine, Lua, SDL, OpenGL |
| Into the Breach          | Subset Games          | February 27, 2018 | Custom C++ engine, Lua, SDL2        |
| Factorio                 | Wube Software         | August 14, 2020   | Custom C++ engine, Lua              |


But of course, this does not mean that every successful indie game has its own custom game engine. Unity gained a large share of both the mobile and indie game markets. For example, here is a list of games made with Unity:

| Game | Studio | Release Date | 
|------|--------|--------------| 
| INSIDE | Playdead | June 29, 2016 | 
| Hollow Knight | Team Cherry | February 24, 2017 | 
| Cuphead | Studio MDHR | September 29, 2017 | 
| Subnautica | Unknown Worlds Entertainment | January 23, 2018 | 
| The Forest | Endnight Games | April 30, 2018 (1.0) | 
| Outer Wilds | Mobius Digital | May 28, 2019 | 
| Untitled Goose Game | House House | September 20, 2019 | 
| Risk of Rain 2 | Hopoo Games | August 11, 2020 (1.0) | 
| Unpacking | Witch Beam | November 2, 2021 |
| Neon White | Angel Matrix | June 16, 2022 | 


But we still repeat the "make a game, not a game engine" advice to computer science students who dream of creating an MMO before they have even finished their bachelor's degree. Yuri Karabatov makes a similar argument in [*Make Your Game, Not an Engine*](https://norikitech.com/posts/make-your-game/). As Tyler Glaiel puts it in [*How to Make Your Own Game Engine (and Why)*](https://medium.com/geekculture/how-to-make-your-own-game-engine-and-why-ddf0acbc5f3):
> You think you can just make something better than Unity or Unreal (or Godot or GameMaker) in general. You can’t. It’s possible to make something that is better than these for specific use cases [...], but you, as an individual or a tiny team, are not going to compete with these for general purpose stuff. Especially if you have never made your own game engine before.

I really like the approach Noel Berry describes in [*Making Video Games in 2025 (Without an Engine)*](https://noelberry.ca/posts/making_games_in_2025/). The engine and editor he created let him quickly build the kinds of 2D games he wants to make, drawing on 20 years of game-development experience. His game engine is written in C# and uses SDL3, with Dear ImGui powering its custom level editors. He works mostly on Linux and uses Native AOT to cross-compile for platforms that do not support VMs.

The goal of the Soup Raiders native port is not to compete with Unity or Unreal, but to build an engine specifically for this game, following the [game-specific approach Tyler Glaiel describes here](https://x.com/TylerGlaiel/status/1806476966973116539). So now that we know what a custom game engine is, we can try to answer the question of why you would make one.

## Curiosity & Learning

Tyler Glaiel (him again) considers learning how game engines work one of the best reasons to build your own. I started making games by writing my own custom 2D game engine in Python with [Pygame](https://github.com/pygame/pygame). That was in the early 2010s, and Unity was not yet where it is now. For example, here is my first game-jam entry, *[Trials](https://teamkwakwa.itch.io/trials)*:

![Trials](/images/trials.png)

Early in my game-development career, I used Python, Pygame, and Box2D. Later, a colleague from EPFL and I built a C/C++ engine with an embedded Python interpreter that could run my games faster. Finally, for [Super Splash Fisticuffs](/gamedev/2015/04/27/ludum-dare.html) (which became Splash Blast Panic), I switched to Unity 5. Apart from a small [Game Boy game](/gamedev/2016/10/17/soup-raiders-jailbreak-post-mortem-of-gbjam-5-doing-a-real-homebrew-gameboy-rom.html) that I built in C with [GBDK](https://gbdk.sourceforge.net/), I did not return to creating game engines until I began teaching.

But why should you learn to make a custom game engine when Unity and Unreal already exist? In fact, I would argue that making your own game engine teaches you a lot about how Unity or Unreal (or Godot) work. For students who want to enter the game industry, building an engine offers insight into proprietary in-house engines that we cannot access in the classroom. So instead of just learning the Unity way or the Unreal way, building a custom engine lets you explore the range of possible game-engine architectures.

In the computer graphics module at SAE Institute Geneva, games-programming students build a 3D scene with OpenGL. I explain [why I still teach OpenGL instead of a more modern API](/graphics/cpp/2026/01/27/why-i-teach-opengles.html) in a separate post. Through this exercise, they learn the fundamentals of rasterisation-based rendering. For example, when I introduce shadow mapping, I show them an implementation of cascaded shadow maps.

![cascaded shadow map](/images/2026/romulan_cascaded.png)

The three shadow-map cascades appear on the right, while the scene is tinted to show which cascade each pixel uses. Funnily enough, when implementing the first version of Soup Raiders in Unity, I was exploring Unity's rendering settings when I came across this option:

![cascaded unity setting](/images/2026/unity_cascade.png)

Faced with such a setting, I have three options:
1. I don't know what a cascaded shadow map is, so I don't touch anything.
2. I don't know what a cascaded shadow map is, so I search online (or ask an LLM), get a sense of what it is, and then change this setting and try to guess how it impacts my performance.
3. I implemented cascaded shadow mapping in an OpenGL sample by hand, so I know exactly what it means and I choose the correct setting accordingly.

For Soup Raiders, I chose a single shadow map with no cascades and applied filtering while drawing the meshes and sprites (I did not really care about the quality of the shadows far away, as this is not an open-world game). A different game and context require different reasoning—and therefore a different decision.

Another example comes from Beach Slap. While I was optimising the game for mobile (I have an old iPad Air 2 from 2014 for that), profiling showed me that a lot of time was spent on occlusion culling, a technique that discards draw calls for objects hidden behind other objects. It's a very useful technique, for example in games with a lot of geometry that is often hidden. But look at my game:

![beach slap](/images/2026/gamescom26_SS%20(6).jpg)

Because no objects occlude one another, the game does not benefit from occlusion culling. Having implemented the technique for my course, I understand its cost and can confidently disable it.

This experience is not unique. Mathieu Ropert, who worked on Paradox's custom C++ engine, described a consulting job using UE5:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Wrapped up a consulting job on UE5 with no prior engine experience outside hobby interest.<br>Within hours I had significant performance improvements and found architectural design flaws.<br>Making CV hard requirements on specific engines is deeply unserious about software engineering.</p>&mdash; Mathieu Ropert (@MatRopert) <a href="https://x.com/MatRopert/status/2049803204385226827?ref_src=twsrc%5Etfw">April 30, 2026</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

## Independence

At the end of 2024, I went through a **degoogling** phase: I moved most of my files and photos from Google to Proton Drive, cancelled Xbox Game Pass, and left Spotify for Qobuz. I may eventually return to simply buying music or listening on YouTube. Big tech is everywhere, and I still want to get rid of GitHub, Microsoft Windows and Google Calendar, but their convenience is really hard to give up.

Indie developers may be independent from publishers, but they still depend on platform holders (Nintendo, Sony, Microsoft, Valve, Apple) and engine providers (Unity, Unreal, etc.). What about version control—do you push your code to GitHub, which Microsoft owns? Do you share assets through Google Drive? And which operating system do you use? Many game developers use Windows because important tools and middleware either work only there or support it best; others use macOS.

In [*Real Reasons (Not) to Build Custom Game Engines in 2024*](https://www.gamedeveloper.com/programming/real-reasons-not-to-build-custom-game-engines-in-2024), Maxim Kiselev identifies three forms of dependency created by third-party engines.

### Technical

On technical dependency, Kiselev writes:
> If you're using a third-party engine and encounter a bug or missing feature that impacts your game, you often have no choice but to wait for the engine’s developers to fix it.

This dependency exists with both proprietary and open-source engines, although with an open-source engine you can inspect the code and fix problems yourself. In my view, a third-party engine locks developers into a particular way of implementing their game. That is acceptable for most projects but can become restrictive in unusual cases.

Unity's transition from OpenGL and DX11 to Vulkan and DX12 illustrates this problem: its modern rendering hardware interface still had to emulate the older model, limiting its potential performance.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Vulkan and DX12 was initially slower in Unreal/Unity because their RHIs didn&#39;t match the retained mode grouping of Vulkan/DX12. Developers had to add hash maps under the RHI to map dynamic API to retained PSO and descriptor set APIs. Which added complexity and CPU cost a lot.</p>&mdash; Sebastian Aaltonen (@SebAaltonen) <a href="https://x.com/SebAaltonen/status/1880889196363251790?ref_src=twsrc%5Etfw">January 19, 2025</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

Of course, Unity could not simply break RHI compatibility between versions. However, a new custom engine designed specifically around Vulkan or DX12 could outperform Unity at the RHI level by matching those APIs more closely. Sebastian Aaltonen actually made a prototype during Unity Hackweek 2019:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">When I was working at Unity, we did a simple (4 day) prototype at Hackweek 2019 with fully persistent data and descriptor sets. The performance was super good:<a href="https://t.co/NPyXHP3NiM">https://t.co/NPyXHP3NiM</a><br><br>This is how Vulkan was designed to be used. When you try to emulate DX11 the perf sucks.</p>&mdash; Sebastian Aaltonen (@SebAaltonen) <a href="https://x.com/SebAaltonen/status/1532988130290241536?ref_src=twsrc%5Etfw">June 4, 2022</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

With a custom game engine, you have full control over your development process and tech stack.

### Legal Independence

You do not own a third-party engine; you use it under a licence that the provider may revoke if it determines that you have violated its terms of service. It has happened several times to developers using Unity:
- [Improbable/SpatialOS in 2019](https://techcrunch.com/2019/01/11/improbable-urges-unity-to-unsuspend-their-game-engine-license-or-clarify-terms/)
- [A student who got their license revoked the day before releasing their game demo in July 2026](https://www.reddit.com/r/unity/comments/1ur9j7m/was_gonna_launch_my_games_demo_tomorrow_but_am/)
- [Mike Thorn getting his license revoked - March 2024](https://discussions.unity.com/t/my-personal-license-has-been-revoked/942826)
- [License Revoked, Editor Closed, Work Lost - Aug 2023](https://discussions.unity.com/t/license-revoked-editor-closed-work-lost/926284)

Using a free and open-source engine such as Godot avoids this particular risk. It is released under the permissive [MIT licence](https://godotengine.org/license/). Unreal is not open source, but it does ship its full source code, which gives a degree of technical independence that Unity's licence activation system doesn't necessarily provide.

![renderware](/images/2026/RenderWare_(2002).png)

In the PS2 era, Criterion Games created RenderWare, a cross-platform 3D game engine for PC, PlayStation 2, Xbox and GameCube. The big deal was that each of those consoles had a different CPU architecture (PS2 was MIPS, GameCube was PowerPC, Xbox was x86 like the PC). So a game engine that let you target all those platforms was the Unreal Engine of the PS2 generation. It powered many popular games across different studios, including:

- *Grand Theft Auto III* — DMA Design — October 23, 2001
- *Tony Hawk's Pro Skater 3* — Neversoft — October 28, 2001
- *Grand Theft Auto: Vice City* — Rockstar North — October 29, 2002
- *Manhunt* — Rockstar North — November 18, 2003
- *Sonic Heroes* — Sonic Team USA — December 30, 2003
- *Burnout 3: Takedown* — Criterion Games — September 7, 2004
- *Grand Theft Auto: San Andreas* — Rockstar North — October 26, 2004
- *The Warriors* — Rockstar Toronto — October 17, 2005
- *Black* — Criterion Games — February 24, 2006
- *Bully* — Rockstar Vancouver — October 17, 2006

However, after EA acquired Criterion in 2004, RenderWare was gradually withdrawn as commercial middleware and had effectively disappeared from the market by 2007 (see [EA's acquisition of Criterion](https://www.gamespot.com/articles/ea-assimilates-criterion/)). According to [EA's William "Bing" Gordon](https://www.gamedeveloper.com/business/bing-there-done-that-ea-s-cco-talks-everything):
> Renderware didn't get the next-gen parts that we needed.

![the machinery](/images/2026/Our_Machinery.webp)

In July 2021, Our Machinery announced a new game engine, "The Machinery", available by subscription for $50 per year for independent developers and $450 per year for industry professionals. The paid subscriptions included every feature, technical support, and source-code access; a free version was also available without the source code. They also published a [series of blog posts](https://ruby0x1.github.io/machinery_blog_archive/) explaining the engine's development process (the blog goes back to 2017).

However, in August 2022, licensees were abruptly told that development had ended and that they must delete all copies of The Machinery's source code and binaries, [as reported by *NME*](https://www.nme.com/news/gaming-news/the-machinery-game-engine-cancelled-as-developers-told-to-delete-all-source-code-3283633). Ryan Fleury discussed the consequences in [*Ships, Icebergs, Game Engines*](https://www.dgtlgrove.com/p/ships-icebergs-game-engines):
> What becomes of work authored for a project that used The Machinery as its engine? If a game developer is lucky, their investment in The Machinery was kept to a minimum, and their content is largely decoupled from The Machinery technology. That, though, would be a very lucky (or careful) user of The Machinery—what is more likely, for that game developer, is that a hefty majority of the authored content—levels, gameplay code, assets—is, in fact, quite coupled to The Machinery technology, and so the value of that game developer’s content has dropped dramatically close to zero.

![unity](/images/2026/unity_runtimefee.png)

In September 2023, Unity [announced a runtime fee based on game installs](https://discussions.unity.com/t/unity-plan-pricing-and-packaging-updates/927079), scheduled to take effect on January 1, 2024. After an immediate backlash, Unity revised the policy on September 22 with [Marc Whitten's open letter](https://unity.com/blog/an-open-letter-to-our-community) but did not cancel the fee entirely until September 2024, when new CEO Matt Bromberg [announced its cancellation](https://unity.com/blog/unity-is-canceling-the-runtime-fee).

The controversy had a lasting impact on the indie game-development community, prompting many developers to adopt Godot or build their own engines:
* [Kalling Kingdom Engine Port and YouTube Hiatus](https://www.elegacorp.com/blog/kalling-kingdom-engine-port-and-youtube-hiatus.html) — Elega Corporation on leaving Unity after the Runtime Fee controversy and building a proprietary game engine in Rust.
* [Godot Private Asset Library — Transitioning from Unity to Godot](https://spielmannspiel.com/blog/transitioning_from_unity_to_godot) — A developer's experience gradually moving new projects from Unity to Godot following the 2023 announcement.
* [From Unity to Godot: My Journey with “No Escape?!”](https://forum.godotengine.org/t/from-unity-to-godot-my-journey-with-my-no-escape-game-and-open-source-projects/126568) — A developer recounts rebuilding an existing Unity game from scratch in Godot 4.
* [Scrapyard Jam](https://itch.io/jam/scrapyard-jam) — A game jam created in the aftermath of Unity's pricing controversy, encouraging developers to build their own engines or experiment with alternatives.

One possible consequence was visible in 2026, when Godot became the most-used engine among submissions to the Game Maker's Toolkit Game Jam:

<blockquote class="bluesky-embed" data-bluesky-uri="at://did:plc:uwucgubhwifmvz4kcpuzjaxf/app.bsky.feed.post/3mrmx5mi3mk24" data-bluesky-cid="bafyreiepprqcjplsxbvrrqkvycr2geat2rq4i3lds4kjccmoyf7ojlttle" data-bluesky-embed-color-mode="system"><p lang="en">Well, it finally happened! After 9 years of Unity dominance, Godot was the most used game engine for GMTK Game Jam 2026 submissions. 

🤖 Godot - 47%
🎮 Unity - 34%
🛠️GameMaker - 5%
🚀 Unreal Engine - 3%
✨ Other - 11%<br><br><a href="https://bsky.app/profile/did:plc:uwucgubhwifmvz4kcpuzjaxf/post/3mrmx5mi3mk24?ref_src=embed">[image or embed]</a></p>&mdash; Game Maker&#x27;s Toolkit (<a href="https://bsky.app/profile/did:plc:uwucgubhwifmvz4kcpuzjaxf?ref_src=embed">@gamemakerstoolkit.com</a>) <a href="https://bsky.app/profile/did:plc:uwucgubhwifmvz4kcpuzjaxf/post/3mrmx5mi3mk24?ref_src=embed">July 27, 2026 at 2:58 PM</a></blockquote><script async src="https://embed.bsky.app/static/embed.js" charset="utf-8"></script>



### Financial Independence

I remember a talk by Rami Ismail at Reboot Develop 2017 where he spoke about this triangle:

![Motivation, money and knowledge triangle](/images/2026/sr/motivation_money_knowledge.svg)

His point was that motivation is the most important of the three, because:
- Motivation + Knowledge + No Money = You can work part-time on your game
- Motivation + Money + No Knowledge = You can pay people to make your game
- Money + Knowledge + No Motivation = You do not make a game at all.

In [*So, You Want to Make a Game Engine*](https://lisyarus.github.io/blog/posts/so-you-want-to-make-a-game-engine.html), Nikita Lisitsa writes:
> Why not make your own game engine? [...] You might find yourself too deep into engine development instead of making an actual game, which can easily lead to a burnout.

This brings us back to the students mentioned earlier who want to build an engine for their ambitious MMO. His warning is simple:
> It is hard and time-consuming.

But imagine that we have plenty of motivation (or a well-scoped game engine) and the necessary knowledge (or the willingness to learn). If we have no money at all—or no willingness to give away a single penny when the game eventually comes out—then making a custom game engine could be financially better than using a third-party engine. Tyler Glaiel offers a more cautious view of whether building your own engine saves money:
> You most likely won’t (save money). Making an engine takes time, and time=money. [...] Using your own engine won’t make you sell more copies of your game automatically. And while you *can* save time in the long run, this usually means having your engine be good enough to carry you across multiple projects, while also providing you with significant workflow improvements compared to commercial engines. It’s not easy to get this right, and you definitely won’t if its your first try at it (and extremely unlikely if you’re doing 3D instead of 2D).

For context, the following prices are an August 2026 snapshot; pricing and licensing terms may change.

- **Unity:** Free with Unity Personal for up to **US$200,000** in gross revenue and/or funding over the previous 12 months. From **US$200,001 to US$24,999,999**, Unity Pro is mandatory and costs **US$2,310/year/seat** or **US$210/month/seat**. At **US$25M or more**, Unity Enterprise with custom pricing is mandatory. There is no revenue share or royalty. ([Unity][1])
- **Unreal Engine 5:** Free until a game earns **US$1M in lifetime gross revenue**, then Epic charges a **5% royalty**. Revenue earned through the Epic Games Store is royalty-free. ([Unreal Engine][2])
- **GameMaker:** Free for non-commercial use and a **US$99.99 one-time fee** for commercial games. Console exports require Enterprise, which costs **US$79.99/month** or **US$799.99/year**. ([GameMaker][3])
- **CRYENGINE:** Free upfront, with a **5% royalty** after the first **US$5,000/year/project**. Full source code is included. ([CRYENGINE][4])
- **Godot:** Completely free under the MIT license, with no royalties, subscriptions, or revenue limits. ([Godot Engine][5])

[1]: https://unity.com/products/pricing-updates "Unity pricing changes"
[2]: https://www.unrealengine.com/license "Unreal Engine (UE5) licensing options - Unreal Engine"
[3]: https://gamemaker.io/en/help/articles/november-2023-pricing-terms-change-faq "November 2023 Pricing/Terms Change FAQ"
[4]: https://www.cryengine.com/support/view/licensing?utm_source=chatgpt.com "CRYENGINE | Support: Licensing"
[5]: https://godotengine.org/license/ "License – Godot Engine"

One note from Maxim to finish this section (taking into account that time is money):

> It’s easy to think that building your own engine will save time and money, but that’s rarely the case. To develop a game using an engine like Unity or Unreal Engine 5, you need to invest time learning them. While this can take a while, it's still a much smaller time investment compared to building your own engine from scratch and learning the underlying technology needed for it.

## Low-Level Control

[*The Handmade Manifesto*](https://handmade.network/manifesto) argues that programmers should understand how computers and their technology stacks work instead of relying on layers of opaque frameworks and dependencies. One of its stated values is "We like to reinvent the wheel." In a way, creating a custom engine means reimplementing solutions to problems that have already been solved, but tailoring them to the specific needs of our games.

Building some low-level systems yourself does not mean rebuilding everything from scratch. [Noel Berry](https://noelberry.ca/posts/making_games_in_2025/) delegates platform, input, and rendering work to SDL3 and uses FMOD for audio. Nikita also recommends using libraries like SDL, GLFW, SFML or OpenAL.

In their [Reddit AMA](https://www.reddit.com/r/factorio/comments/in5d3i/developer_technicaloriented_ama/), the Factorio developers argued that standard engines were unsuitable for their game logic:
> 'standard engines' are so restrictive in what can be done and leave so much performance sitting there that I wouldn't ever consider using one for something like Factorio. 

A custom engine can also dramatically affect compilation times and build sizes. Developers using Unreal or Unity—particularly IL2CPP builds—may be familiar with these problems:
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">We upgraded a project from Unity 2022.3 to 6.3 and Unity is still the slow , cluncky thing it was before. The builds are as slow. compiling IL2CPP takes 1.5 hours on the machien that compiles UE5 source in 40 mins. It is hard to go back to Unity.</p>&mdash; Ashkan Saeidi Mazdeh (@Ashkan_GC) <a href="https://x.com/Ashkan_GC/status/2019446029175693724?ref_src=twsrc%5Etfw">February 5, 2026</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

The problem became so severe that I dedicated a separate computer to building Beach Slap for every platform at the end of each development day, using a single `.bat` script.

Dan Baker argues that owning a custom engine can also reduce compilation times:
> For example, our Nitrous Engine compiles very quickly. The engine compiles in less than 30 seconds. The engine code is clean and modular, so we can implement features in the engine or fix a bug in around a tenth of the time it would take in an off-the-shelf engine. Not only can we do a clean build of Ara in less than 2 minutes, but our debug version of the Ara and Nitrous is so fast that we can still run at 30 fps in full debug.

Sébastien de Graffenried's custom engine also produces tiny builds compared with default Unity or Unreal builds:
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">A nice thing about using your own C engine are the small build sizes.<br>And I didn&#39;t even try that hard to reduce the size! <a href="https://t.co/d85Po9ztUU">https://t.co/d85Po9ztUU</a> <a href="https://t.co/OO2QncB2lk">pic.twitter.com/OO2QncB2lk</a></p>&mdash; Sébastien de Graffenried (@seb_degraff) <a href="https://x.com/seb_degraff/status/1889649086560600088?ref_src=twsrc%5Etfw">February 12, 2025</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

Jonathan Blow also demonstrates the fast compilation times achieved by the compiler for his own programming language:
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">I did some work on the compiler that had the side effect of speeding things up! Here are the current compile speeds on my desktop.<br><br>Current compiler size: 55,273 lines. <a href="https://t.co/HmYKzZ3z3q">pic.twitter.com/HmYKzZ3z3q</a></p>&mdash; Jonathan Blow (@Jonathan_Blow) <a href="https://x.com/Jonathan_Blow/status/1353939518588502018?ref_src=twsrc%5Etfw">January 26, 2021</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

These three examples show that custom game engines can improve not only your game's performance but also the performance of your workflow. As Tyler Glaiel puts it:
> it’s nice to just have your own tech, [...]. It’s nice to be able to actually debug the internals of your game if something goes wrong. 

However, he also warns of the risks:
> But it can also suck if you made a couple of bad design choices and everything falls apart entirely, and there’s no resources online to help you. You have full control and full responsibility, and all the pros and cons that come with that.

A custom engine can improve performance and workflow, but poor design choices can still leave you with a C++ project that takes ages to compile. Optimising its compilation times is then your responsibility.

## Unique Game Mechanics

Unique or innovative game ideas sometimes require custom technology and the freedom that a custom engine provides. Although general-purpose engines can often support such ideas, working around their constraints may be difficult. For example, in Unity's GameObject model, creating many objects with separate `MonoBehaviour` scripts can make the overhead of their `Update()` calls prohibitively expensive. A common workaround is to use a single manager `MonoBehaviour` to control all those entities. Unity's DOTS architecture addresses this limitation, although it introduces a different set of trade-offs.


Glaiel uses *Noita* as an example:
> A great example of a justified use of a custom game engine is the well-known Noita. The game has a truly unique concept that likely wouldn’t have worked with any existing proprietary engine, a uniqueness captured in the name of its engine, "Falling Everything." Yet, Noita doesn’t rely on advanced graphical effects, it’s single-player, and it was built exclusively for one platform — PC.

![noita](/images/2026/noita-feel-alive.jpg)

*Noita* is a roguelite by Nolla Games in which every pixel is simulated. In his [GDC talk](https://www.gdcvault.com/play/1025695/Exploring-the-Tech-and-Design), Petri Purho explains that the physics system began with experiments in QuickBASIC: each pixel checked whether there was empty space beneath it and fell accordingly. He developed the system further in *Bloody Zombies*, eventually adding rigid bodies. *Noita* then grew out of this existing C++ physics engine.

![Miegakure](/images/2026/Miegakure.png)

For *Miegakure*, an unusual 4D puzzle game, Marc ten Bosch had to reimplement many fundamental systems. As he explained to [*Vice*](https://www.vice.com/en/article/what-happened-to-miegakure-the-game-that-promised-the-4th-dimension/):
> People have very much figured out how to build 2D and 3D games: proof of that is that game engines like Unity exist.In 4D, none of that knowledge exists, and it is more difficult to come up with because you can’t fully visualize it and the math is more complicated. So anything a game developer would take for granted in a 3D game—like collision detection, lighting, sound, modeling props—is a new, difficult problem that has to be figured out. It takes a long time to solve these issues, but it is also extremely fun for me!

![teardown](/images/2026/teardown.webp)
Similarly, Dennis Gustafsson [explained](https://www.gamedeveloper.com/design/combining-bombastic-heists-with-a-fully-destructible-voxel-world-in-i-teardown-i-) that *Teardown* grew out of his experiments with voxel and destruction technology:
> The engine and tool pipeline are created from scratch in C++ for this game specifically, [...], but since the game relies on novel technology I don't think it would have been possible using an off-the-shelf engine.

## Specialisation

Tyler Glaiel lists "I can do better" (than other game engines) as a bad reason for making a game engine. In his own words:
> You think you can just make something better than Unity or Unreal (or Godot or GameMaker) in general. You can’t. It’s possible to make something that is better than these for specific use cases [...], but you, as an individual or a tiny team, are not going to compete with these for general purpose stuff.

For a custom engine to make sense, it must be specialised for the game, its artistic direction, or the platform's technical constraints.

Because Noel Berry's artist uses [Aseprite](https://www.aseprite.org/), he added direct support for its file format to the engine. He also builds level editors tailored to each game and the team's workflow. He can do that because he does not need most of the features of a generic-purpose game engine.

![animal well](/images/2026/Animal_Well.jpg)

According to [Sam Machkovech's article on *Animal Well*](https://www.gamedeveloper.com/design/why-animal-well-s-home-brewed-engine-was-key-to-its-success), Billy Basso built a custom engine partly because his experience with bloated, sluggish off-the-shelf engines in mobile development had left a "sour taste." His engine allowed him to combine a rim-lighting shader, which highlights silhouettes in otherwise dark scenes, with a full-screen Navier–Stokes simulation for smoke and water. Basso recommends an engine-first approach to game development:
> [...] That opens up a lot of unique creative avenues. Once I get a cool system working, then I can play around with it and see what it allows for.

Nikita makes the point that a custom game engine does not necessarily need complex material graphs, global illumination, advanced 3D physics, multiplayer infrastructure or industrial-scale editor tooling. For Glaiel, specialisation is almost a requirement for a custom engine. He adds that:
> [...] you can make your asset pipeline / level editor / whatever way smoother to use when considering your specific use cases instead of needing it to be general purpose.

This is one of the central ideas in [Andreas Fredriksson's *Context Is Everything*](https://vimeo.com/644068002) talk at Handmade Seattle 2021: once you understand your specific context, a custom engine's low-level control lets you optimise as deeply as necessary.

Specialisation can also provide long-term benefits: a custom engine may support the next game or even an entire series. This was the case for the [RED Engine of CD Projekt Red](https://witcher-games.fandom.com/wiki/REDengine):
- (2007) Aurora Engine: CDPR licensed and heavily modified BioWare’s engine to create The Witcher.
- (2011) REDengine 1: CDPR introduced its own proprietary engine with The Witcher 2.
- (2012) REDengine 2: The engine evolved to support consoles and multiplatform development.
- (2015) REDengine 3: REDengine was redesigned for the large open world of The Witcher 3.
- (2020) REDengine 4: The engine evolved again for the dense urban world of Cyberpunk 2077.
- (2023) REDengine 4: Phantom Liberty became the final major release built with REDengine.

CD Projekt Red has since switched to Unreal Engine for *The Witcher IV*, but the evolution of REDengine still shows how a custom engine's foundations can support several generations of games.

## Multiplatform

When releasing a game on multiple platforms, Unity feels like magic. Even if the result is not perfectly optimised, porting a Unity game to a console can take far less time than implementing the port by hand in a custom engine, especially when the platform is unfamiliar. Nikita describes the cost of multiplatform support in a custom engine:
> Supporting multiple platforms adds more pain, since different platforms have different executable file formats, dynamic library formats, etc. You'll have to compile several different versions of your game, one for each platform.

Compare that with the "time to triangle"—the time required to render an engine's first triangle on a console—that [Mark Cerny discussed for several PlayStation generations at Gamelab 2013](https://www.youtube.com/watch?v=xHXrBnipHyA):

| Platform          | “Time to triangle” |
| ----------------- | -----------------: |
| PlayStation       |     **1-2 months** |
| PlayStation 2     |     **3-6 months** |
| **PlayStation 3** |    **6-12 months** |
| PlayStation 4     |     **1-2 months** |

Custom engines have a clearer advantage on niche and retro platforms. At the time of writing, Unity 6.4 officially supports these consoles:

- PlayStation 4 (including PlayStation VR)
- PlayStation 5 (including PlayStation VR2)
- Xbox One
- Xbox Series X
- Xbox Series S
- Nintendo Switch
- Nintendo Switch 2

These are all recent console generations. Targeting older or more unusual hardware often requires a custom engine or specialised tooling. On the [Playdate](https://play.date/), you are required to program in C or Lua with its SDK. The [Arduboy](https://www.arduboy.com/) similarly uses C++ through the Arduino ecosystem, under severe hardware constraints.

For GBJam 2016, I made a Game Boy game in C using GBDK, a process I described in [a separate post](/gamedev/2016/10/17/soup-raiders-jailbreak-post-mortem-of-gbjam-5-doing-a-real-homebrew-gameboy-rom.html). [GB Studio](https://www.gbstudio.dev/) did not exist at the time, so I had to endure the painful process of programming for a system without a debugger (the screen would just be blank at boot when there was a problem).

Similarly, Elias Daler is developing a PS1 game with his own custom engine:
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">I started making stuff for PS1 exactly one year ago.<br><br>It&#39;s been a wild journey since then. I&#39;m thinking of writing a big article about it (and later a video, maybe).<br><br>And this is just the beginning of my PS1 journey! <br>Now that I have a pretty good engine, I can make a real game. <a href="https://t.co/fA1cWJfNlp">pic.twitter.com/fA1cWJfNlp</a></p>&mdash; Elias Daler (@EliasDaler) <a href="https://x.com/EliasDaler/status/1948300981130727607?ref_src=twsrc%5Etfw">July 24, 2025</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

Commercial engines must follow current technology and console generations, whereas custom engines can continue targeting whichever platforms their developers choose.

## Modding

On file management, Tyler writes:
> You might want to be able to build mod support or dynamic loading/unloading or whatever off of this, as long as you have the basics here and only ever load files through the file manager, you can easily add whatever other functionality you want into this later.

But what can we load and allow the players to change?

![civ4 mods](/images/2026/civ_iv.jpg)

One of the defining games of my teenage years was *Civilization IV*, whose unusually moddable, data-driven architecture was discussed in the [August 2005 issue of *Game Developer*](https://media.gdcvault.com/GD_Mag_Archives/GDM_August_2005.pdf). It features four tiers of moddability:

- **In-game WorldBuilder:** An in-game map editor for customising terrain and placing units, cities, buildings, and resources.
- **XML/data modification:** All game variables, text, asset paths, and rules were stored in standard XML files.
- **Python scripting:** High-level game functionality was exposed to Python, allowing scripts to generate maps, modify the interface, trigger game events, and override AI.
- **C++ GameCore DLL SDK:** Users could modify, replace, or extend the low-level C++ code that runs the game.

While researching this post, I discovered [*Realism Invictus*](https://www.moddb.com/mods/realism-invictus/news/realism-invictus-38-released-20-year-anniversary-of-realism-invictus), a total-overhaul mod that has remained in development for more than 20 years. It adds over 130 technologies, entire families of distinct units, more than 160 leaders, and 21 additional civics, making it feel almost like *Civilization IV 2.0*. All this is possible because the game developers spent a lot of time making the game (and thus the engine) moddable.

![arma 3](/images/2026/arma3.jpg)

Bohemia Interactive's *ARMA III* offers another example. In his talk [THE PANDORA'S BOX OF MODDING IN 'ARMA' GAMES](https://gdcvault.com/play/1027043/The-Pandora-s-Box-of), Karel Mořický describes three relationships between games and mods:

- **Standard game:** Players cannot modify it, so the code's internal mess remains hidden.
- **Improvised modding:** Determined players modify the game without official support, often producing messy or unstable results.
- **Moddable game:** The developer provides an API so mods can add content. At this point, the product becomes a platform.

I find it fascinating that *ARMA* supports multiple simultaneous mods, dependencies between mods, patch mods that override existing content, and multiplayer-specific server and client mods. At the time of the talk, the community had created 70,174 mods. The game exposes its editors directly through the main menu, and modders can use a development branch alongside the main release to prepare their mods for upcoming updates.

![minecraft mods](/images/2026/minecraft_mod.jpg)

By contrast, the *Minecraft: Java Edition* modding ecosystem grew largely without an official engine-level API from Mojang. Early modders simply decompiled the game and replaced or modified classes directly inside `minecraft.jar`. Over time, different communities built shared modding layers. Today, the main ecosystems include Fabric, Forge, NeoForge, and Quilt, alongside server platforms such as Paper and its derivatives. Updates to *Minecraft: Java Edition* have often been painful for modders. Version 1.13 introduced substantial internal changes, making large mods difficult to port and forcing even Forge itself to undergo a major redesign.

Interestingly, *Minecraft: Bedrock Edition* experimented with a [JavaScript API](https://www.minecraft.net/en-us/article/scripting-api-now-public-beta) in 2018. Its modern [Script API](https://learn.microsoft.com/en-us/minecraft/creator/documents/scripting/introduction?view=minecraft-bedrock-stable) still uses JavaScript or TypeScript, while [Molang](https://learn.microsoft.com/en-us/minecraft/creator/documents/molang/introduction?view=minecraft-bedrock-stable) serves as a separate expression language embedded in add-on JSON files.

![factorio](/images/2026/factorio.jpg)

[*Factorio* mods](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html) can run Lua code both during startup and while a map is being played. Because *Factorio* supports deterministic multiplayer, its developers found that even iterating over a Lua hash table could make a mod nondeterministic and cause [desynchronisation](https://www.factorio.com/blog/post/fff-70). Mods can also crash. Initially, *Factorio* presented mod failures in the same way as game crashes, but the developers later [added clearer error reporting](https://www.factorio.com/blog/post/fff-178) that identified the responsible mod. One of *Factorio 2.0*'s most significant modding changes was to treat the game itself as a mod, shipping first-party components through the same dependency infrastructure.

For *Beach Slap*, we designed the level editor as an in-game tool from the start so that we could share it with players. Levels are stored as JSON files, making them easy to save locally, upload, and download. I do not, however, plan to support modding in the native version of *Soup Raiders*.

## Conclusion

This post grew far beyond my original idea, but I wanted to set out my thoughts on building a custom engine before delving into the technology itself. Building an engine takes time, but it gives us control over how the game loads and updates, removes engine-licence fees, and teaches us about asset compilation, rendering, and optimisation. We can even expose parts of the engine to players, allowing them to improve the game or create mods—and potentially entirely new games—with our technology. After Unity's runtime-fee announcement, technological independence became an even more important concern for game developers.

The rest of this series will explore the implementation of the *Soup Raiders* native port and how it targets 60 Hz on Nintendo Switch with loading times below three seconds. One final principle comes from [Ted Bendixson's Better Software Conference 2025 talk](https://www.youtube.com/watch?v=Ca53JTohdN4): build an actual game with your custom engine, not merely an impressive technical demo. Tyler Glaiel expresses the same principle more forcefully:

> **Make a game at the same time as you’re making the engine.** This is an unbreakable rule. The only unbreakable rule. Get the basics in as fast as you possibly can and then immediately start making a game on top of it. An engine is nothing without a game.

I will leave you with one final thought on building a game engine with the help of LLMs:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Now is the perfect time to write your own engine. The argument in the past was that you don&#39;t have time to write all the less important generic features. Now, the LLM will do that for you. You can focus on things that differentiate your product. <a href="https://t.co/ydEaaZOx12">https://t.co/ydEaaZOx12</a></p>&mdash; Sebastian Aaltonen (@SebAaltonen) <a href="https://x.com/SebAaltonen/status/2033460617282031835?ref_src=twsrc%5Etfw">March 16, 2026</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

## References
- [Noel Berry's Making Video Games in 2025 (without an engine)](https://noelberry.ca/posts/making_games_in_2025/)
- [Rez Graham's Independent Games Summit: A Case for Making Your Own Engine](https://www.gdcvault.com/play/1034506/Independent-Games-Summit-A-Case)
- [Maxim Kiselev's Real reasons (not) to build custom game engines in 2024](https://www.gamedeveloper.com/programming/real-reasons-not-to-build-custom-game-engines-in-2024)
- [raysan5's CUSTOM GAME ENGINES: A Small Study](https://gist.github.com/raysan5/909dc6cf33ed40223eb0dfe625c0de74)
- [Angelo "Encelo" Theodorou's nCine: a world with custom in-house engines is possible](https://encelo.github.io/CustomEnginesPresentation/#1)
- [Handmade Network's The Handmade Manifesto](https://handmade.network/manifesto)
- [Dan Baker's A case for building your own tech](https://www.gamesindustry.biz/a-case-for-building-your-own-tech-opinion)
- [Yuri Karabatov's Make your game, not an engine](https://norikitech.com/posts/make-your-game/)
- [Tyler Glaiel's How to make your own game engine (and why)](https://medium.com/geekculture/how-to-make-your-own-game-engine-and-why-ddf0acbc5f3)
- [Nikita Lisitsa's So, you want to make a game engine](https://lisyarus.github.io/blog/posts/so-you-want-to-make-a-game-engine.html)
