#version 330
#define FSH

#moj_import <fog.glsl>
#moj_import <utils.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in vec2 texCoord0;
in float fogDistance;
in vec4 vertexColor;
in vec3 normal;
in float yval;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    color *= vertexColor * ColorModulator * vec4(1,1,1,0.8);
    color.rgb = mix(color.rgb, FogColor.rgb * FogColor.rgb, 0.5 * (1.0 - yval));
    if (color.a < 0.1) {
        discard;
    }
    fragColor = linear_fog(color, fogDistance, FogStart, FogEnd, FogColor);
}