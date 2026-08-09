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

A game engine is a reusable software framework that allows to create and run a computer game. It sits between the actual game code (gameplay logic) and the operating system (Windows, SteamOS, Android): 

![](/images/2026/game_engine_stack.svg)

In this position, the game engine role is to make sure that the game loop is running by interacting with the OS accordingly. This game loop runs as follow:

![](/images/2026/game_loop.svg)

- **Event Polling**: window resizing, keyboard/mouse/controller input changes, exiting the game, ...  
- **Gameplay**: physics, calling the gameplay code
- **Rendering**: generating the commands to be sent to the GPU to then present the new images on the screen.

But that's not all what a game engine is supposed to do, it also needs to load all the assets that the game need (3d models, animations, sprites, music and sounds) and all of this is work that is not implementing the specifics of the actual game. We will go into details in the next blog posts about each part and how it is implemented in Soup Raiders Native.

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


But then of course, it does not mean that all the successfull indie games have their own custom game engine. Unity took a big market share in mobile game development as well as indie games. For example, here is a list of games made with Unity:

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


But we still have this "Make a game or make a game engine" (or ["Make your game, not an engine"](https://norikitech.com/posts/make-your-game/) by Yuri Karabatov) statement that we throw over the faces of computer science students who already dream of creating their MMO even before they finished their bachelor. Because like Tyler Glaiel puts it (in this blog post [here](https://medium.com/geekculture/how-to-make-your-own-game-engine-and-why-ddf0acbc5f3)): 
> You think you can just make something better than Unity or Unreal (or Godot or GameMaker) in general. You can’t. It’s possible to make something that is better than these for specific use cases [...], but you, as an individual or a tiny team, are not going to compete with these for general purpose stuff. Especially if you have never made your own game engine before.

I really like the approach of Noel Berry (described in this blog post [here](https://noelberry.ca/posts/making_games_in_2025/)). The engine and editor that he created allow him to quickly create the 2d games that he wants to make and he leverages 20 years of making games into this specific goal. His game engine is written in C#, uses SDL3, DearImGui for the custom level editors, he works mostly on Linux and uses Native-AOT to cross-compile for platforms who don't like VM.

Our goal with this Soup Raiders Native Port is not to make Unity or Unreal, but it is to make a game engine that supports this specific game (exactly what Tyler Glaiel tweeted about [here](https://x.com/TylerGlaiel/status/1806476966973116539)). So now that we know what a custom game engine is, we can try to answer the question of why making a game engine.

## Curiosity & Learning

Tyler Glaiel (him again) describes creating your game engine to learn how it works one of the best reasons to make one. I started making games by making my own custom 2d game engine in Python with [pygame](https://github.com/pygame/pygame). That was the early 2010s and Unity was not yet where it is now. For example, my first game jam game "[Trials](https://teamkwakwa.itch.io/trials)":

![Trials](/images/trials.png)

In the history of my game development career, I started using Python and Pygame with box2d and then with a colleague from EPFL, we had a C/C++ game engine embedding a Python interpreter that could run my games faster. Finally, for [Super Splash Fisticuffs}(/gamedev/2015/04/27/ludum-dare.html) (which became Splash Blast Panic) I switched to Unity 5. It was only in my teaching that I went back to creating C++ game engine, except for the small [Game Boy game](/gamedev/2016/10/17/soup-raiders-jailbreak-post-mortem-of-gbjam-5-doing-a-real-homebrew-gameboy-rom.html) that I implemented in C with [GBDK](https://gbdk.sourceforge.net/). 

But why should you learn to make a custom game engine, when there is already Unity or Unreal? Actually, I make the point that making your own game engine teaches you a lot about how Unity or Unreal (or Godot) work. For my students who want to work in the game industry, it can actually be a way to understand how proprietary game engines work, because as a teacher, I don't have access to them. So instead of just learning the Unity way or the Unreal way, creating a custom game engine gives the opportunity to explore the possibility space of every game engine architecture choices. 

In the computer graphics module at SAE Institute Geneva, the games programming students have to make a 3d scene using OpenGL ([here](graphics/cpp/2026/01/27/why-i-teach-opengles.html) is a blog post on why I still use OpenGL instead of more modern API). Throughout this process, they learn all the basics of what a rasterize renderer. For example, when I introduce shadow mapping, I show them an implementation of cascaded shadow map.

![cascaded shadow map](/images/2026/romulan_cascaded.png)

You can see on the right side the three cascades of shadow maps and in the scene the tinting colors to show which pixel is using which cascade. Funny enough, when implementing the first version of Soup Raiders on Unity, I was trying to optimize the rendering in the Unity settings and I landed on this option:

![cascaded unity setting](/images/2026/unity_cascade.png)

In those situations, there are different options:
1. I don't know what cascaded shadow map is, so I don't touch anythin
2. I don't know what cascaded shadow map is, so I search online (or ask an LLM) and I get a sense of what it is, so I can change this setting and try to guess how it impacts my performance
3. I implemented cascaded shadow mapping in an OpenGL sample by hand and I know exactly what it means and choose the correct setting accordingly.

The answer for Soup Raiders what to only have one shadow map (so no cascade) and do some filtering when drawing the meshes and sprites (I did not really care about the quality of the shadow far away as this is not a open world). Different game, different context, different reasoning, so different decision.

Another example come from Beach Slap, as I was optimising the game for mobile (I have an old iPad Air 2 from 2014 for that), when profiling, I realized that there was a lot of time spent on Occlusion Culling, which is a technique that allows to discard draw calls of objects behind other objects. It's a super useful techiniques for example in games with a lot of geometry that is especially hidden. But check my game:

![beach slap](/images/2026/gamescom26_SS%20(6).jpg)

No object is hidden behind another one. Which means that I don't need Occlusion Culling at all. Again, because I implemented Occlusion Culling for my course, I have an idea of its cost and I definitely know that I don't need.

In conclusion, I am not the only one saying this. Mathieu Ropert who worked at Paradox on their custom game engine in C++ has this to say about a gig:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Wrapped up a consulting job on UE5 with no prior engine experience outside hobby interest.<br>Within hours I had significant performance improvements and found architectural design flaws.<br>Making CV hard requirements on specific engines is deeply unserious about software engineering.</p>&mdash; Mathieu Ropert (@MatRopert) <a href="https://x.com/MatRopert/status/2049803204385226827?ref_src=twsrc%5Etfw">April 30, 2026</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

## Independence

I did a **degoogling** step end of 2024 for most of my google drive and google photos (that I move to Proton Drive), cancelling my Xbox Game Pass subscription (I was not playing that much anyway), canceled my Spotify account (moved to Qobuz for one year, but I might just go back to just buy the music I like or listening it on Youtube). Big tech is everywhere and I still want to get rid of Github, Microsoft Windows and Google Calendar, but their conveniences are really hard to get rid of.

The **indie** in indie game developer means independent from publisher, but what about platform holders (Nintendo, Sony, Microsoft, Valve, Apple) or the engine providers (Unity, Unreal, etc...)? What about version control, do you push your code to Github (this is Microsoft)? And sharing asset files, do you use Google Drive? What about your OS? Most of the gamedevs are on Windows for most of the middlewares work only there, some developers are on MacOSX. 

Like Maxim Kiselev points out in his article [here](https://www.gamedeveloper.com/programming/real-reasons-not-to-build-custom-game-engines-in-2024), when using a third-party engine, we have three dependences

### Technical

For the technical dependency, according to Maxim in the same article:
> If you're using a third-party engine and encounter a bug or missing feature that impacts your game, you often have no choice but to wait for the engine’s developers to fix it.

It is the same regardless if the third-party engine is a big proprietary closed-source engine or an open-source one (at least you can see and fix the open one). For me, using a third-party engine means locking yourself in one way of implementing the game, which is ok in most cases, but can be detrimental in specific cases. 

It reminds me of Unity doing the transition from OpenGL/DX11 to Vulkan/DX12 where the modern RHI (rendering hardware abstractions) would still need to emulate the old RHI, which means that they were much slower that what they could.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Vulkan and DX12 was initially slower in Unreal/Unity because their RHIs didn&#39;t match the retained mode grouping of Vulkan/DX12. Developers had to add hash maps under the RHI to map dynamic API to retained PSO and descriptor set APIs. Which added complexity and CPU cost a lot.</p>&mdash; Sebastian Aaltonen (@SebAaltonen) <a href="https://x.com/SebAaltonen/status/1880889196363251790?ref_src=twsrc%5Etfw">January 19, 2025</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

Of course, Unity could not just break their RHI from one version to another, but it also means that a new custom engine built on Vulkan/DX12 could easily beat Unity in terms of RHI performance by having a new one that was matching those new API. Sebastian Aaltonen actually made a prototype during Unity Hackweek 2019:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">When I was working at Unity, we did a simple (4 day) prototype at Hackweek 2019 with fully persistent data and descriptor sets. The performance was super good:<a href="https://t.co/NPyXHP3NiM">https://t.co/NPyXHP3NiM</a><br><br>This is how Vulkan was designed to be used. When you try to emulate DX11 the perf sucks.</p>&mdash; Sebastian Aaltonen (@SebAaltonen) <a href="https://x.com/SebAaltonen/status/1532988130290241536?ref_src=twsrc%5Etfw">June 4, 2022</a></blockquote> <script async src="https://platform.x.com/widgets.js" charset="utf-8"></script>

With a custom game engine, you have full control over your development process and tech stack.

### Legal

You don't own your third-party engine. You just have a license with the company that allow you to use it. Which also mean that they can also take it away whenever they consider that you violated their Terms of Service. It happened several times for developers using Unity:
- [Improbable/SpatialOS in 2019](https://techcrunch.com/2019/01/11/improbable-urges-unity-to-unsuspend-their-game-engine-license-or-clarify-terms/)
- [A student who got their license revoked the day before releasing their's game demo in July 2026](https://www.reddit.com/r/unity/comments/1ur9j7m/was_gonna_launch_my_games_demo_tomorrow_but_am/)
- [Mike Thorn getting his license revoked - March 2024](https://discussions.unity.com/t/my-personal-license-has-been-revoked/942826)
- [License Revoked, Editor Closed, Work Lost - Aug 2023](https://discussions.unity.com/t/license-revoked-editor-closed-work-lost/926284)

Switching to a free and open-source engine like Godot solves this problem. It is released under the permissive [MIT license](https://godotengine.org/license/). It works the same way with Unreal that is free but open-source which give a degree of technical independence that Unity's license activation system doesn't necessarily provide.

![renderware](/images/2026/RenderWare_(2002).png)

In the PS2 era, Criterion Games created RenderWare, a cross-platform 3D game engine for PC, PlayStation 2, Xbox and GameCube. The big deal was that each of those consoles had different CPU architectures (PS2 was MIPS, GameCube was PowerPC, Xbox was x86 like PC). So to have a game engine that allow to target all those platforms was like the Unreal Engine of the PS2 generation. It powered many popular games across different studios, including:

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

However, after EA acquired Criterion in 2004, RenderWare was gradually withdrawn as commercial middleware and effectively disappeared from the market by 2007 (see [EA's acquisition of Criterion](https://www.gamespot.com/articles/ea-assimilates-criterion/). According to [William "Bing" Gordon from EA](https://www.gamedeveloper.com/business/bing-there-done-that-ea-s-cco-talks-everything):
> Renderware didn't get the next-gen parts that we needed.

![the machinery](/images/2026/Our_Machinery.webp)

In July 2021, Our Machinery annonced a new game engine "The Machinery", available for a discounted price of $50.00 per year for independent developers and $450.00 per year for industry professionals. It came with with the full suite of features, technical support, and source access ( a free version without source). On top of their game engines, they also published a [series of blog post](https://ruby0x1.github.io/machinery_blog_archive/) explaining their development process (the blog dated from 2017).

However, in August 2022, out of nowhere, licensed game developers were told to delete all traces of any source code or binaries they had of The Machinery and that development on the engine was halted ([article here](https://www.nme.com/news/gaming-news/the-machinery-game-engine-cancelled-as-developers-told-to-delete-all-source-code-3283633)). This prompted Ryan Fleury to write this in his blog post [Ships, Icebergs, Game Engines](https://www.dgtlgrove.com/p/ships-icebergs-game-engines):
> What becomes of work authored for a project that used The Machinery as its engine? If a game developer is lucky, their investment in The Machinery was kept to a minimum, and their content is largely decoupled from The Machinery technology. That, though, would be a very lucky (or careful) user of The Machinery—what is more likely, for that game developer, is that a hefty majority of the authored content—levels, gameplay code, assets—is, in fact, quite coupled to The Machinery technology, and so the value of that game developer’s content has dropped dramatically close to zero.

![unity](/images/2026/unity_runtimefee.png)

In August 2023, Unity annouced that they would introduce runtime fee based on game installs starting January 1st (Unity discussions link [here](https://discussions.unity.com/t/unity-plan-pricing-and-packaging-updates/927079)) which prompted a huge backlash in the community. They updated those policies on September 22th with [Marc Whitten's open letter](https://unity.com/blog/an-open-letter-to-our-community) to revise/clarify some points but did not back down until September 2024 when Matt Bromberg (the new CEO after John Riccitello) finally cancelled the Runtime Fee in [this annoncement](https://unity.com/blog/unity-is-canceling-the-runtime-fee).

This left a profound trauma in the indie game development community with a lot of people trying to move to Godot or create their own game engines:
* [Kalling Kingdom Engine Port and YouTube Hiatus](https://www.elegacorp.com/blog/kalling-kingdom-engine-port-and-youtube-hiatus.html) — Elega Corporation on leaving Unity after the Runtime Fee controversy and building a proprietary game engine in Rust.
* [Godot Private Asset Library — Transitioning from Unity to Godot](https://spielmannspiel.com/blog/transitioning_from_unity_to_godot) — A developer's experience gradually moving new projects from Unity to Godot following the 2023 announcement.
* [From Unity to Godot: My Journey with “No Escape?!”](https://forum.godotengine.org/t/from-unity-to-godot-my-journey-with-my-no-escape-game-and-open-source-projects/126568) — A developer recounts rebuilding an existing Unity game from scratch in Godot 4.
* [Scrapyard Jam](https://itch.io/jam/scrapyard-jam) — A game jam created in the aftermath of Unity's pricing controversy, encouraging developers to build their own engines or experiment with alternatives.

The result of this runtime fee can still be seen today in 2026, because at the Game Maker's Toolkit Game Jam the most used game engine for submissions was Godot:

<blockquote class="bluesky-embed" data-bluesky-uri="at://did:plc:uwucgubhwifmvz4kcpuzjaxf/app.bsky.feed.post/3mrmx5mi3mk24" data-bluesky-cid="bafyreiepprqcjplsxbvrrqkvycr2geat2rq4i3lds4kjccmoyf7ojlttle" data-bluesky-embed-color-mode="system"><p lang="en">Well, it finally happened! After 9 years of Unity dominance, Godot was the most used game engine for GMTK Game Jam 2026 submissions. 

🤖 Godot - 47%
🎮 Unity - 34%
🛠️GameMaker - 5%
🚀 Unreal Engine - 3%
✨ Other - 11%<br><br><a href="https://bsky.app/profile/did:plc:uwucgubhwifmvz4kcpuzjaxf/post/3mrmx5mi3mk24?ref_src=embed">[image or embed]</a></p>&mdash; Game Maker&#x27;s Toolkit (<a href="https://bsky.app/profile/did:plc:uwucgubhwifmvz4kcpuzjaxf?ref_src=embed">@gamemakerstoolkit.com</a>) <a href="https://bsky.app/profile/did:plc:uwucgubhwifmvz4kcpuzjaxf/post/3mrmx5mi3mk24?ref_src=embed">July 27, 2026 at 2:58 PM</a></blockquote><script async src="https://embed.bsky.app/static/embed.js" charset="utf-8"></script>



### Financial

I remember a talk by Rami Ismail at Reboot Develop 2017 where he spoke about this triangle:

![Motivation, money and knowledge triangle](/images/2026/sr/motivation_money_knowledge.svg)

His point was that motivation was the most important of those three, because:
- Motivation + Knowledge + No Money = You can work part-time on your game
- Motivation + Money + No Knowledge = You can pay people to make your game
- Money + Knowledge + No Motivation = You do not make a game at all.

Nikita Lisitsa in his [blog post](https://lisyarus.github.io/blog/posts/so-you-want-to-make-a-game-engine.html) "So, you want to make a game engine" says:
> Why not make your own game engine? [...] You might find yourself too deep into engine development instead of making an actual game, which can easily lead to a burnout.

This is why in the beginning I talked about students making their own game engine for their ambitious MMO. Like Nikita says:
> It is hard and time-consuming.

But if we imagine that we have a lot of motivation (or a good scope for the game engine), the knowledge (or the willingness to learn) and no money at all (or not willing to give any penny when the game eventually comes out), then making a custom game engine could be financially better than using a third-party engine. Tyler Glaiel says about saving money on creating your own game engine ([here](https://medium.com/geekculture/how-to-make-your-own-game-engine-and-why-ddf0acbc5f3)):
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


## Specialization

Sometimes, your game is just too crazy

Total war, Factorio

## Modding


No modding for Splash Blast Panic.
For Beach Slap, we have a custom level editor in the game, but we don't let the possibility through a tool to change the content of the game.

## Conclusion

Making a game has a lot of good, but at a time cost. We control how we load and upadte our game (to the specific need of our game), we owe no license to anybody, and we learn a bunch about asset compilation, rendering, and optimization. In the rest of the series, we will detail in the implementation details of the Soup Raiders Native Port and how we can target 60Hz in the Switch with sub-3s loading time.   

I leave with one thing to think about creating your own game engine with LLM:

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
