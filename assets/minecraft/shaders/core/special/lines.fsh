#version 150

#moj_import <fog.glsl>
#moj_import <utils.glsl>

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec4 glpos;

out vec4 fragColor;

void main() {
    discardControlGLPos(gl_FragCoord.xy, glpos);
    vec4 color = vertexColor * ColorModulator;

    if (color.a < 0.02) {
        float cycle = sin(GameTime * 6000) * 0.5 + 0.5;
        color = vec4(0, 0, 0, (cycle + 1) / 4);
    }

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
