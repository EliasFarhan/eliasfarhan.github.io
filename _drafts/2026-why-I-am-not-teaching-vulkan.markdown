---
layout: post
title:  "Why I am not teaching Vulkan"
categories: jekyll update
---
<!--more-->
## Introduction

I made a blog post about why I am still teaching OpenGL ES 3.0 in 2025-2026 in my introduction to Computer Graphics course at SAE Institute [here](/jekyll/update/2026/01/27/why-i-teach-opengles.html), now let's talk about why I am not teaching Vulkan yet. 

How about a [VRHI](https://uaasoftware.bitbucket.io/vrhi.html)

## Vulkan 1.0

The portability (Switch, Android, Windows, Linux). 

On Android (from [here](https://developer.android.com/about/dashboards) as of Jan 7th 2025):
- Vulkan 1.0.3	3.86%
- Vulkan 1.1	62.09%
- Vulkan 1.3	26.01%
- Vulkan 1.4	0.67%


### Pipeline State Object (PSO)

### Render pass 

### Synchronization + presenting

### The mental load
Verbosity, so many different concepts for a triangle.

## Modern Vulkan?

Sascha Willems [How To Vulkan in 2026](https://www.howtovulkan.com/) showcases an example of modern Vulkan.

### Pipeline dynamic state
https://docs.vulkan.org/guide/latest/dynamic_state.html

### Dynamic rendering
https://docs.vulkan.org/samples/latest/samples/extensions/dynamic_rendering/README.html

[VK_KHR_dynamic_rendering_local_read](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_dynamic_rendering_local_read.html)

### Shader object
https://docs.vulkan.org/samples/latest/samples/extensions/shader_object/README.html

### Buffer Device Address

### Mesh Shader


## The reason why not

### Descriptor Sets + Push Constant

[VK_KHR_push_descriptor](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_push_descriptor.html)

[VK_EXT_descriptor_indexing](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html)

### Synchronization

**Fences**

**Binary semaphores**

**Pipeline Barriers** 

In the middle of the module, we implement a simple OpenGL sample with a framebuffer drawing a scene and then applying some simple post-processing on it. In OpenGL, the synchronization between those pipelines is done through implicit ordering (first we do the scene pass, then the post-processing pass). However, in Vulkan, synchronization between those two passes needs to be done through a 
pipeline memory barriers. 

However, there are some extensions that makes live simple:
- [VK_KHR_unified_image_layouts](https://docs.vulkan.org/features/latest/features/proposals/VK_KHR_unified_image_layouts.html) allows the pipeline barriers to set VK_IMAGE_LAYOUT_GENERAL instead of the variations of image layouts


- [VK_KHR_synchronization2](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_synchronization2.html) bundles memory, buffer, and image barriers into a single structure passed to vkCmdPipelineBarrier2.


## Next steps

I am not switching to Vulkan yet, but this retrospective pushed to look deeper into Vulkan and to try to implement several samples to prove my points. Maybe instead of switching, I could be adding Vulkan to my OpenGL ES course throughout the module. Most of my students work on mid-range gaming laptop with a discrete Nvidia or AMD card. If enough of the Vulkan setup is done, one can dream that a motivated could do the same samples in Vulkan as the one in OpenGL. 

### Vulkan Bootstrap

### The extensions
VK_EXT_scalar_block_layout

### Raytracing

**Shadow**
Using ray query

**Simple reflections**


**Pathtracing**
PBR through pathtracing