#version 330 core

layout (location = 0) in vec3 vertex;

uniform mat4 mvp;
uniform float point_size;

void main() {
    gl_Position = mvp * vec4(vertex, 1.f);
    gl_PointSize = point_size;
}