#version 330 core
layout (location = 0) in vec4 vertex; // xy is pos, zw are texture coords

out vec2 TextureCoords;

uniform mat4 mvp;

void main()
{
    gl_Position = mvp * vec4(vertex.xy, 0.0, 1.0);
    TextureCoords = vertex.zw;
}