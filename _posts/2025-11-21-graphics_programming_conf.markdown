---
layout: post
title:  "Graphics Programming Conference 2025"
#date:   2024-12-23 20:19:00 +0200
categories: jekyll update
---

![First image](/images/2025/industry_badge.jpg)

<!--more-->

This week, I went to Breda to attend the Graphics Programming Conference, thanks to SAE Institute. My goal was to delve into more advanced Computer Graphics before starting the module the week after.

Breda is a lovely city, south of the Netherlands, that you can easily access from Schiphol airport by train. Originally, I wanted to go by train from Lausanne with TGV and Eurostar, but in the end it did not work out with my schedule.

![Photo of Breda](/images/2025/breda_canal.jpg)

The conference is divided in three days, with very technical talks (which I love), some sponsored talks and some more "academic" talks. Sometimes, some talks are concurrent, but because they are all recorded, it is pretty easy to just go to the one that is most interesting for us. Overall, the quality of the talks is really high.

![Conference photo](/images/2025/conference.jpg)

As a teacher, those were the talks that I was the most interested in:
- **Getting to know Slang** by [Shannon Woods](https://www.linkedin.com/in/shannon-woods-5a43b42/): I am more used to GLSL, so the very HLSL-flavor of SLang does not attract me by default, however the whole struct, generic, interface looks very promising for bigger games/engines. 
- **Root signatures & shader ISA** by [Wessel de Groot](https://www.linkedin.com/in/wesseldegroot): Going a bit low-level would help me be on par on the GPU compared to the GPU.
- **After the Tutorial: Where to Continue your Graphics Programming Journey** by [Mike Shah](https://www.mshah.io/). I really liked how Mike diffirentiate the basics from the more advanced features regarding graphics and how he introduced the different abstractions one after the other along the graphics journey. 

Those talks were directly impactful for me for teaching Graphics Programming to my students. I will definitely share them with my students when they are on youtube.

Of course, going to a conference is also a break in the usual day-to-day life and it allows to have the brain breath and find new ideas, so here are the resulting ideas that came out of different talks:

![SEED](/images/2025/talk.a-decade-of-seed-lessons-from-10-years-of-r&d-in-games.talk-wide-1x.webp)
- **A Decade of SEED: Lessons from 10 Years of R&D in Games**: It made me think of research in the different areas of rendering, computer vision, game ai, physics, and animation. But also EA SEED is part of a big AAA studio and I was wondering what a research lab could look like for indie games. Currently, we mostly rely on Unreal or Unity or Godot (some still have the courage to use custom engine), but the sharing of custom tools and technology could really be improved and it made me think how I could help other devs around me (RGB conf was a try).

![Mobile](/images/2025/talk.eras-in-mobile-graphics.talk-wide-1x.webp)

- **Eras in mobile graphics**: ARM is putting NPU in GPU and GPU will start to look more like NPU. Something in me dislikes AI, but another part of me is thinking how AI can help solve a lot of problems. Just maybe not at the price of stealing everybody's work...

![DOOM](/images/2025/talk.a-beautiful-hell-path-tracing-in-doom-the-dark-ages.talk-wide-1x.webp)

- **A Beautiful Hell: Path Tracing in DOOM The Dark Ages**: I really want to experiment more with raytracing and path-tracing, maybe try to find solutions at a smaller scale than DOOM, but a fascinating talk.

![Water](/images/2025/talk.water-simulation-and-rendering-in-enshrouded.talk-wide-1x.webp)

- **Water Simulation & Rendering in Enshrouded**: Very interesting approach to simulate and then render water. Now I want to play with procedural content generation and water.

![Battlefield](/images/2025/talk.battlefield-6-pushing-visual-fidelity-while-optimizing-for-all-hardware.talk-wide-1x.webp)

- **Battlefield 6: Pushing visual fidelity while optimizing for all hardware**. Debug tools! I need to investigate how to make my like programming on the GPU easier. Maybe I can sneak ShaderToHuman in my projects.

![X-plane](/images/2025/talk.the-aircraft-of-theseus-shipping-x-plane-for-30-years.talk-wide-1x.webp)

- **The aircraft of Theseus - Shipping X-Plane for 30 years.** I really enjoyed this talk. It is very interesting to see how the team managed to update an OpenGL ***2.1*** engine with external plugins also using OpenGL 2.1 and updating it to Vulkan with Zink.

![Teardown](/images/2025/talk.raytracing-voxels-in-teardown-and-beyond.talk-wide-1x.webp)

- **Raytracing Voxels in Teardown and Beyond**. Again a very interesting talk that feels closer from home for me. Using OpenGL 3.3 and now updating to Vulkan, what an achievement.

I really enjoyed the ranges of talks and expertises. There were a lot of AAA studios, but also AA and smaller studios with very different problematics to solve. What I think might be missing is the point of view of the students, seeing some student work showcase, as they are the future of our industry in the end. 

All in all, I really enjoyed this second Graphics Programming Conference, learned a ton of stuffs, got inspired for a whole bunch of projects and I am ready to teach my computer graphics module next week! 

![Photo of Breda last](/images/2025/breda.jpg)