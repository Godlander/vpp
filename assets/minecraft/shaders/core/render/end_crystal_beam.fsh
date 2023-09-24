#version 330
#define FSH

#moj_import <utils.glsl>
#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in vec2 texCoord0;
in float fogDistance;
in vec4 vertexColor;
in vec4 lightColor;
in vec4 overlayColor;
in vec4 glpos;

out vec4 fragColor;

void main() {
    discard_control_glpos(gl_FragCoord.xy, glpos);

    vec4 color = texture(Sampler0, texCoord0);
    if (color.a < 0.1) discard;
    color *= vertexColor * ColorModulator;
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightColor;
    fragColor = linear_fog(color, fogDistance, FogStart, FogEnd, FogColor);
}