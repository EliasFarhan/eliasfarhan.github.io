---
layout: post
title:  "Why I am not teaching Vulkan"
categories: jekyll update
---
<!--more-->
## Introduction

I made a blog post about why I am still teaching OpenGL ES 3.0 in 2025-2026 in my introduction to Computer Graphics course at SAE Institute [here](/jekyll/update/2026/01/27/why-i-teach-opengles.html), now let's talk about why I am not teaching Vulkan yet. 

How about a [Vulkan Rendering Hardware Interface](https://uaasoftware.bitbucket.io/vrhi.html)

## Vulkan 1.0

The portability (Switch, Android, Windows, Linux). 

On Android (from [here](https://developer.android.com/about/dashboards) as of Jan 7th 2025):
- Vulkan 1.0.3	3.86%
- Vulkan 1.1	62.09%
- Vulkan 1.3	26.01%
- Vulkan 1.4	0.67%

### The mental load

I still remember going through the Vulkan tutorial the first time. Just to render a triangle, one has to interact with:
- VkInstance (created with VkInstanceCreateInfo )
- VkPhysicalDevice (queried with vkEnumeratePhysicalDevices) and keep queue family indices
- VkDevice (created with VkDeviceCreateInfo using the VkPhysicalDevice)
- VkSurfaceKHR (created using SDL)
- VkQueue (created using VkDeviceQueueCreateInfo)
- VkSwapchainKHR and retrieving all its VkImage and generates their VkImageView
Verbosity, so many different concepts for a triangle.
- VkShaderModule (created in a similar way than OpenGL but loading SPIR-V files instead of GLSL)
- VkRenderpass with its VkAttachmentDescription, VkSubpass 
- VkPipeline created using:
    - VkPipelineShaderStageCreateInfo 
    - VkPipelineDynamicStateCreateInfo
    - VkPipelineVertexInputStateCreateInfo
    - VkPipelineInputAssemblyStateCreateInfo
    - VkPipelineViewportStateCreateInfo using VkViewport and VkRect2D scissor
    - VkPipelineRasterizationStateCreateInfo 
    - VkPipelineMultisampleStateCreateInfo
    - VkPipelineColorBlendStateCreateInfo using VkPipelineColorBlendAttachmentState
    - VkPipelineLayout
    -> needed the renderpass created before as well with the subpass index
- VkFramebuffer created with VkFramebufferCreateInfo  using the VkImageView attachments and the renderpass
- VkCommandBuffer created with VkCommandBufferAllocateInfo from a VkCommandPool created using vkCreateCommandPool 

All that to record the draw call of our hello world triangle in a command buffer and give it to the queue. 

### Pipeline State Object (PSO)


### Render pass 
Framebuffer, Subpasses.

### Synchronization + presenting


### Memory

Staging buffer

## Modern Vulkan?

Sascha Willems [How To Vulkan in 2026](https://www.howtovulkan.com/) showcases an example of modern Vulkan focusing on using those three extensions:
- Dynamic rendering - Greatly simplifies render pass setup, one of the most criticized Vulkan areas
- Buffer device address - Lets us access buffers via pointers instead of going through descriptors
- Descriptor indexing - Simplifies descriptor management, often referred to as "bindless"
- Synchronization2 - Improves synchronization handling, one of the hardest areas of Vulkan

Also Mason Remaley: https://gamesbymason.com/blog/2026/vulkan/ describes:
- Vertex Pulling
- Descriptor Indexing ~ bindless
- Draw indirect

In this blog post, I wanted to go into the detail all those extensions and techniques and also extend other very useful extensions that really simplify using Vulkan, but might also be less available depending on the platform and GPU. All this to try to think about how the Introduction to Computer Graphics course would look like if it included Vulkan.

### Pipeline dynamic state
https://docs.vulkan.org/guide/latest/dynamic_state.html

### Dynamic rendering

In Vulkan 1.0, one of the painful part before the finish line to render the first triangle is going through the creation of VkRenderpass, VkSubpass, and VkFramebuffer to define the basic backbuffer that one could find in OpenGL. With [VK_KHR_dynamic_rendering](https://docs.vulkan.org/samples/latest/samples/extensions/dynamic_rendering/README.html), we get rid of render passes and framebuffers and simply gives the attachments this way:
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

This greatly simplifies the rendering on the backbuffer, but what about multi pass rendering for techniques like shadow map, deferred rendering, post-processing? With [VK_KHR_dynamic_rendering_local_read](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_dynamic_rendering_local_read.html) using VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT allows an VkImage (for example the images in the deferred rendering G-Buffer) to be used both as attachment and with a sampler in the same rendering pass. This is even simplier than OpenGL framebuffer object approach where we bind the first framebuffer object with its attachments and then bind the backbuffer. 

### Shader object

In Vulkan 1.0, one of the more cumbersome part of the first sample "Hello Triangle" is to creation of the pipeline. But what if there is no need to create a pipeline in the first place? This is the goal of the [VK_EXT_shader object](https://docs.vulkan.org/samples/latest/samples/extensions/shader_object/README.html)

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

### Buffer Device Address

### Mesh Shader

## The reason why not

### Descriptor Sets + Push Constant

[VK_KHR_push_descriptor](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_push_descriptor.html)

[VK_EXT_descriptor_indexing](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_descriptor_indexing.html)

Descriptor Heap https://www.khronos.org/blog/simplifying-vulkan-one-subsystem-at-a-time
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