#version 330 core

struct Camera {
    vec3 eye_position;
};

uniform Camera camera;
uniform int display_mode = 0;
uniform vec4 color; // rgba

in vec3 vertex_normal_ws;
in vec3 fragment_position_ws;

out vec4 out_color; // @Cleanup: just use gl_Frag_Color?

struct Directional_Light {
    vec3  direction;
    vec3  color;
    float power;
};

struct Point_Light {
    vec3  position;
    vec3  color;
    float power;
};

const int POINT_LIGHT_COUNT = 4;
Point_Light point_lights[POINT_LIGHT_COUNT] = Point_Light[POINT_LIGHT_COUNT](
    Point_Light(vec3( 500,  500,  500), vec3(1), .1),
    Point_Light(vec3(-500, -500,  250), vec3(1), .1),
    Point_Light(vec3( 250, -500, -500), vec3(1), .1),
    Point_Light(vec3(   0,  500, -500), vec3(1), .1)
);

const int DIRECTIONAL_LIGHT_COUNT = 1;
Directional_Light directional_lights[DIRECTIONAL_LIGHT_COUNT] = Directional_Light[DIRECTIONAL_LIGHT_COUNT](
    Directional_Light(vec3(0,  0,  1), vec3(1), .2)
);

vec3 ambient_color   = .1 * color.xyz;
vec3 diffuse_color   = color.xyz;
vec3 specular_color  = vec3(1.0);
float shininess      = 16.;
float gamma          = 2.2;


vec3 blinn_phong_brdf(vec3 N, vec3 V, vec3 L, vec3 light_color, float light_power) {
    float n_dot_l = clamp(dot(N, L), 0., 1.);

    float specular = 0;
    if (n_dot_l > 0.) {
        vec3 H = normalize(V + L);
        float n_dot_h = clamp(dot(N, H), 0., 1.);
        specular = pow(n_dot_h, shininess);
    }

    return ambient_color + light_color * light_power * (diffuse_color * n_dot_l + specular_color * specular);
}

void main() {
    vec3 N = normalize(vertex_normal_ws);

    switch (display_mode) {
        case 0: { // normal shading

            out_color = vec4(N, 1.f) * .5f + .5f;

        } break;
        case 1: { // solid color

            out_color = color;

        } break;
        case 2: { // blinn-phong shading

            vec4 color_linear = vec4(0, 0, 0, 1);

            vec3 V = normalize(camera.eye_position - fragment_position_ws);

            for (int light_index = 0; light_index < DIRECTIONAL_LIGHT_COUNT; ++light_index) {
                Directional_Light light = directional_lights[light_index];
                vec3 L = normalize(-light.direction);
                color_linear.xyz += blinn_phong_brdf(N, V, L, light.color, light.power);
            }

            for (int light_index = 0; light_index < POINT_LIGHT_COUNT; ++light_index) {
                Point_Light light = point_lights[light_index];
                vec3 L = normalize(light.position - fragment_position_ws);
                color_linear.xyz += blinn_phong_brdf(N, V, L, light.color, light.power);
            }

            vec4 color_gamma_corrected = vec4(pow(color_linear.xyz, vec3(1./gamma)), 1);
            // out_color = color_linear;
            out_color = color_gamma_corrected;

        } break;
    }
}