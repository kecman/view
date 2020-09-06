#version 330 core

uniform vec4 shape_colour; // rgba

out vec4 colour;

void main() {
    colour = shape_colour;
}