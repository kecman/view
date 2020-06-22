#version 330 core

uniform vec4 line_color; // rgba

out vec4 color;

void main () {
    color = line_color;
}