#version 330 core

layout (triangles) in;
layout (line_strip, max_vertices = 6) out;

in VERTEX_SHADER_OUT {
    vec3 normal;
} geom_in[];

uniform mat4 clip_from_view;

const float NORMAL_LENGTH = 1.;

// @TODO Make the tip more obvious, maybe with an arrow head
void normal_segment(int index) {
    vec4 base = gl_in[index].gl_Position;
    vec4 tip = base + vec4(geom_in[index].normal, 0.) * NORMAL_LENGTH;

    gl_Position = clip_from_view * base;
    EmitVertex();
    gl_Position = clip_from_view * tip;
    EmitVertex();
    EndPrimitive();
}

void main() {
    normal_segment(0);
    normal_segment(1);
    normal_segment(2);
}