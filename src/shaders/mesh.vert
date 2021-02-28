#version 330 core

layout (location = 0) in vec3 vertex;

uniform mat4 world_from_model;
uniform mat4 view_from_world;
uniform mat4 projection_from_view;
uniform float point_size;

void main() {
    mat4 projection_from_model = projection_from_view * view_from_world * world_from_model;
    gl_Position = projection_from_model * vec4(vertex, 1.f);
    gl_PointSize = point_size;
}