---
layout: post
title:  "Why I am not teaching Vulkan"
categories: jekyll update
---

## Introduction

I made a blog post about why I am still teaching OpenGL ES 3.0 in 2025-2026 in my introduction to Computer Graphics course at SAE Institute [here](/jekyll/update/2026/01/27/why-i-teach-opengles.html), now let's talk about why I am not teaching Vulkan yet and how I could introduce it in my course. One could say that OpenGL ES is enough for the introduction to computer graphics, because it manages to run simple samples on a lot of platforms. 

<!--more-->

However, a lot of more modern techniques used in the most common game engines are really starting to show OpenGL (especially ES) as antique, meaning that students following my course might not understand most of what makes real-time computer graphics now. But Vulkan is a beast to tackle when trying to learn it (the origin [Vulkan Tutorial](https://vulkan-tutorial.com/) definitely did not help). So what about an RHI like NVRHI or more recently the [Vulkan Rendering Hardware Interface](https://uaasoftware.bitbucket.io/vrhi.html)? I think there is value in learning the actual GPU API instead of a library that sits on top of it, so let's go dig into Vulkan!

## Vulkan 1.0

This section will focus on Vulkan 1.0. I know that we are currently at Vulkan 1.4 and I will talk about it and its useful extensions in later sections. One of the good reasons to use Vulkan 1.0 is the portability between Switch, Android, Windows, Linux, MacOSX and iOS (through MoltenVK). 

On Android (from [here](https://developer.android.com/about/dashboards) as of Jan 7th 2025):
- Vulkan 1.0.3	3.86%
- Vulkan 1.1	62.09%
- Vulkan 1.3	26.01%
- Vulkan 1.4	0.67%

However, it still means losing the WebGL2 port compared to OpenGL ES 3.0. Yes WebGPU exists, but it is not a 1-to-1 translation like OpenGL ES 3.0 to WebGL2, it requires much more effort than most of my students want to do.

### The mental load

I still remember going through the Vulkan tutorial the first time. Just to render a triangle, one has to interact with:
- `VkInstance` (created with `VkInstanceCreateInfo` )
- `VkPhysicalDevice` (queried with `vkEnumeratePhysicalDevices`) and keep queue family indices
- `VkDevice` (created with `VkDeviceCreateInfo` using the `VkPhysicalDevice`)
- `VkSurfaceKHR` (created using SDL)
- `VkQueue` (created using `VkDeviceQueueCreateInfo`)
- `VkSwapchainKHR` and retrieving all its `VkImage` and generates their `VkImageView`
- `VkShaderModule` (created in a similar way than OpenGL but loading SPIR-V files instead of GLSL)
- `VkRenderpass` with its `VkAttachmentDescription`, `VkSubpass` 
- `VkPipeline` created using:
    - `VkPipelineShaderStageCreateInfo` 
    - `VkPipelineDynamicStateCreateInfo`
    - `VkPipelineVertexInputStateCreateInfo`
    - `VkPipelineInputAssemblyStateCreateInfo`
    - `VkPipelineViewportStateCreateInfo` using `VkViewport` and `VkRect2D` scissor
    - `VkPipelineRasterizationStateCreateInfo` 
    - `VkPipelineMultisampleStateCreateInfo`
    - `VkPipelineColorBlendStateCreateInfo` using `VkPipelineColorBlendAttachmentState`
    - `VkPipelineLayout`
    -> needed the renderpass created before as well with the subpass index
- `VkFramebuffer` created with `VkFramebufferCreateInfo`  using the `VkImageView` attachments and the renderpass
- `VkCommandBuffer` created with `VkCommandBufferAllocateInfo` from a `VkCommandPool` created using `vkCreateCommandPool` 

All that to record the draw call of our hello world triangle in a command buffer and give it to the queue. It does not take into account:
- `VkBuffer` and allocations
- `VkImage` with `VkSample` and the transitions from loading to using it in a sample
- The synchronization of attachments between subpasses
- All the nice things the OpenGL driver do for us

### Pipeline State Object (PSO)

Like showed in the mental load list, creating a `VkPipeline` in Vulkan 1.0 requires A LOT of different states, some often irrelevant to the current need of the graphics programmer creating a new pipeline to be used in their samples. If I need to put it in diagram, it would look like this:
```

                        ┌─────────────────────────────────┐
                        │   vkCreateGraphicsPipelines()   │
                        └────────────────┬────────────────┘
                                         │
                        ┌────────────────▼────────────────┐
                        │ VkGraphicsPipelineCreateInfo    │
                        └────────────────┬────────────────┘
                                         │
        ┌──────────────┬─────────────┬───┴────┬──────────────┬──────────────┐
        │              │             │        │              │              │
        ▼              ▼             ▼        ▼              ▼              ▼
 ┌─────────────┐ ┌───────────┐ ┌─────────┐ ┌──────────┐ ┌────────────┐ ┌────────────┐
 │ VkPipeline  │ │ VkPipeline│ │VkRender │ │VkPipeline│ │VkPipeline  │ │   stage    │
 │   Layout    │ │   Cache   │ │  Pass   │ │  flags   │ │  subpass   │ │   Count    │
 └─────────────┘ └───────────┘ └─────────┘ └──────────┘ └────────────┘ └──────┬─────┘
        │                                                                     │
        ▼                                                                     ▼
 ┌──────────────────┐                                       ┌──────────────────────────┐
 │ VkPipelineLayout │                                       │ VkPipelineShaderStage    │
 │ CreateInfo       │                                       │ CreateInfo[]             │
 │                  │                                       │                          │
 │ ┌──────────────┐ │                                       │  ┌────────────────────┐  │
 │ │ VkDescriptor │ │                                       │  │ VK_SHADER_STAGE_   │  │
 │ │ SetLayout[]  │ │                                       │  │ VERTEX_BIT         │  │
 │ └──────────────┘ │                                       │  │    ▼               │  │
 │ ┌──────────────┐ │                                       │  │ VkShaderModule     │  │
 │ │ VkPushConst  │ │                                       │  └────────────────────┘  │
 │ │ Range[]      │ │                                       │  ┌────────────────────┐  │
 │ └──────────────┘ │                                       │  │ VK_SHADER_STAGE_   │  │
 └──────────────────┘                                       │  │ FRAGMENT_BIT       │  │
                                                            │  │    ▼               │  │
                                                            │  │ VkShaderModule     │  │
                                                            │  └────────────────────┘  │
                                                            └──────────────────────────┘

   ┌──────────────────── Fixed-Function State ────────────────────────┐
   │                                                                  │
   │  ┌──────────────────────┐    ┌──────────────────────┐            │
   │  │ VkPipelineVertexInput│    │ VkPipelineInputAssem │            │
   │  │ StateCreateInfo      │    │ blyStateCreateInfo   │            │
   │  │                      │    │                      │            │
   │  │ • bindingDescriptions│    │ • topology           │            │
   │  │ • attribDescriptions │    │ • primitiveRestart   │            │
   │  └──────────────────────┘    └──────────────────────┘            │
   │                                                                  │
   │  ┌──────────────────────┐    ┌──────────────────────┐            │
   │  │ VkPipelineViewport   │    │ VkPipelineRasterizat │            │
   │  │ StateCreateInfo      │    │ ionStateCreateInfo   │            │
   │  │                      │    │                      │            │
   │  │ • viewports[]        │    │ • polygonMode        │            │
   │  │ • scissors[]         │    │ • cullMode           │            │
   │  └──────────────────────┘    │ • frontFace          │            │
   │                              │ • depthBias          │            │
   │                              │ • lineWidth          │            │
   │                              └──────────────────────┘            │
   │                                                                  │
   │  ┌──────────────────────┐    ┌──────────────────────┐            │
   │  │ VkPipelineMultisample│    │ VkPipelineDepthStenc │            │
   │  │ StateCreateInfo      │    │ ilStateCreateInfo    │            │
   │  │                      │    │                      │            │
   │  │ • rasterizationSamp  │    │ • depthTestEnable    │            │
   │  │ • sampleShading      │    │ • depthWriteEnable   │            │
   │  │ • sampleMask         │    │ • depthCompareOp     │            │
   │  └──────────────────────┘    │ • stencilTestEnable  │            │
   │                              └──────────────────────┘            │
   │                                                                  │
   │  ┌──────────────────────┐    ┌──────────────────────┐            │
   │  │ VkPipelineColorBlend │    │ VkPipelineDynamic    │            │
   │  │ StateCreateInfo      │    │ StateCreateInfo      │            │
   │  │                      │    │                      │            │
   │  │ • logicOpEnable      │    │ • dynamicStates[]    │            │
   │  │ • attachments[]      │    │   - VIEWPORT         │            │
   │  │   - blendEnable      │    │   - SCISSOR          │            │
   │  │   - srcColorBlendFac │    │   - LINE_WIDTH       │            │
   │  │   - dstColorBlendFac │    │   - DEPTH_BIAS       │            │
   │  │   - colorWriteMask   │    │   - BLEND_CONSTANTS  │            │
   │  └──────────────────────┘    │   - ...              │            │
   │                              └──────────────────────┘            │
   └──────────────────────────────────────────────────────────────────┘

                        ┌─────────────────────────────────┐
                        │          VkPipeline             │
                        │      (output handle)            │
                        └─────────────────────────────────┘
```

In a way, this forces the use of data-driven development, defining empty default structures, enabling specific features only when needing them. This was one of the goal of my computer graphics editor (mentionned in this [blog post](/jekyll/update/2023/11/29/compgrapheditorv1.html)), setting up states in an editor, instead than by hand.

However, for my course, I also want my students to quickly be able to create a sample and modify some values to showcase the techniques shown during the course. Especially for the first course with Hello Triangle, the coginitive load cannot be overloaded. Here are some few problems:
- One need to give the `VkRenderPass` and the `subpassIndex` where the pipeline is going to be used. 

### Render pass 

```
                          ┌───────────────────────────────┐
                          │     vkCreateRenderPass()      │
                          └───────────────┬───────────────┘
                                          │
                          ┌───────────────▼───────────────┐
                          │  VkRenderPassCreateInfo       │
                          └───────────────┬───────────────┘
                                          │
              ┌───────────────────────────┼───────────────────────────┐
              │                           │                           │
              ▼                           ▼                           ▼
 ┌─────────────────────┐  ┌─────────────────────────┐  ┌──────────────────────┐
 │ pAttachments[]      │  │ pSubpasses[]            │  │ pDependencies[]      │
 │ (attachmentCount)   │  │ (subpassCount)          │  │ (dependencyCount)    │
 └──────────┬──────────┘  └────────────┬────────────┘  └──────────┬───────────┘
            │                          │                          │
            ▼                          ▼                          ▼
 ┌─────────────────────┐  ┌─────────────────────────┐  ┌──────────────────────┐
 │ VkAttachmentDescrip │  │ VkSubpassDescription    │  │ VkSubpassDependency  │
 │ tion                │  │                         │  │                      │
 │                     │  │                         │  │ • srcSubpass         │
 │ • flags             │  │ • pipelineBindPoint     │  │ • dstSubpass         │
 │ • format            │  │   (GRAPHICS)            │  │ • srcStageMask       │
 │ • samples           │  │                         │  │ • dstStageMask       │
 │ • loadOp            │  │ • inputAttachments[]    │  │ • srcAccessMask      │
 │ • storeOp           │  │ • colorAttachments[]    │  │ • dstAccessMask      │
 │ • stencilLoadOp     │  │ • resolveAttachments[]  │  │ • dependencyFlags    │
 │ • stencilStoreOp    │  │ • depthStencilAttach    │  │                      │
 │ • initialLayout     │  │ • preserveAttachments[] │  └──────────────────────┘
 │ • finalLayout       │  │                         │
 │                     │  └────────────┬────────────┘
 └─────────────────────┘               │
                           ┌───────────┴────────────────────────────────┐
                           │                                            │
                           ▼                                            ▼
              ┌─────────────────────────┐              ┌─────────────────────────┐
              │ VkAttachmentReference   │              │ VkAttachmentReference   │
              │ (color / input /        │              │ (depthStencil)          │
              │  resolve / preserve)    │              │                         │
              │                         │              │ • attachment (index)    │
              │ • attachment (index)    │              │ • layout                │
              │ • layout                │              │   IMAGE_LAYOUT_DEPTH_   │
              │   IMAGE_LAYOUT_COLOR_   │              │   STENCIL_ATTACHMENT_   │
              │   ATTACHMENT_OPTIMAL    │              │   OPTIMAL               │
              └─────────────────────────┘              └─────────────────────────┘
```
Framebuffer, Subpasses.

```
                          ┌───────────────────────────────┐
                          │    vkCreateFramebuffer()      │
                          └───────────────┬───────────────┘
                                          │
                          ┌───────────────▼───────────────┐
                          │  VkFramebufferCreateInfo      │
                          └───────────────┬───────────────┘
                                          │
         ┌──────────┬─────────────┬───────┴───────┬──────────────┐
         │          │             │               │              │
         ▼          ▼             ▼               ▼              ▼
  ┌────────────┐ ┌────────┐ ┌──────────┐  ┌───────────┐  ┌───────────┐
  │ renderPass │ │ pAttach│ │  width   │  │  height   │  │  layers   │
  │ (VkRender  │ │ ments[]│ │          │  │           │  │           │
  │  Pass)     │ │        │ │          │  │           │  │           │
  └─────┬──────┘ └───┬────┘ └──────────┘  └───────────┘  └───────────┘
        │            │
        │            ▼
        │    ┌─────────────────────────────────────────────────────┐
        │    │ VkImageView[]  (attachmentCount)                    │
        │    │                                                     │
        │    │  ┌──────────────┐ ┌──────────────┐ ┌────────────┐   │
        │    │  │ ImageView 0  │ │ ImageView 1  │ │ ImageView N│   │
        │    │  │ (e.g. color) │ │ (e.g. depth) │ │ (...)      │   │
        │    │  └──────┬───────┘ └──────┬───────┘ └─────┬──────┘   │
        │    │         │                │               │          │
        │    └─────────┼────────────────┼───────────────┼──────────┘
        │              │                │               │
        │              ▼                ▼               ▼
        │    ┌─────────────────────────────────────────────────────┐
        │    │ VkImageView (each one wraps a VkImage)              │
        │    │                                                     │
        │    │  ┌───────────────────────────────────────────────┐  │
        │    │  │ VkImageViewCreateInfo                         │  │
        │    │  │                                               │  │
        │    │  │ • image        ──► VkImage                    │  │
        │    │  │ • viewType     ──► 2D / 2D_ARRAY / CUBE ...   │  │
        │    │  │ • format       ──► VK_FORMAT_*                │  │
        │    │  │ • components   ──► VkComponentMapping         │  │
        │    │  │                    (r, g, b, a swizzle)       │  │
        │    │  │ • subresourceRange                            │  │
        │    │  │     - aspectMask  (COLOR / DEPTH / STENCIL)   │  │
        │    │  │     - baseMipLevel                            │  │
        │    │  │     - levelCount                              │  │
        │    │  │     - baseArrayLayer                          │  │
        │    │  │     - layerCount                              │  │
        │    │  └───────────────────────────────────────────────┘  │
        │    └─────────────────────────────────────────────────────┘
        │
        │
        ▼
 ┌─────────────────────────────────────────────────────────────────────┐
 │ VkRenderPass  (must be compatible)                                  │
 │                                                                     │
 │  Attachment 0 ◄────────────────────────────── ImageView 0           │
 │  (format, samples, loadOp, storeOp...)        must match format     │
 │                                                & sample count       │
 │  Attachment 1 ◄────────────────────────────── ImageView 1           │
 │  (format, samples, loadOp, storeOp...)        must match format     │
 │                                                & sample count       │
 │  ...                                                                │
 │  Attachment N ◄────────────────────────────── ImageView N           │
 │                                                                     │
 └─────────────────────────────────────────────────────────────────────┘
 ```

### Synchronization + presenting


### Memory

Staging buffer. Allocation vs buffer.

## Why not Modern Vulkan?

Sascha Willems [How To Vulkan in 2026](https://www.howtovulkan.com/) showcases an example of modern Vulkan focusing on using those three extensions:
- Dynamic rendering - Greatly simplifies render pass setup, one of the most criticized Vulkan areas
- Buffer device address - Lets us access buffers via pointers instead of going through descriptors
- Descriptor indexing - Simplifies descriptor management, often referred to as "bindless"
- Synchronization2 - Improves synchronization handling, one of the hardest areas of Vulkan

Also Mason Remaley "It's Not About the API" [talk](https://gamesbymason.com/blog/2026/vulkan/) at Handmadecon describes those techniques (among others):
- Vertex Pulling
- Descriptor Indexing ~ bindless
- Draw indirect

In this blog post, I wanted to go into the detail all those extensions and techniques and also extend other very useful extensions that really simplify using Vulkan, but might also be less available depending on the platform and GPU. All this to try to think about how the Introduction to Computer Graphics course would look like if it included Vulkan.

However, one of big disadvantages of using modern Vulkan is the support on older hardware and on mobile platforms. All my students have fairly modern laptops (mostly Nvidia) and they never port their samples to mobile platforms like Android or the Switch, so it is fair to say that this is not really a concern of mine as a teacher.

My next computer graphics class is going to be in Decembre 2026, so I can also include extensions that just came out or are pretty recent if they can ease up the learning process of using Vulkan.

### Pipeline dynamic state
https://docs.vulkan.org/guide/latest/dynamic_state.html

Back-face culling quick toggle

[VK_EXT_extended_dynamic_state](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_extended_dynamic_state.html) allows culling mode, primitive topology (TRIANGLES, TRIANGLES_LIST, TRIANGLES_FAN), stencil and depth testing to be dynamically set per draw call (like OpenGL). 
[VK_EXT_extended_dynamic_state2](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_extended_dynamic_state2.html) and [VK_EXT_extended_dynamic_state3](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_extended_dynamic_state3.html) allows depth bias, blending to be dynamic. 
Those extensions exist to limit the number of Pipeline State Objects by avoid the replication of pipelines that have everything in common except blending or depth testing enable value.



### Dynamic rendering

In Vulkan 1.0, one of the painful part before the finish line to render the first triangle is going through the creation of `VkRenderpass`, `VkSubpass`, and `VkFramebuffer` to define the basic backbuffer that one could find in OpenGL. With [VK_KHR_dynamic_rendering](https://docs.vulkan.org/samples/latest/samples/extensions/dynamic_rendering/README.html), we get rid of render passes and framebuffers and simply gives the attachments this way:
```c++
const VkRenderingAttachmentInfoKHR color_attachment_info{
    .sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO_KHR,
    .imageView = swapchain.imageViews[imageIndex_], 
    .imageLayout = VK_IMAGE_LAYOUT_GENERAL,
    .loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
    .storeOp = VK_ATTACHMENT_STORE_OP_STORE,
    .clearValue = clearColor,
};

const VkRenderingAttachmentInfoKHR depth_attachment_info{
    .sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO_KHR,
    .imageView = swapchain.depthImageView, //depth buffer sitll have to be created by hand
    .imageLayout = VK_IMAGE_LAYOUT_GENERAL,
    .loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
    .storeOp = VK_ATTACHMENT_STORE_OP_DONT_CARE,
    .clearValue = clearDepth,
};

const VkRenderingInfoKHR render_info{
    .sType = VK_STRUCTURE_TYPE_RENDERING_INFO_KHR,
    .renderArea = VkRect2D{.offset = {0, 0}, .extent = swapchain.extent},
    .layerCount = 1,
    .colorAttachmentCount = 1,
    .pColorAttachments = &color_attachment_info,
    .pDepthAttachment = &depth_attachment_info,
};

vkCmdBeginRenderingKHR(commandBuffers_[imageIndex_], &render_info);
//... drawing
vkCmdEndRenderingKHR(commandBuffers_[imageIndex_]);
```

This greatly simplifies the rendering on the backbuffer, but what about multi pass rendering for techniques like shadow map, deferred rendering, post-processing? With [VK_KHR_dynamic_rendering_local_read](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_dynamic_rendering_local_read.html) using VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT allows an VkImage (for example the images in the deferred rendering G-Buffer) to be used both as attachment and with a sampler in the same rendering pass. This is even simplier than OpenGL framebuffer object approach where we bind the first framebuffer object with its attachments and then bind the backbuffer. Here is an example with a simple shadow pass and then a forward pass using the shadow map:

```
  vkCmdBeginRendering(&renderingInfo)
  │
  │
  ▼
 ┌──────────────────────────────────────────────────────────────────────┐
 │ PASS 1 — Depth Prepass                                               │
 │                                                                      │
 │  Locations:  { UNUSED }                                              │
 │  Inputs:     { UNUSED }   depth input: NONE                          │
 │                                                                      │
 │  Writes:                                                             │
 │   depth ──────────────────────────────────►  depth  ██               │
 │   (no color output)                          color  ░░               │
 │                                                                      │
 │  Pipeline:                                                           │
 │   depthWriteEnable  = TRUE                                           │
 │   depthCompareOp    = LESS                                           │
 │   colorWriteMask    = 0  (no color writes)                           │
 │                                                                      │
 │  vkCmdBindPipeline(depthPrepassPipeline)                             │
 │  vkCmdDrawIndexed(...)   ◄── all scene geometry                      │
 │                                                                      │
 └──────────────────────────────────────────────────────────────────────┘
  │
  ▼
 ┌──────────────────────────────────────────────────────────────────────┐
 │ BARRIER                                                              │
 │                                                                      │
 │  vkCmdPipelineBarrier2(VkMemoryBarrier2 {                            │
 │    srcStageMask:  EARLY_FRAGMENT_TESTS | LATE_FRAGMENT_TESTS         │
 │    srcAccessMask: DEPTH_STENCIL_ATTACHMENT_WRITE_BIT                 │
 │    dstStageMask:  FRAGMENT_SHADER_BIT                                │
 │    dstAccessMask: INPUT_ATTACHMENT_READ_BIT                          │
 │  })                                                                  │
 │                                                                      │
 │  No layout transition — stays RENDERING_LOCAL_READ_KHR               │
 │                                                                      │
 └──────────────────────────────────────────────────────────────────────┘
  │
  ▼
 ┌──────────────────────────────────────────────────────────────────────┐
 │ PASS 2 — Forward Shading (reads prepass depth)                       │
 │                                                                      │
 │  Locations:  { 0 }                                                   │
 │  Inputs:     { UNUSED }   depth input: 0                             │
 │                                                                      │
 │  Reads:                                                              │
 │   input_attachment_index=0  ◄────────────  depth  ▓▓                 │
 │                                                                      │
 │  Writes:                                                             │
 │   layout(location=0) outColor ───────────► color  ██                 │
 │                                                                      │
 │  Pipeline:                                                           │
 │   depthWriteEnable  = FALSE  (already filled)                        │
 │   depthCompareOp    = EQUAL  (only shade exact matches)              │
 │                                                                      │ 
 │  vkCmdBindPipeline(forwardPipeline)                                  │
 │  vkCmdDrawIndexed(...)   ◄── all scene geometry                      │
 │                                                                      │
 └──────────────────────────────────────────────────────────────────────┘
  │
  ▼
  vkCmdEndRendering()


 ┌──────────────────────────────────────────────────────────────────────┐
 │ ATTACHMENT STATE SUMMARY                                             │
 │                                                                      │
 │            Pass 1          Barrier        Pass 2                     │
 │          (Depth Pre)      ░░░░░░░░     (Forward)                     │
 │  ────────────────────────────────────────────────────                │
 │  color     ----           ░░░░░░░░       WRITE                       │
 │  depth     WRITE          ░░░░░░░░       READ (input + EQUAL test)   │
 │                                                                      │
 │  All layouts: RENDERING_LOCAL_READ_KHR throughout.                   │
 │  Single rendering scope — data stays on-tile (TBR GPUs).             │
 │                                                                      │
 └──────────────────────────────────────────────────────────────────────┘
```

### Shader object

In Vulkan 1.0, one of the more cumbersome part of the first sample "Hello Triangle" is to creation of the pipeline. But what if there is no need to create a pipeline in the first place? This is the goal of the [VK_EXT_shader_object ](https://docs.vulkan.org/samples/latest/samples/extensions/shader_object/README.html)

Creating a shader object looks like this:
```C++
VkShaderCreateInfoEXT createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_SHADER_CREATE_INFO_EXT;
createInfo.stage = stage; //vertex or fragment or compute
createInfo.nextStage = nextStage; // fragment if vertex, otherwise 0
createInfo.codeType = VK_SHADER_CODE_TYPE_SPIRV_EXT;
createInfo.codeSize = code.length;
createInfo.pCode = code.data;
createInfo.pName = "main";
createInfo.setLayoutCount = static_cast<uint32_t>(setLayouts.size());
createInfo.pSetLayouts = setLayouts.empty() ? nullptr : setLayouts.data();
createInfo.pushConstantRangeCount = static_cast<uint32_t>(pushConstantRanges.size());
createInfo.pPushConstantRanges = pushConstantRanges.empty() ? nullptr : pushConstantRanges.data();
```

Binding the shaders looks like this:
```c++
static constexpr std::array<VkShaderStageFlagBits, 2> stages = {
    VK_SHADER_STAGE_VERTEX_BIT,
    VK_SHADER_STAGE_FRAGMENT_BIT
};

std::array<VkShaderEXT, 2> shaders = {
    vertexShader_.GetHandle(),
    fragmentShader_.GetHandle()
};

vkCmdBindShadersEXT(cmd, 2, stages.data(), shaders.data());
```

It means that I only need to give the Descriptor Set Layout and the ranges of Push Constants, which is a great simplification compare to Vulkan 1.0 PSO bloat. It's even an improvement on OpenGL `glProgram` where we needed to remove the shader modules after creating the pipeline. What is great is also that it can be used with compute shader as well. The only exception is raytracing pipelines.

### Buffer Device Address

I first encounter BDA (Buffer Device Address) when playing with raytracing. I was always wondering how I could put all my meshes vertex input data and the materials with their associated textures in the same shader. For example here for my raytracing model sample:
```glsl

layout(buffer_reference, scalar) readonly buffer IndexBuffer {
    uint indices[];
};

layout(buffer_reference, scalar) readonly buffer TexCoordBuffer {
    vec2 texCoords[];
};

layout(buffer_reference, scalar) readonly buffer NormalBuffer {
    vec4 normals[];
};

struct MeshDescriptor {
    IndexBuffer indexBuffer;
    TexCoordBuffer texCoordBuffer;
    NormalBuffer normalBuffer;
    uint materialIndex;
    uint padding;
};

layout(binding = 3, set = 0, scalar) readonly buffer MeshDescriptorBuffer {
    MeshDescriptor meshDescriptors[];
};

```
`MeshDescriptor` refers to an index buffer, a texture coordinate buffer and a normal buffer through a BDA each. It also copied directly to memory from a CPU strucutre using `GL_EXT_scalar_block_layout`.

### Mesh Shader

Mesh optimizer

### Descriptor Heap

## Things to still take care of

While 

### Descriptor Sets + Push Constant

[VK_KHR_push_descriptor](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_push_descriptor.html)

[VK_EXT_descriptor_indexing](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html)

[Descriptor Heap](https://www.khronos.org/blog/simplifying-vulkan-one-subsystem-at-a-time)
### Synchronization

**Fences**

**Binary semaphores**

**Pipeline Barriers** 

In the middle of the module, we implement a simple OpenGL sample with a framebuffer drawing a scene and then applying some simple post-processing on it. In OpenGL, the synchronization between those pipelines is done through implicit ordering (first we do the scene pass, then the post-processing pass). However, in Vulkan, synchronization between those two passes needs to be done through a 
pipeline memory barriers. 

However, there are some extensions that makes live simple:
- [VK_KHR_unified_image_layouts](https://docs.vulkan.org/features/latest/features/proposals/VK_KHR_unified_image_layouts.html) allows the pipeline barriers to set VK_IMAGE_LAYOUT_GENERAL instead of the variations of image layouts


- [VK_KHR_synchronization2](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_synchronization2.html) bundles memory, buffer, and image barriers into a single structure passed to vkCmdPipelineBarrier2.

### Memory

Push constants, ubo and ssbo needs to align to std140 or std450 which has this weird requirements of having ```vec3``` being align at 16 bytes (instead of 4 bytes on the CPU). With [VK_EXT_scalar_block_layout](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_scalar_block_layout.html), it allows those non-scalar types to be aligned by their components. Actually, since Vulkan 1.4, this is no more an extension, nor optional, but required.

Uploading images with staging buffer -> use of [VK_EXT_host_image_copy](https://docs.vulkan.org/samples/latest/samples/extensions/host_image_copy/README.html).


## Next steps

I am not switching to Vulkan yet, but this retrospective pushed to look deeper into Vulkan and to try to implement several samples to prove my points. My current plan is to add Vulkan to my OpenGL ES course throughout the module. Most of my students work on mid-range gaming laptop with a discrete Nvidia or AMD card. If enough of the Vulkan setup is done, one can dream that a motivated one could do the same samples in Vulkan as the one in OpenGL. 

### Vulkan Bootstrap

### The extensions

This is the list of extensions that I use:
- `VK_EXT_scalar_block_layout` (required in Vulkan 1.4 anyway)
- `VK_KHR_unified_image_layouts`
- `VK_KHR_synchronization2`
- `VK_EXT_descriptor_heap`
- `VK_EXT_host_image_copy`
- `VK_KHR_dynamic_rendering` + `VK_KHR_dynamic_rendering_local_read`
- `VK_EXT_shader_object`

### Raytracing

Currently, the raytracing course is at the end of the computer graphics module, just showcasing some techniques used in AAA games and introducing what a future with pathtracing might look like. If my module gets updated with modern Vulkan, I don't see any reason to defer the teaching of hardware and to limit it to theory. Why not introduce raytracing earlier to implement simple techniques with ray query and then more advanced techniques in parallel of their full rasterize counterpart.

**Shadow**
Using ray query

**Simple reflections**


**Pathtracing**

PBR through pathtracing

When going to the Graphics Programming Conference ([blog post here]), I was in owe with the Pathtracing talk from idSoftware and Nvidia regarding the recently released Doom the Dark Ages. I sitll remember having my notebook and writing all the different techniques used in the game to allow for pathtracing at 60fps. 
SHaRC
SER
OMM