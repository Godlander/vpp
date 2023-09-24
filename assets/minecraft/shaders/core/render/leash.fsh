#version 330
#define FSH

#moj_import <utils.glsl>
#moj_import <fog.glsl>

uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float fogDistance;
flat in vec4 vertexColor;
in vec4 glpos;

out vec4 fragColor;

void main() {
    discard_control_glpos(gl_FragCoord.xy, glpos);

    fragColor = linear_fog(vertexColor, fogDistance, FogStart, FogEnd, FogColor);
}