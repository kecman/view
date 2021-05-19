#version 330 core


uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iTime;                 // shader playback time (in seconds)
// uniform float     iTimeDelta;            // render time (in seconds)
// uniform int       iFrame;                // shader playback frame
// uniform float     iChannelTime[4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
// uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
// uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
// uniform vec4      iDate;                 // (year, month, day, time in seconds)
// uniform float     iSampleRate;           // sound sample rate (i.e., 44100)

const float gradient  = 1.0;
const float intensity = 8.0;
const float PI = 3.1415926535897932;
float gaussian( in vec2 p )
{
  float denom = gradient * gradient * 2.0;
  float val1 = 1.0 / (denom * PI);
  float val2 = exp(-dot(p, p) / denom);
  return val1 * val2;
}

float smooth_step( float edge0, float edge1, float x )
{
    float p = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    float v = p * p * (3.0 - 2.0 * p); // smoothstep formula
    
    //v = smoothstep( edge0, edge1, x ); // Compare with built-in
    
    return v;
}

// Paste a shader toy here!
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
    // vec3 col = vec3(0, 0, 1);
    vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));


    vec2  p = uv * 2.0 - 1.0;
    float t = intensity * gaussian(.8 * p);
    col = mix(vec3(1.0), col, 1.0 - t);
    col = min(vec3(1.0), col);

    // "Make it grey-er"
    // col = mix(col, vec3(0), .4);


    // col = smoothstep(vec3(1), col, vec3(min(.99, length(p))));
    // col = mix(vec3(1), col, min(1, pow(length(p), 16)));
    // col = mix(col, vec3(1), 0);

    // Output to screen
    fragColor = vec4(col,1.0);
}

out vec4 fragColor;


void main() {
    mainImage(fragColor, gl_FragCoord.xy);
    // // Normalized pixel coordinates (from 0 to 1)
    // vec2 uv = fragCoord/iResolution.xy;

    // // Time varying pixel color
    // vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));

    // // Output to screen
    // fragColor = vec4(col,1.0);
    // // out_color = vec4(1, 1, 1, 1);
}