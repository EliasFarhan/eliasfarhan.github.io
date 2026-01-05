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
Since when I started to give Computer Graphics courses, I have been following the [learnopengl.com](https://learnopengl.com/) structure with the variation of OpenGL ES 3.0. But why specifically this version? Because it is the most cross-platform version of OpenGL for me, with this version you can run the same C++ program (with some caveats) and the same shaders for:
- Windows: while I encountered some driver issues throughout the year, OpenGL ES 3.0 is compatible with OpenGL 4.3, so I just assume OpenGL 4.3 on Windows not to worry.
- Linux: recently I had some issue with Wayland vs X working on some OpenGL tests, I need to dig deeper if there is any more issue (probably building SDL3 without the proper dependencies).
- Android: this one is a bit complicated as the actual android app boots from Java and calls the native lib containing the code.
- Nintendo Switch: we have two devkits at school and except removing glew or glad and replacing it with the embedding OpenGL wrapper, it works fine.
- WebGL2: my favorite reason of using OpenGL ES 3.0 is that it is mostly compatible with WebGL2 with emscripten (except float color attachment that is an extension...), which allows my students to port their samples to their own website/blog.
- Probably iOS or MacOSX: I did not try personally.

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
[...]

class Pipeline
{
public:
    void Load(const Shader& vertex_shader, const Shader& fragment_shader);
[...]
```

Because of OpenGL implementation of uniform buffer, we added a bunch of function to set those uniforms and to retrieve the uniform locations (and cache them for future retrieval):

```C++
class Pipeline
{
public:
    [...]
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

One of the weird thing for me going into OpenGL is how memory is allocated. For example, for a vertex input buffer, an index buffer:

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
### Textures

stb_image

### Draw commands

### Render passes & Framebuffer

## Missing modern OpenGL in ES 3.0

The cost of using OpenGL ES 3.0 (to allow use of WebGL 2.0) has still a cost though.
### SSBO

Of course, we need to had another type of buffer that can be binded to an uniform. 

### Compute shader

### Other abstractions

## Conclusion


