#version 150

#moj_import <fog.glsl>
#moj_import <utils.glsl>

uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
flat in vec4 vertexColor;
in vec4 glpos;

out vec4 fragColor;

void main() {
    discardControlGLPos(gl_FragCoord.xy, glpos);
    if (vertexColor.a == 0.0) {discard;}
    fragColor = linear_fog(vertexColor, vertexDistance, FogStart, FogEnd, FogColor);
}
