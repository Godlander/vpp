#version 330
#define FSH

#moj_import <utils.glsl>
#moj_import <fog.glsl>

uniform mat4 ProjMat;
uniform vec4 ColorModulator;
uniform vec2 ScreenSize;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in vec4 vertexColor;
in float fogDistance;

out vec4 fragColor;

void main() {
    if (!is_gui(ProjMat)) discard_control(gl_FragCoord.xy, ScreenSize.x);

    vec4 color = vertexColor;
    if (color.a == 0.0) discard;
    color = color * ColorModulator;
    fragColor = linear_fog(color, fogDistance, FogStart, FogEnd, FogColor);
}