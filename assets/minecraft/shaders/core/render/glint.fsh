#version 330
#define FSH

#moj_import <utils.glsl>
#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform float GlintAlpha;

in float fogDistance;
in vec2 texCoord0;
in vec4 glpos;

out vec4 fragColor;

void main() {
    discard_control_glpos(gl_FragCoord.xy, glpos);

    vec4 color = texture(Sampler0, texCoord0) * ColorModulator;
    if (color.a < 0.1) discard;
    float fade = linear_fog_fade(fogDistance, FogStart, FogEnd) * GlintAlpha;
    fragColor = vec4(color.rgb * fade, color.a);
}
