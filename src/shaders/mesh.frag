#version 330 core

uniform int display_mode = 0;
uniform vec4 color; // rgba

in vec3 vertex_normal;

out vec4 out_color;

void main() {
    switch (display_mode) {
        case 0: {
            out_color = vec4(normalize(vertex_normal), 1.f) * .5f + .5f;
        } break;
        case 1: {
            out_color = color;
        } break;
    }
}