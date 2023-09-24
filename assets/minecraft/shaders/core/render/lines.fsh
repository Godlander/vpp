#version 330
#define FSH

#moj_import <utils.glsl>
#moj_import <fog.glsl>

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float fogDistance;
in vec4 vertexColor;
in vec4 glpos;

out vec4 fragColor;

void main() {
    discard_control_glpos(gl_FragCoord.xy, glpos);

    vec4 color = vertexColor * ColorModulator;
    fragColor = linear_fog(color, fogDistance, FogStart, FogEnd, FogColor);
}