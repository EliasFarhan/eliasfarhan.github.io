---
layout: post
title:  "Why I still teach OpenGL ES 3.0"
categories: jekyll update
---

<!--more-->

## Introduction

It's been a few years that I have been giving this Introduction to Computer Graphics module (a trimester) at SAE Institute Geneva and I have always been wondering if and when I would need to transition my course from OpenGL to more modern API. 

Back in Novmeber, I was at the Graphics Programming Conference (my blog post [here](jekyll/update/2025/11/21/graphics_programming_conf.html)), and this subject reemerged for me during the conversations with people from the industry as well as from the talks. From the Teardown talk, the original game worked in OpenGL 3.3 and from the X-Plane talk, the rendering engine was using OpenGL 2.1. But both those talks were about how they transitionned to more modern API to have better graphics. 

Two talks really could my attention about education for Computer Graphics: the talk _Bridging Pixels and Code: Teaching Computer Graphics to Technical Artists_ from Matthieu Delaere that focus on students creating their own rasterizer from scratch and the talk from Mike Shah that focuses on the next steps after the tutorial. The latter talk actually made me think about if the actual idea to do the transition to modern API for my course made still sense.

## The course content
Since when I started to give Computer Graphics courses, I have been following the [learnopengl.com](https://learnopengl.com/) structure with the variation of OpenGL ES 3.0. But why specifically this version? Because it is the most cross-platform version of OpenGL for me, with this version you can run the same C++ program (with some caveats) and the same shaders for:
- Windows: while I encountered some driver issues throughout the year, OpenGL ES 3.0 is compatible with OpenGL 4.3, so I just assume OpenGL 4.3 on Windows not to worry.
- Linux: recently I had some issue with Wayland vs X working on some OpenGL tests, I need to dig deeper if there is any issue (probably building SDL3 without the proper dependencies).
- Android: this one is a bit complicated as the actual android app boots from Java and calls the native lib containing the code.
- Nintendo Switch: we have two devkits at school and except removing glew or glad and replcing it with the embedding OpenGL wrapper, it works fine.
- WebGL2: my favorite reason of using OpenGL ES 3.0 is that it is mostly compatible with WebGL2 with emscripten (except float color attachment that is an extension...), which allows my students to port their samples to their own website.
- Probably iOS or MacOSX: I did not try personally.


## Core concepts

### Pipeline

### GPU memory

### Textures

### Draw commands

### Render passes & Framebuffer

## Conclusion


