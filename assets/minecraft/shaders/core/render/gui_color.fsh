#version 150

uniform vec4 ColorModulator;

in vec4 vertexColor;
in vec3 pos1;
in vec3 pos2;
in vec3 pos3;

out vec4 fragColor;

void main() {
    vec2 p1 = pos1.xy / pos1.z;
    vec2 p2 = pos2.xy / pos2.z;
    vec2 p3 = pos3.xy / pos3.z;
    vec2 minp = min(p1, min(p2, p3));
    vec2 maxp = max(p1, max(p2, p3));
    ivec2 size = ivec2(round(abs((minp - maxp))));
    if (size == clamp(size, ivec2(79,12), ivec2(81,14)) && vertexColor.r == vertexColor.g && vertexColor.r == vertexColor.b) {
        discard;
    }
    vec4 color = vertexColor;
    if (color.a == 0.0) {
        discard;
    }
    fragColor = color * ColorModulator;
}
