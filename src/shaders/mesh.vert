#version 330 core

layout (location = 0) in vec3 in_vertex;
layout (location = 1) in vec3 in_normal;

uniform mat4 world_from_model;
uniform mat4 view_from_world;
uniform mat4 projection_from_view;
uniform float point_size;

out vec3 vertex_normal;

void main() {
    mat4 projection_from_model = projection_from_view * view_from_world * world_from_model;

    vertex_normal = (transpose(inverse(world_from_model)) * vec4(in_normal, 0.f)).xyz;

    gl_Position = projection_from_model * vec4(in_vertex, 1.f);
    gl_PointSize = point_size;
}