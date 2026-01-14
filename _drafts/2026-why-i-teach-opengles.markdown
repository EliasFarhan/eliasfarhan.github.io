---
layout: post
title:  "Why I still teach OpenGL ES 3.0"
categories: jekyll update
---

<div id="webgl-container" style="text-align: center; margin: 20px 0;">
  <canvas id="canvas" width="800" height="600" 
          style="border: 1px solid #000; background-color: #000;">
  </canvas>
  <div id="status" style="margin-top: 10px;">Loading...</div>
</div>
<script>
  // Lock the title
  const originalTitle = document.title;
  
  Object.defineProperty(document, 'title', {
    get: function() {
      return originalTitle;
    },
    set: function(newTitle) {
      // Ignore any attempts to change title
      console.log('Blocked title change to:', newTitle);
    }
  });
</script>
<script>
  var Module = {
    canvas: document.getElementById('canvas'),
    print: function(text) {
      console.log(text);
    },
    setStatus: function(text) {
      document.getElementById('status').innerText = text;
    },
    locateFile: function(path) {
      return '/assets/webgl/hello-transform/' + path;
    },
  };
</script>
<script async src="/assets/webgl/hello-transform/HelloTransform.js"></script>
<style>
  #canvas {
    width: 100% !important;
    height: auto !important;
    aspect-ratio: 4/3;
    display: block !important;
  }
</style>
<!--more-->
*Little C++ OpenGL ES 3.0 sample compiled to the web with emscripten*

## Introduction

It's been a few years that I have been giving this Introduction to Computer Graphics module (a trimester) at SAE Institute Geneva and I have always been wondering if and when I would need to transition my course from OpenGL to more modern API. 

Back in Novmeber, I was at the Graphics Programming Conference (my blog post [here](jekyll/update/2025/11/21/graphics_programming_conf.html)), and this subject reemerged for me during the conversations with people from the industry as well as from the talks. From the Teardown talk, the original game worked in OpenGL 3.3 and from the X-Plane talk, the rendering engine was using OpenGL 2.1. But both those talks were about how they transitionned to more modern API to have better graphics. 

Two talks really caught my attention about education for Computer Graphics: the talk _Bridging Pixels and Code: Teaching Computer Graphics to Technical Artists_ from Matthieu Delaere that focus on students creating their own rasterizer from scratch and the talk from Mike Shah that focuses on the next steps after the tutorial. The latter talk actually made me think about if the actual idea to do the transition to modern API for my course made still sense.

## The course content
The goal of the introduction in computer graphics module is for the students to implement a 3d scene with a graphics API. What is important to understand is that they should not implement a generic 3d renderer, but specifically a 3d scene, so the final executable is not supposed to be data-driven. For example, it would be completely ok to have such implementation:

```C++
void DrawScene(const Pipeline& pipeline, const Camera& camera)
{
  //Cull the scene from the camera

  //Draw each 3d object by hand

}
```

Since when I started to give this module, I have been following the [learnopengl.com](https://learnopengl.com/) structure with the variation of OpenGL ES 3.0 . Each chapter is like a list of samples that have to be implemented and tested.

But why specifically this version of OpenGL? OpenGL ES 3.0 is a mobile graphics API, released in August 2012, so about 14 years ago (which is a LONG time in computer graphics). I chose it because it is the most cross-platform version of OpenGL in my opinion, with this version you can run the same C++ program (with some #ifdef) and the same shaders for:
- Windows: while I encountered some driver issues throughout the year, OpenGL ES 3.0 is compatible with OpenGL 4.3, so I just assume OpenGL 4.3 on Windows not to worry.
- Linux: recently I had some issue with Wayland vs X working on some OpenGL tests, I need to dig deeper if there is any more issue (probably building SDL3 without the proper dependencies).
- Android: this one is a bit complicated as the actual android app boots from Java and calls the native lib containing the code.
- Nintendo Switch: we have two devkits at school and except removing glew or glad and replacing it with the embedding OpenGL wrapper, it works fine.
- WebGL2: my favorite reason of using OpenGL ES 3.0 is that it is mostly compatible with WebGL2 with emscripten (except float color attachment that is an extension...), which allows my students to port their samples to their own website/blog. It is the case with this blog post where I simply put the demo out of emscripten on the web page.
- Probably iOS or MacOSX: I did not try personally.

One of the hassles of the first course is having the students' laptop chooses the wrong GPU on laptop (using the Intel integrated GPU instead of the Nvidia GPU). Last year, you just needed to set the whole Nvidia configuration to be on "Performant" mode, but with a new Windows update, you need to set individually the application that is to be performant in the Windows settings, not the Nvidia settings anymore. Also, there is this trick for Windows:
```C++
#ifdef __cplusplus
extern "C" {
#endif

__declspec(dllexport) DWORD NvOptimusEnablement = 1;
__declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;

#ifdef __cplusplus
}
#endif
```
And this (supposedely) enables the discrete GPU and not the integrated one.

## Core concepts

When working on their samples, the students usually start to build their own abstraction. This year, we decided to work together and build the abstraction in a common git repository such that those abstraction could be used by all the students of the class as soon as it was implemented. 

### Pipeline

I really dislike OpenGL naming... Pipelines are called program, so when my students comes from learnopengl.com, they name their pipelines ```shaderProgram```. Anyway, we created an abstraction called ```Pipeline``` that loads with a vertex shader and a fragment shader (also a specific abstraction) that looks like this:

```C++
class Shader
{
public:
//shader target being GL_VERTEX_SHADER or GL_FRAGMENT_SHADER
    void Load(std::string_view path, GLenum shader_target); 
//[...]

class Pipeline
{
public:
    void Load(const Shader& vertex_shader, const Shader& fragment_shader);
//[...]
```
Shaders are "compiled" with *glslangValidator* that I configure with *CMake*. This allows to check for syntax errors during compile-time instead of seeing a weird error in the run-time compilation of the glsl shader by the driver. 

Because of OpenGL implementation of uniform buffer, we added a bunch of function to set those uniforms and to retrieve the uniform locations (and cache them for future retrieval):

```C++
class Pipeline
{
public:
    //[...]
    void SetInt(std::string_view uniform_name, int new_value);
    void SetFloat(std::string_view uniform_name, float new_value);
    template<typename T>
    requires core::IsVector3<T, float>
    void SetVec3(const std::string_view uniform_name, const T& v) {
        const GLint loc = GetUniformLocation(uniform_name);
        glUniform3f(loc, v.x, v.y, v.z);
    }
private:
    GLint GetUniformLocation(std::string_view name);
    std::unordered_map<std::string, GLint, StringHash, StringEqual> uniform_location_map_;
```
Several things to unpack here:
- ```SetVec3``` uses the concept ```IsVector3``` that check if the type has the three attributes x, y, z at the correct type. 
- ```StringHash``` and ```StringEqual``` allows the use of ```std::string_view``` without the need to create a ```std::string``` when trying to find a uniform location in the map.


### Vertex inputs

**Replace with Buffer abstraction + Vertex Input abstraction**

One of the weird thing for me going into OpenGL is how memory is allocated (the glGen*, glBind*, and then upload the data and probably uplaod at the same time). For example, for a vertex input buffer, an index buffer:

```C++
int vbo_;
glGenBuffers(vboCount, &vbo_);
glBindBuffer(GL_ARRAY_BUFFER, vbo_);
glBufferData(GL_ARRAY_BUFFER, vertex_buffer.size, vertex_buffer.data, GL_STATIC_DRAW);

int ebo_;
glGenBuffers(vboCount, &ebo_);
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo_);
glBufferData(GL_ELEMENT_ARRAY_BUFFER, index_buffer.size, index_buffer.data, GL_STATIC_DRAW);
```

For vertex inputs, you have those buffers that are to be setup in a Vertex Array Object, sort of like a container of vertex buffers, to define how the pipeline is going to read the vertex buffers, with something like this:

```C++
int vao_;
glGenVertexArrays(1, &vao_);
glBindVertexArray(vao_);

glBindBuffer(GL_ARRAY_BUFFER, vbo_);

glVertexAttribPointer(
  vertex_input_location, // in the shader (location = 0) 
  vertexAttribData.size, // how many of the primitive: float => 1, vec2 => 2, vec3 => 3, vec4 => 4
  vertexAttribData.type,
  GL_FALSE,
		vertexAttribData.stride,
		(void*)vertexAttribData.offset);
glEnableVertexAttribArray(vertexAttribData.index);

```

Vertex Input becomes even more important when we want to give a buffer while using instancing (for example giving the model matrix of our models through vertex input). I usually let the students find their abstractions for VAO, VBO, EBO and instancing buffers, as they have to implement model loading as well. But this would look like this:
```C++
//init instancing buffer object
int ibo_;
glGenBuffers(1, &ibo_);
glBindBuffer(GL_ARRAY_BUFFER, ibo_);
glBufferData(GL_ARRAY_BUFFER, instancing_buffer.size, instancing_buffer.data, GL_STATIC_DRAW);

//link instancing buffer object to vao
glVertexAttribPointer(
  instancing_input_location, // in the shader (location = 0) 
  instancingAttribData.size, // how many of the primitive: float => 1, vec2 => 2, vec3 => 3, vec4 => 4
  instancingAttribData.type,
  GL_FALSE,
	instancingAttribData.stride,
  (void*)instancingAttribData.offset);
glEnableVertexAttribArray(instancingAttribData.index);
glVertexAttribDivisor(instancing_input_location, 1);
```
The divisor thingy is confusing, but it means that we give the value of the instancing buffer per instance and not per vertex.

### Textures

The logic for texture in OpenGL is counter-intuitive. One has to understand the difference between texture name (the handle given by ```glGenTextures```) and the texture unit (```GL_TEXTURE0``` for example). It confuses a lot of my students each year. So binding a texture to a uniform sample looks like this:
```C++
glUniform1i(uniform_location, 0);
glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE2D, my_texture);
```
This is put in a function in the pipeline to look this:
```C++
pipeline_.SetTexture("uniform_name", my_texture, 0);

//with implementation looking like this:
void Pipeline::SetTexture(std::string_view uniform_name, const Texture& texture, int texture_unit)
{
    const auto uniformLocation = GetUniformLocation(uniformName);
    glUniform1i(uniformLocation, textureUnit);
    glActiveTexture(GL_TEXTURE0 + textureUnit);
    texture.Bind(); 
}
```

For loading, in the beginning of the module, we start with [*stb_image*](https://github.com/nothings/stb) to load JPG, PNG, BMP, etc... This header-only library decompresses the images such that we can upload them to the GPU, something that looks like this:
```C++
image.pixels = stbi_load(imagePath.data(), &image.width, &image.height, &image.comp, 0);
	
glGenTextures(1, &my_texture);
glBindTexture(GL_TEXTURE2D, name_);
switch (image.comp)
	{
	case 3:
		glTexImage2D(GL_TEXTURE2D, 
      0, GL_RGB, image.width, image.height, 
      0, GL_RGB, GL_UNSIGNED_BYTE, image.pixels);
		break;
	case 4:
		glTexImage2D(GL_TEXTURE2D, 
      0, GL_RGBA, image.width, image.height, 
      0, GL_RGBA, GL_UNSIGNED_BYTE, image.pixels);
		break;
	default:
		break;
	}
```
All this is course hidden in a ```Texture``` abstraction with ```Load``` and ```Bind```. Then for cubemaps, we add:
```C++
class Texture
{
  public:
  //[...]
  void LoadCubemaps(std::span<const std::string_view, 6> paths);
}
```
The ```Texture``` holds the "target" (```GL_TEXTURE2D``` or ```GL_TEXTURE_CUBE_MAP```, why not texture3d?) and then the ```Bind``` will bind the correct target.

### Draw commands

In OpenGL, the driver is adding our commands into its own command buffer. This forbids multi-threading draw commands generation (compare to more modern API) and it gives this feeling that drawing happens immediately. Because of learnopengl.com, most of my students put their draw call in the ```Mesh``` contained in their ```Model```. So it looks like this:
```C++
void Model::Draw(const Pipeline& pipeline)
{
  pipeline.Bind();
  for(auto& mesh: meshes)
  {
    mesh.Draw(pipeline);
  }
}

void Mesh::Draw(const Pipeline& pipeline)
{
  material_.Bind(pipeline); //binding all textures to their samples
  glDrawElements(GL_TRIANGLES, indices_count, GL_UNSIGNED_INT, nullptr);
  //or depending on the abstraction
  vao_.Draw();
}

```
After working on my computer graphics editor (I wrote a blog post [here](/jekyll/update/2023/11/29/compgrapheditorv1.html)), I really prefer a separated approach where a scene has materials (pipeline + texture reference) and meshes, and that models do not exist as scene abstraction. However again, it is not about making a data-driven renderer, but just implement a 3d scene.

### Dynamic states

In OpenGL, pipeline states (depth-stencil, back-face culling, blending) are all mostly dynamic and can be changed with a line, for example:
```C++
glEnable(GL_DEPTH_TEST);
glDepthFunc(GL_LESS);

glEnable(GL_CULL_FACE);
glCullFace(GL_BACK);
glFrontFace(GL_CCW);

glEnable(GL_BLEND);
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

glEnable(GL_STENCIL_TEST);
glStencilFunc(GLenum func,GLint ref,GLuint mask);
glStencilOp(GLenum sfail, GLenum dpfail, GLenum dppass);
glStencilMask(GLuint mask);
```

### Render passes & Framebuffer

**Framebuffer abstraction**

Finally, the last big OpenGL core concept is about multi passes. The first half of the module is spent in one pass. Post-processing is the first example of multi-pass, where my students have to use a framebuffer to draw their scene, and then use another pipeline and the render targets as a sampled texture. The first example is several variations of post-processing (like grayscale, inversing the color). Setting a certain framebuffer in OpenGL is starting a new render pass (RenderDoc will usually write it as Color Pass). Defining the framebuffer with a texture color attachment would look like this:

```C++
glGenFramebuffers(1, &fbo_);
//[...] Create the texture

glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorBuffer_, 0);
```

The depth-stencil buffer in this case is setup as a RBO (render buffer object, yet another type of buffers), sort of like a GPU only kind of resource. This will look like this:

```C++
glGenRenderbuffers(1, &depthRbo_);
glBindRenderbuffer(GL_RENDERBUFFER, depthRbo_);
glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, size_.x, size_.y);
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRbo_);

```
For the shadow pass, we usually want depth-only pass and those are setup this was:
```C++
//No draw setup
GLenum drawBuffers = GL_NONE;
glDrawBuffers(1, &drawBuffers);
glReadBuffer(GL_NONE);

```
The fragment shader of the depth-only pass would look like this (linearizing the depth by setting explicitely the ```gl_FragDepth```):
```glsl
#version 300 es
precision highp float;

out vec4 FragColor;

void main()
{
    gl_FragDepth = gl_FragCoord.z;
    FragColor = vec4(0,0,0,1);
}
```

A big step in using framebuffer in the module comes with the introduction to HDR (High-Dynamic Range), basically the fact that we can use color in a bigger range than [0 - 255]. One of such applications is deferred rendering and the creation of G-Buffer (Geometry Buffer) to minimize the amount of lighting calculation per pixel. So first, you render a color pass on a G-Buffer with several color attachments each containing important geometry value (position, normal, base color) and then there is a light pass where lighting is calculated per pixel. This technique see a huge performance improvement when drawing a lot of lights on the screen.

Of course, not all monitor outputs HDR, so we need a way to go back to LDR (Low-Dynamic Range, [0 - 255]) and this is done at the end of the lighting pass fragment shader:
```glsl
//Reinhard tonemapping
vec3 result = lighting / (lighting + vec3(1.0));
FragColor = vec4(result, 1.0);
```

## Missing modern OpenGL features in ES 3.0

Using OpenGL ES 3.0 (to allow use of WebGL 2.0) has still a cost though. Some core concepts of modern rendering are explained in course content but not implemented (except if the students want to get rid of WebGL2 compatibility).

### SSBO

As of OpenGL 4.3 and OpenGL 3.1, we can define shader storage buffer object. This is useful to remove the need to pass by the vertex inputs when doing instancing. Of course, we need to had another type of buffer that can be binded to an uniform. This would look like this:
```C++
//in C++
glGenBuffers(1, &ssbo_);
glBindBuffer(GL_SHADER_STORAGE_BUFFER, ssbo_);
glBufferData(GL_SHADER_STORAGE_BUFFER, instancing_buffer.size, instancing_buffer.data, GL_DYNAMIC_DRAW);
glBindBufferBase(GL_SHADER_STORAGE_BUFFER, binding_point, ssbo);

//in shader
layout(std430, binding = 3) buffer layoutName
{
    vec4 data_SSBO[];
};

void main()
{
  vec4 instancing_data = data_SSBO[gl_InstanceID];
}
```

### Compute shader
Compute shader only appeared in OpenGL ES 3.1 (so not WebGL2). Coming back to the post-processing example explained before, instead of giving the color attachment of the scene as a ```sampler2D```, we could give it as an ```image2D``` and actually do the post-processing in compute. Typically, every the-whole-screen kind of shader are easier to implement with a compute pipeline with a single shader, rather than a graphics pipeline with a plane in NDC (Normal Device Coordinate) going from [-1, 1] just to recover the whole screen in the vertex shader and implementing the transformation in the fragment shader.

### SPIR-V

Starting with OpenGL 4.6 (not even available in OpenGL ES 3.2), we can load SPIR-V instead of plain text GLSL. This allow for quick loading of shader as the format is binary and it allows to add a compilation step to shaders (something we sort of do anyway with glslandValidator).

### Bindless 



## Missing features from Modern API
Sticking with OpenGL means also mssing a lot about newer features of modern API like Vulkan and DX12.

### Raytracing
With all their marketing on RTX, Nvidia surely brought raytracing in every gamer's mouth when talking about computer graphics. Of course, raytracing exists since before the advent of graphics card. However in 2018, DXR was released, allowing for hardware raytracing on the GPU using new kind of shaders (closest-hit, miss, raygen, etc...) and Vulkan followed with the Nvidia extension and then the generic extension. 

Most games are still living in a hybrid rendering world where some parts are done in rasterization and some are done in raytracing, with custom options for players. In its [State of GPU Hardware](https://asawicki.info/articles/state_of_gpu_hardware_2025.php), Dmytro “Boolka” Bulatov mentions that only games like *Indiana Jones and the Great Circle* (released in late 2024) that puts DXR as a requirement. So for me, as a teacher, I still showcase the hardware raytracing API, its advantages and disadvantages, and how the future looks like, but as it is an introduction to computer graphics, I can't ask all my students to have to implement a hardware raytracing pipeline.

### Multithreaded rendering
When thinking about modern CPU architecture, we are living in a multi-core world now, but most of what we program in games is still happening in one thread on one core. To truly unlock the power of our CPU, we can divide our work between several threads. A common pattern is to have a threading model with Game/Cull/Render on the CPU, or having the loading done async and those still work with OpenGL. 

However, certain games (like [Halo Infinite](https://www.youtube.com/watch?v=IUiNUky-ibM)) require the use of multiple threads to generate all the GPU commands. This is definitely possible with DX12 and Vulkan, but not in OpenGL where the render states are in the driver implementation in one thread.

## The results

Here are some of the works of my students during this module over the years:
- [Fabian Huber](https://blog.stowy.ch/posts/how-i-implemented-a-deferred-pbr-renderer-in-opengl/)
- [Samuel Styles](https://sstyles93.github.io/projects/openglscene/)
- [Olivier Pachoud](https://chocolive24.github.io/blog/how-i-created-an-opengl-3d-scene/)
- [Constantin Verine](https://cochta.github.io/work/nested/renderer)
- [Remy Lambert](https://remlamb.github.io/3d_scene/scene.html)
- [Maxime Roch](https://mebearwhodis.github.io/projects/opengl-renderer)

## Conclusion

OpenGL ES 3.0 has still a lot of advantages to be teached even in 2026 (especially WebGL2), at the cost of going through the struggle of the legacy of this API. 14 years is a lot of time in Computer Graphics. I want to write another blog post about why we are not yet switching to Vulkan. 


