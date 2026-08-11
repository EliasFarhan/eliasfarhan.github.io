---
layout: post
title:  "Soup Raiders Goes Native (1/?): What You Gain by Building Your Own Game Engine"
categories: [gamedev, cpp]
series: soupraiders-native
---

![](/images/2026/game_engine_share_release.png)

According to VGInsights, about 10% of games released on Steam in 2024 used a custom engine, while back in 2012 it was 71%! So looking at this trend, why should anybody try to make their own game engine?

<!--more-->

But... 

![](/images/2026/game_engine_share_sold.png)

Those games still represent 41% of units sold in 2024 and, even if those are mostly AAA game engines, it means that making your own game engine can still make sense business-wise. So this blog post is about why you should make a game engine.

However, before answering this question, we need to define what a game engine is, because even Anthropic thinks Claude Code is a custom game engine:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Most people&#39;s mental model of Claude Code is that &quot;it&#39;s just a TUI&quot; but it should really be closer to &quot;a small game engine&quot;.<br><br>For each frame our pipeline constructs a scene graph with React then<br>-&gt; layouts elements<br>-&gt; rasterizes them to a 2d screen<br>-&gt; diffs that against the…</p>&mdash; Thariq (@trq212) <a href="https://x.com/trq212/status/2014051501786931427?ref_src=twsrc%5Etfw">January 21, 2026</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

## What's a game engine and what do we mean by custom?

A game engine is a reusable software framework that lets you create and run a computer game. It sits between the actual game code (gameplay logic) and the operating system (Windows, SteamOS, Android):

![](/images/2026/game_engine_stack.svg)

In this position, the game engine's role is to make sure that the game loop keeps running by interacting with the OS accordingly. This game loop runs as follows:

![](/images/2026/game_loop.svg)

- **Event Polling**: window resizing, keyboard/mouse/controller input changes, exiting the game, ...  
- **Gameplay**: physics, calling the gameplay code
- **Rendering**: generating the commands to be sent to the GPU to then present the new images on the screen.

But that's not all a game engine is supposed to do: it also needs to load all the assets that the game needs (3d models, animations, sprites, music and sounds), and none of this is implementing the specifics of the actual game. We will go into more detail in the next blog posts about each part and how it is implemented in Soup Raiders Native.

So it's no wonder that at the beginning of any project, the question of developing our own game engine comes up. The goal of commercial game engines like Unreal or Unity is to sell you the game engine so that you only have to focus on making your game, whereas making a custom game engine means implementing that part by hand, or at least gluing frameworks and libraries together to do this under-the-hood engineering yourself. Here are some examples:

- I use Unity, but I develop a lot of internal tools <- **not** a custom game engine.
- I use SDL3 + assimp to make a 3d game <- this is a custom game engine.
- I use Unreal, but I rewrote the renderer <- **not** a custom game engine.
- I use SFML to make a simple 2d networking game <- this is a custom game engine.
- I use Godot and extended it with C++ <- **not** a custom game engine.
- I handwrote from scratch the renderer in DX12 and I open a window with the Windows API <- this is a custom game engine.


So now it's worth looking at a list of games that have a custom game engine. I still remember "Indie Game: The Movie", where all the games shown in the documentary were made with custom engines as well. But there are also all these very successful games:

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


But of course, this does not mean that every successful indie game has its own custom game engine. Unity took a big market share in mobile game development as well as in indie games. For example, here is a list of games made with Unity:

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


But we still have this "Make a game or make a game engine" (or ["Make your game, not an engine"](https://norikitech.com/posts/make-your-game/) by Yuri Karabatov) statement that we throw in the faces of computer science students who dream of creating their MMO before they have even finished their bachelor's degree. Because, as Tyler Glaiel puts it (in this blog post [here](https://medium.com/geekculture/how-to-make-your-own-game-engine-and-why-ddf0acbc5f3)):
> You think you can just make something better than Unity or Unreal (or Godot or GameMaker) in general. You can’t. It’s possible to make something that is better than these for specific use cases [...], but you, as an individual or a tiny team, are not going to compete with these for general purpose stuff. Especially if you have never made your own game engine before.

I really like the approach of Noel Berry (described in this blog post [here](https://noelberry.ca/posts/making_games_in_2025/)). The engine and editor that he created let him quickly build the 2d games he wants to make, and he puts 20 years of making games to work towards this specific goal. His game engine is written in C#, uses SDL3 and DearImGui for the custom level editors; he works mostly on Linux and uses Native-AOT to cross-compile for platforms that don't like VMs.

Our goal with this Soup Raiders Native Port is not to make Unity or Unreal, but to make a game engine that supports this specific game (exactly what Tyler Glaiel tweeted about [here](https://x.com/TylerGlaiel/status/1806476966973116539)). So now that we know what a custom game engine is, we can try to answer the question of why you would make one.

## Curiosity & Learning

Tyler Glaiel (him again) describes creating your own game engine to learn how it works as one of the best reasons to make one. I started making games by writing my own custom 2d game engine in Python with [pygame](https://github.com/pygame/pygame). That was in the early 2010s, and Unity was not yet where it is now. For example, my first game jam game, "[Trials](https://teamkwakwa.itch.io/trials)":

![Trials](/images/trials.png)

Early in my game development career, I started with Python and Pygame using box2d, and then, with a colleague from EPFL, we built a C/C++ game engine embedding a Python interpreter that could run my games faster. Finally, for [Super Splash Fisticuffs](/gamedev/2015/04/27/ludum-dare.html) (which became Splash Blast Panic), I switched to Unity 5. It was only through my teaching that I went back to creating C++ game engines, except for the small [Game Boy game](/gamedev/2016/10/17/soup-raiders-jailbreak-post-mortem-of-gbjam-5-doing-a-real-homebrew-gameboy-rom.html) that I implemented in C with [GBDK](https://gbdk.sourceforge.net/).

But why should you learn to make a custom game engine when Unity and Unreal already exist? In fact, I would argue that making your own game engine teaches you a lot about how Unity or Unreal (or Godot) work. For my students who want to work in the game industry, it can be a way to understand how proprietary game engines work, because, as a teacher, I don't have access to them. So instead of just learning the Unity way or the Unreal way, creating a custom game engine gives you the opportunity to explore the possibility space of game engine architecture choices.

In the computer graphics module at SAE Institute Geneva, the games programming students have to make a 3d scene using OpenGL ([here](/graphics/cpp/2026/01/27/why-i-teach-opengles.html) is a blog post on why I still use OpenGL instead of a more modern API). Throughout this process, they learn all the basics of how a rasterizing renderer works. For example, when I introduce shadow mapping, I show them an implementation of cascaded shadow maps.

![cascaded shadow map](/images/2026/romulan_cascaded.png)

You can see on the right side the three cascades of shadow maps, and in the scene the tint colors showing which pixel is using which cascade. Funnily enough, when implementing the first version of Soup Raiders in Unity, I was trying to optimize the rendering in the Unity settings and I landed on this option:

![cascaded unity setting](/images/2026/unity_cascade.png)

In those situations, there are different options:
1. I don't know what a cascaded shadow map is, so I don't touch anything.
2. I don't know what a cascaded shadow map is, so I search online (or ask an LLM), I get a sense of what it is, and then I change this setting and try to guess how it impacts my performance.
3. I implemented cascaded shadow mapping in an OpenGL sample by hand, so I know exactly what it means and I choose the correct setting accordingly.

The answer for Soup Raiders was to have only one shadow map (so no cascade) and to do some filtering when drawing the meshes and sprites (I did not really care about the quality of the shadows far away, as this is not an open-world game). Different game, different context, different reasoning, so different decision.

Another example comes from Beach Slap. While I was optimising the game for mobile (I have an old iPad Air 2 from 2014 for that), profiling showed me that a lot of time was spent on Occlusion Culling, a technique that discards draw calls for objects hidden behind other objects. It's a very useful technique, for example in games with a lot of geometry that is often hidden. But look at my game:

![beach slap](/images/2026/gamescom26_SS%20(6).jpg)

No object is hidden behind another one, which means that I don't need Occlusion Culling at all. Again, because I implemented Occlusion Culling for my course, I have an idea of its cost and I know for sure that I don't need it.

In conclusion, I am not the only one saying this. Mathieu Ropert, who worked at Paradox on their custom game engine in C++, has this to say about a gig:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Wrapped up a consulting job on UE5 with no prior engine experience outside hobby interest.<br>Within hours I had significant performance improvements and found architectural design flaws.<br>Making CV hard requirements on specific engines is deeply unserious about software engineering.</p>&mdash; Mathieu Ropert (@MatRopert) <a href="https://x.com/MatRopert/status/2049803204385226827?ref_src=twsrc%5Etfw">April 30, 2026</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

## Independence

I went through a **degoogling** phase at the end of 2024: I moved most of my Google Drive and Google Photos to Proton Drive, cancelled my Xbox Game Pass subscription (I was not playing that much anyway) and cancelled my Spotify account (I moved to Qobuz for a year, but I might simply go back to buying the music I like or listening to it on YouTube). Big tech is everywhere, and I still want to get rid of GitHub, Microsoft Windows and Google Calendar, but their convenience is really hard to give up.

The **indie** in indie game developer means independent from publishers, but what about platform holders (Nintendo, Sony, Microsoft, Valve, Apple) or engine providers (Unity, Unreal, etc.)? What about version control: do you push your code to GitHub (which is Microsoft)? And for sharing asset files, do you use Google Drive? What about your OS? Most gamedevs are on Windows because most middleware only works there, and some developers are on macOS.

As Maxim Kiselev points out in his article [here](https://www.gamedeveloper.com/programming/real-reasons-not-to-build-custom-game-engines-in-2024), when using a third-party engine, we have three dependencies.

### Technical

For the technical dependency, according to Maxim in the same article:
> If you're using a third-party engine and encounter a bug or missing feature that impacts your game, you often have no choice but to wait for the engine’s developers to fix it.

It is the same regardless of whether the third-party engine is a big proprietary closed-source engine or an open-source one (at least you can read and fix the open one). For me, using a third-party engine means locking yourself into one way of implementing the game, which is fine in most cases but can be detrimental in specific ones.

It reminds me of Unity's transition from OpenGL/DX11 to Vulkan/DX12, where the modern RHI (rendering hardware interface) still had to emulate the old one, which meant it was much slower than it could have been.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Vulkan and DX12 was initially slower in Unreal/Unity because their RHIs didn&#39;t match the retained mode grouping of Vulkan/DX12. Developers had to add hash maps under the RHI to map dynamic API to retained PSO and descriptor set APIs. Which added complexity and CPU cost a lot.</p>&mdash; Sebastian Aaltonen (@SebAaltonen) <a href="https://x.com/SebAaltonen/status/1880889196363251790?ref_src=twsrc%5Etfw">January 19, 2025</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

Of course, Unity could not just break their RHI from one version to another, but it also means that a new custom engine built on Vulkan/DX12 could easily beat Unity in terms of RHI performance, by having one that matched those new APIs. Sebastian Aaltonen actually made a prototype during Unity Hackweek 2019:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">When I was working at Unity, we did a simple (4 day) prototype at Hackweek 2019 with fully persistent data and descriptor sets. The performance was super good:<a href="https://t.co/NPyXHP3NiM">https://t.co/NPyXHP3NiM</a><br><br>This is how Vulkan was designed to be used. When you try to emulate DX11 the perf sucks.</p>&mdash; Sebastian Aaltonen (@SebAaltonen) <a href="https://x.com/SebAaltonen/status/1532988130290241536?ref_src=twsrc%5Etfw">June 4, 2022</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

With a custom game engine, you have full control over your development process and tech stack.

### Legal independence

You don't own your third-party engine. You just have a license with the company that allows you to use it, which also means that they can take it away whenever they consider that you violated their Terms of Service. It has happened several times to developers using Unity:
- [Improbable/SpatialOS in 2019](https://techcrunch.com/2019/01/11/improbable-urges-unity-to-unsuspend-their-game-engine-license-or-clarify-terms/)
- [A student who got their license revoked the day before releasing their game demo in July 2026](https://www.reddit.com/r/unity/comments/1ur9j7m/was_gonna_launch_my_games_demo_tomorrow_but_am/)
- [Mike Thorn getting his license revoked - March 2024](https://discussions.unity.com/t/my-personal-license-has-been-revoked/942826)
- [License Revoked, Editor Closed, Work Lost - Aug 2023](https://discussions.unity.com/t/license-revoked-editor-closed-work-lost/926284)

Switching to a free and open-source engine like Godot solves this problem. It is released under the permissive [MIT license](https://godotengine.org/license/). Unreal is not open source, but it does ship its full source code, which gives a degree of technical independence that Unity's license activation system doesn't necessarily provide.

![renderware](/images/2026/RenderWare_(2002).png)

In the PS2 era, Criterion Games created RenderWare, a cross-platform 3D game engine for PC, PlayStation 2, Xbox and GameCube. The big deal was that each of those consoles had a different CPU architecture (PS2 was MIPS, GameCube was PowerPC, Xbox was x86 like PC). So a game engine that let you target all those platforms was the Unreal Engine of the PS2 generation. It powered many popular games across different studios, including:

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

However, after EA acquired Criterion in 2004, RenderWare was gradually withdrawn as commercial middleware and had effectively disappeared from the market by 2007 (see [EA's acquisition of Criterion](https://www.gamespot.com/articles/ea-assimilates-criterion/)). According to [William "Bing" Gordon from EA](https://www.gamedeveloper.com/business/bing-there-done-that-ea-s-cco-talks-everything):
> Renderware didn't get the next-gen parts that we needed.

![the machinery](/images/2026/Our_Machinery.webp)

In July 2021, Our Machinery announced a new game engine, "The Machinery", available for a discounted price of $50.00 per year for independent developers and $450.00 per year for industry professionals. It came with the full suite of features, technical support and source access (there was also a free version without the source). On top of their game engine, they also published a [series of blog posts](https://ruby0x1.github.io/machinery_blog_archive/) explaining their development process (the blog goes back to 2017).

However, in August 2022, out of nowhere, licensed game developers were told to delete all traces of any source code or binaries they had of The Machinery and that development on the engine was halted ([article here](https://www.nme.com/news/gaming-news/the-machinery-game-engine-cancelled-as-developers-told-to-delete-all-source-code-3283633)). This prompted Ryan Fleury to write this in his blog post [Ships, Icebergs, Game Engines](https://www.dgtlgrove.com/p/ships-icebergs-game-engines):
> What becomes of work authored for a project that used The Machinery as its engine? If a game developer is lucky, their investment in The Machinery was kept to a minimum, and their content is largely decoupled from The Machinery technology. That, though, would be a very lucky (or careful) user of The Machinery—what is more likely, for that game developer, is that a hefty majority of the authored content—levels, gameplay code, assets—is, in fact, quite coupled to The Machinery technology, and so the value of that game developer’s content has dropped dramatically close to zero.

![unity](/images/2026/unity_runtimefee.png)

In August 2023, Unity announced that they would introduce a runtime fee based on game installs starting January 1st (Unity discussions link [here](https://discussions.unity.com/t/unity-plan-pricing-and-packaging-updates/927079)), which prompted a huge backlash in the community. They updated those policies on September 22nd with [Marc Whitten's open letter](https://unity.com/blog/an-open-letter-to-our-community) to revise and clarify some points, but they did not back down until September 2024, when Matt Bromberg (the new CEO after John Riccitiello) finally cancelled the Runtime Fee in [this announcement](https://unity.com/blog/unity-is-canceling-the-runtime-fee).

This left a deep scar in the indie game development community, with a lot of people trying to move to Godot or create their own game engines:
* [Kalling Kingdom Engine Port and YouTube Hiatus](https://www.elegacorp.com/blog/kalling-kingdom-engine-port-and-youtube-hiatus.html) — Elega Corporation on leaving Unity after the Runtime Fee controversy and building a proprietary game engine in Rust.
* [Godot Private Asset Library — Transitioning from Unity to Godot](https://spielmannspiel.com/blog/transitioning_from_unity_to_godot) — A developer's experience gradually moving new projects from Unity to Godot following the 2023 announcement.
* [From Unity to Godot: My Journey with “No Escape?!”](https://forum.godotengine.org/t/from-unity-to-godot-my-journey-with-my-no-escape-game-and-open-source-projects/126568) — A developer recounts rebuilding an existing Unity game from scratch in Godot 4.
* [Scrapyard Jam](https://itch.io/jam/scrapyard-jam) — A game jam created in the aftermath of Unity's pricing controversy, encouraging developers to build their own engines or experiment with alternatives.

The consequences of this runtime fee can still be seen today in 2026: at the Game Maker's Toolkit Game Jam, the most used game engine for submissions was Godot:

<blockquote class="bluesky-embed" data-bluesky-uri="at://did:plc:uwucgubhwifmvz4kcpuzjaxf/app.bsky.feed.post/3mrmx5mi3mk24" data-bluesky-cid="bafyreiepprqcjplsxbvrrqkvycr2geat2rq4i3lds4kjccmoyf7ojlttle" data-bluesky-embed-color-mode="system"><p lang="en">Well, it finally happened! After 9 years of Unity dominance, Godot was the most used game engine for GMTK Game Jam 2026 submissions. 

🤖 Godot - 47%
🎮 Unity - 34%
🛠️GameMaker - 5%
🚀 Unreal Engine - 3%
✨ Other - 11%<br><br><a href="https://bsky.app/profile/did:plc:uwucgubhwifmvz4kcpuzjaxf/post/3mrmx5mi3mk24?ref_src=embed">[image or embed]</a></p>&mdash; Game Maker&#x27;s Toolkit (<a href="https://bsky.app/profile/did:plc:uwucgubhwifmvz4kcpuzjaxf?ref_src=embed">@gamemakerstoolkit.com</a>) <a href="https://bsky.app/profile/did:plc:uwucgubhwifmvz4kcpuzjaxf/post/3mrmx5mi3mk24?ref_src=embed">July 27, 2026 at 2:58 PM</a></blockquote><script async src="https://embed.bsky.app/static/embed.js" charset="utf-8"></script>



### Financial independence

I remember a talk by Rami Ismail at Reboot Develop 2017 where he spoke about this triangle:

![Motivation, money and knowledge triangle](/images/2026/sr/motivation_money_knowledge.svg)

His point was that motivation is the most important of the three, because:
- Motivation + Knowledge + No Money = You can work part-time on your game
- Motivation + Money + No Knowledge = You can pay people to make your game
- Money + Knowledge + No Motivation = You do not make a game at all.

Nikita Lisitsa in his [blog post](https://lisyarus.github.io/blog/posts/so-you-want-to-make-a-game-engine.html) "So, you want to make a game engine" says:
> Why not make your own game engine? [...] You might find yourself too deep into engine development instead of making an actual game, which can easily lead to a burnout.

This is why, at the beginning, I talked about students making their own game engine for their ambitious MMO. As Nikita says:
> It is hard and time-consuming.

But if we imagine that we have a lot of motivation (or a well-scoped game engine), the knowledge (or the willingness to learn) and no money at all (or no willingness to give away a single penny when the game eventually comes out), then making a custom game engine could be financially better than using a third-party engine. Here is what Tyler Glaiel says about saving money by creating your own game engine ([here](https://medium.com/geekculture/how-to-make-your-own-game-engine-and-why-ddf0acbc5f3)):
> You most likely won’t (save money). Making an engine takes time, and time=money. [...] Using your own engine won’t make you sell more copies of your game automatically. And while you *can* save time in the long run, this usually means having your engine be good enough to carry you across multiple projects, while also providing you with significant workflow improvements compared to commercial engines. It’s not easy to get this right, and you definitely won’t if its your first try at it (and extremely unlikely if you’re doing 3D instead of 2D).

- **Unity:** Free with Unity Personal for up to **US$200,000** in gross revenue and/or funding over the previous 12 months. From **US$200,001 to US$24,999,999**, Unity Pro is mandatory and costs **US$2,310/year/seat** or **US$210/month/seat**. At **US$25M or more**, Unity Enterprise with custom pricing is mandatory. There is no revenue share or royalty. ([Unity][1])
- **Unreal Engine 5:** Free until a game earns **US$1M in lifetime gross revenue**, then Epic charges a **5% royalty**. Revenue earned through the Epic Games Store is royalty-free. ([Unreal Engine][2])
- **GameMaker:** Free for non-commercial use and a **US$99.99 one-time fee** for commercial games. Console exports require Enterprise, which costs **US$79.99/month** or **US$799.99/year**. ([GameMaker][3])
- **CRYENGINE:** Free upfront, with a **5% royalty** after the first **US$5,000/year/project**. Full source code is included. ([CRYENGINE][4])
- **Godot:** Completely free under the MIT license, with no royalties, subscriptions, or revenue limits. ([Godot Engine][5])

[1]: https://unity.com/products/pricing-updates "Unity pricing changes"
[2]: https://www.unrealengine.com/license?utm_source=chatgpt.com "Unreal Engine (UE5) licensing options - Unreal Engine"
[3]: https://gamemaker.io/en/help/articles/november-2023-pricing-terms-change-faq?utm_source=chatgpt.com "November 2023 Pricing/Terms Change FAQ"
[4]: https://www.cryengine.com/support/view/licensing?utm_source=chatgpt.com "CRYENGINE | Support: Licensing"
[5]: https://godotengine.org/license/?utm_source=chatgpt.com "License – Godot Engine"

One note from Maxim to finish this section (taking into account that time is money):
>It’s easy to think that building your own engine will save time and money, but that’s rarely the case. To develop a game using an engine like Unity or Unreal Engine 5, you need to invest time learning them. While this can take a while, it's still a much smaller time investment compared to building your own engine from scratch and learning the underlying technology needed for it.

## Low-level control

The Handmade Manifesto ([here](https://handmade.network/manifesto)) argues that programmers should understand how computers and their technology stacks work instead of relying on layers of opaque frameworks and dependencies. Their values add a "We like to reinvent the wheel" section. In a way, create a custom engine is implementing again a lot of code for problems that are already solved, but with a twisted on the specifics of our games. 

Reimplementing low-level systems does not mean one should reimplemented all of the low-level systems. Noel Berry (article [here]) delegates platform, input, and rendering work to SDL3 and uses FMOD for audio. Nikita also recommends using libraries like SDL, GLFW, SFML or OpenAL.

In their [Reddit AMA](https://www.reddit.com/r/factorio/comments/in5d3i/developer_technicaloriented_ama/), the developer of Factorio argued that for their game logic:
> 'standard engines' are so restrictive in what can be done and leave so much performance sitting there that I wouldn't ever consider using one for something like Factorio. 

Compilation time and build size are also something that change drastically when you have your own custom game engine. People working with Unreal or with Unity (especially il2cpp) might know about problems like those:
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">We upgraded a project from Unity 2022.3 to 6.3 and Unity is still the slow , cluncky thing it was before. The builds are as slow. compiling IL2CPP takes 1.5 hours on the machien that compiles UE5 source in 40 mins. It is hard to go back to Unity.</p>&mdash; Ashkan Saeidi Mazdeh (@Ashkan_GC) <a href="https://x.com/Ashkan_GC/status/2019446029175693724?ref_src=twsrc%5Etfw">February 5, 2026</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

For me, it got so problematic that I have a specific other computer that compiles Beach Slap at the end of a dev day for all the platforms (PC + Steam PC/Linux + Android APK/AAB + Nintendo Switch) in one bat script. 

Dan Baker argues that owning your own game engine can also lower compilation time:
> For example, our Nitrous Engine compiles very quickly. The engine compiles in less than 30 seconds. The engine code is clean and modular, so we can implement features in the engine or fix a bug in around a tenth of the time it would take in an off-the-shelf engine. Not only can we do a clean build of Ara in less than 2 minutes, but our debug version of the Ara and Nitrous is so fast that we can still run at 30 fps in full debug.

Sebastien de Graffenrid build size:
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">A nice thing about using your own C engine are the small build sizes.<br>And I didn&#39;t even try that hard to reduce the size! <a href="https://t.co/d85Po9ztUU">https://t.co/d85Po9ztUU</a> <a href="https://t.co/OO2QncB2lk">pic.twitter.com/OO2QncB2lk</a></p>&mdash; Sébastien de Graffenried (@seb_degraff) <a href="https://x.com/seb_degraff/status/1889649086560600088?ref_src=twsrc%5Etfw">February 12, 2025</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

Or Johnathan Blow own compiler:
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">I did some work on the compiler that had the side effect of speeding things up! Here are the current compile speeds on my desktop.<br><br>Current compiler size: 55,273 lines. <a href="https://t.co/HmYKzZ3z3q">pic.twitter.com/HmYKzZ3z3q</a></p>&mdash; Jonathan Blow (@Jonathan_Blow) <a href="https://x.com/Jonathan_Blow/status/1353939518588502018?ref_src=twsrc%5Etfw">January 26, 2021</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

Those three examples show that having custom game engines can not just improve the performance of your game, but also the performance of your workflow. Like Tyler Glaeil puts it:
> it’s nice to just have your own tech, [...]. It’s nice to be able to actually debug the internals of your game if something goes wrong. 

But he warns directly:
> But it can also suck if you made a couple of bad design choices and everything falls apart entirely, and there’s no resources online to help you. You have full control and full responsibility, and all the pros and cons that come with that.

With a custom game engine, you can make things faster and easier to use, but you can also completely screw it up and still have a C++ project that takes ages to compile. It then becomes your responsability to optimize the compile time of your project.

## Unique Game Mechanics

On this topic, Glaiel quotes:
> A great example of a justified use of a custom game engine is the well-known Noita. The game has a truly unique concept that likely wouldn’t have worked with any existing proprietary engine, a uniqueness captured in the name of its engine, "Falling Everything." Yet, Noita doesn’t rely on advanced graphical effects, it’s single-player, and it was built exclusively for one platform — PC.

- Miegakure
- Dwarf Fortress

## Specialization

Noel Berry's artist uses Asesprite so he simply implemented a direct importer of the format in his game engine. He also build custom level editors for the needs of his game and the team. He can do that because he does not need most of the features of a generic-purpose game engine.

Nikita makes the point that a custom game engine does not necesseraly need complex material graphs, global illumination, or advanced 3D physics, multiplayer infrastructure or industrial-scale editor tooling. For Glaiel, specialization is almost a requirement for a custom engine. He adds that:
> [...] you can make your asset pipeline / level editor / whatever way smoother to use when considering your specific use cases instead of needing it to be general purpose.

This is one of the talking points of [Andreas Fredriksson's Context is Everything](https://vimeo.com/644068002) talk at Handmade Seattle 2021, when you know your specific context, you can optimize accordingly and because you have low-level control over your custom engine, you can go as deep as you need to solve your problem. 

The point of specialization is also long-term. We might want to use our custom game engine for the next game, even for a whole series of games. This was the case for the [RED Engine of CD Projekt Red](https://witcher-games.fandom.com/wiki/REDengine):
- (2007) Aurora Engine: CDPR licensed and heavily modified BioWare’s engine to create The Witcher.
- (2011) REDengine 1: CDPR introduced its own proprietary engine with The Witcher 2.
- (2012) REDengine 2: The engine evolved to support consoles and multiplatform development.
- (2015) REDengine 3: REDengine was redesigned for the large open world of The Witcher 3.
- (2020) REDengine 4: The engine evolved again for the dense urban world of Cyberpunk 2077.
- (2023) REDengine 4: Phantom Liberty became the final major release built with REDengine.

Of course, we all know now that CD Projekt Red switched to Unreal for Witcher 4, and even though a game engine changes heavily from one version to another, some of the foundations still stay. 

## Multi-platform

When releasing a game on multiple platforms, Unity feels like magic. The time it takes to naively port a specific game to a console (may it be not the best port) is pretty low compare to do it by hand in a custom game engine (especially when we don't know the platform). To quote Nikita on multi-platform development with a custom game engine:
> Supporting multiple platforms adds more pain, since different platforms have different executable file formats, dynamic library formats, etc. You'll have to compile several different versions of your game, one for each platform.

Compared that to the "time to triangle" (the time to draw the first triangle of game engine on the console) that [Mark Cerny was talking at Gamelab in 2013](https://www.youtube.com/watch?v=xHXrBnipHyA) about for the PS3 (among other Sony's consoles):

| Platform          | “Time to triangle” |
| ----------------- | -----------------: |
| PlayStation       |     **1-2 months** |
| PlayStation 2     |     **3-6 months** |
| **PlayStation 3** |    **6-12 months** |
| PlayStation 4     |     **1-2 months** |

However, the big win for custom game engines are for very niche or retro platforms. The current version of Unity (6.4) support those game consoles:
- PlayStation 4 (including PlayStation VR)
- PlayStation 5 (including PlayStation VR2)
- Xbox One
- Xbox Series X
- Xbox Series S
- Nintendo Switch
- Nintendo Switch 2

Those are the previous and current generation of consoles. Which means that older or exotic game consoles requires you to use a custom game engine. On the [Playdate](https://play.date/), you are required to program in C or Lua with their SDK. The [Arduboy](https://www.arduboy.com/) also pushes the boundries with a C++ dialect in the Arduino ecosystem.

For GBJam in 2016, I made a Gameboy Game in C using GBDK (blog post [here](/gamedev/2016/10/17/soup-raiders-jailbreak-post-mortem-of-gbjam-5-doing-a-real-homebrew-gameboy-rom.html)). [GB Studio](https://www.gbstudio.dev/) did not exist back in the day, so I needed to suffer through the painful process of program on a system without debugger (the screen would just be blank at boot when there was a problem). 

Similarly, someone that has the same first name as me is working on a PS1 game on his custom game engine and here is the result:
<blockquote class="twitter-tweet"><p lang="en" dir="ltr">I started making stuff for PS1 exactly one year ago.<br><br>It&#39;s been a wild journey since then. I&#39;m thinking of writing a big article about it (and later a video, maybe).<br><br>And this is just the beginning of my PS1 journey! <br>Now that I have a pretty good engine, I can make a real game. <a href="https://t.co/fA1cWJfNlp">pic.twitter.com/fA1cWJfNlp</a></p>&mdash; Elias Daler (@EliasDaler) <a href="https://x.com/EliasDaler/status/1948300981130727607?ref_src=twsrc%5Etfw">July 24, 2025</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

Commercial game engines move forward with the technology and new game consoles, but custom game engines don't have the same requirements. 

## Modding

Tyler says about file management:
> You might want to be able to build mod support or dynamic loading/unloading or whatever off of this, as long as you have the basics here and only ever load files through the file manager, you can easily add whatever other functionality you want into this later.

But what can we load and allow the players to change? One of the games of my teenage years' game was Civilization IV (article in [Game Developer magazine of August 2005](https://media.gdcvault.com/GD_Mag_Archives/GDM_August_2005.pdf)) that had an unusual good architecture for this (very data-driven). It features four tiers of moddability:
- in-game WorldBuilder: an in-game map editor tool to customize terrain and place units, cities, buildings, resources
- XML/data modification: all the game variables, text, asset paths, and rules were located in standard CML files.
- Python scripting; all high-level game functionality were exposed to Python, so scripts could generate maps, modify the interface, trigger game events, override AI. 
- a C++ GameCore DLL SDK: users could also modify, replace or extend the low-level C++ code that plays the game.

While doing my research, I realized that there was a mod more than 20 years still in development named Realism Invictus [here](https://www.moddb.com/mods/realism-invictus/news/realism-invictus-38-released-20-year-anniversary-of-realism-invictus) which is a total overhaul of the game adding more than 130+ technologies to the tree as well as whole family of distinct units, more than 160 leaders, 80+ additional conventional military,  promotions, 21 additional civics, which makes it feel more like Civ IV 2.0. All this is possible because the game developers spent a lot of time to make the game (and thus the engine) moddable.

![arma 3]()

Same with ARMA III, a game by Bohemia Interactive. In his talk [THE PANDORA'S BOX OF MODDING IN 'ARMA' GAMES](https://gdcvault.com/play/1027043/The-Pandora-s-Box-of), Karel Mořický describes the different types of games in regard to mods:
- Standard game: cannot be tampered with, nobody see the mess of the code.
- Improvised mod: people willing to mod will do it -> often messy and unstable. 
- Moddable game: provides API for modders, mods add new content on top. We call such product a platform.

I find fascinating how in ARMA, you can have multiple mods, mod of a mod (mod depending on another mod), patch mod (overloading existing content) and that it works with multiplayer (with specific server mods and client mods). At the time of the talk, they had 70,174 mods. For this to work, they have the editors available from the main menu directly. To avoid mods not working when a new game update releases, they have a special development branch along the main one available to the modders who can synchronize their development to those of the development team. 

In the opposite, Minecraft Java Edition modding ecosystem mostly grew without Mojang providing a conventional official engine-level mod API. The primitive era saw modder simply decompiling the game and directly replacing or modyfing classes insed `minecraft.jar`. Then came the common layers built by different communities throughout the history of the game. The modern ecosystem is roughly Fabric, Forge, NeoForge, Quilt, without forgetting the server software ecosystems such as Paper and derivatives.  Minecraft Java Edition updates were painful for modders. Minecraft 1.13 involved substantial internal changes, so porting large mods became difficult, even the common layer Forge required asignificant redesign. 

Funny enough, the Bedrock Edition of Minecraft (aka the C++ version) tried a [JavaScript API](https://www.minecraft.net/en-us/article/scripting-api-now-public-beta) in 2018. It is now obsolete and the Script API now uses Molang a custom scripting language ([introduction here](https://learn.microsoft.com/en-us/minecraft/creator/documents/molang/introduction?view=minecraft-bedrock-stable)). 

In the case of Factorio, mods are allowed to run Lua code at the game startup and while a map is actively being played (article [here](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html)). 
Deterministic script ([here](https://www.factorio.com/blog/post/fff-70))
Dealing with broken mods ([here](https://www.factorio.com/blog/post/fff-178)) 
Treating the game itself as mods.

In my games, from the beginning we designed the level editor of Beach Slap to be able to share it with player by having it in-game. Fur this to work, our levels are json files that can be stored locally. I don't intent for Soup Raiders to support modding though. 

## Conclusion

Making a game engine has a lot of upsides, but it costs time. We control how we load and update our game (to the specific needs of our game), we owe no license fees to anybody, and we learn a lot about asset compilation, rendering and optimization. We can even open the engine to players (at least part of it) for them to improve or to create new mods (or even games) with our technology. In the rest of the series, we will go into the implementation details of the Soup Raiders Native Port and how we can target 60Hz on the Switch with sub-3s loading times.

I will leave you with one thought about creating your own game engine with LLM:

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
