#version 150

#moj_import <fog.glsl>
#moj_import <tools.glsl>
#moj_import <utils.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in float dist;
in vec4 vertexColor;
in vec4 lightColor;
in vec2 texCoord0;
in vec4 glpos;

out vec4 fragColor;

void main() {
    discardControlGLPos(gl_FragCoord.xy, glpos);
    vec4 color = texture(Sampler0, texCoord0);
    float alpha = color.a * 255.0;
    if (color.a < 0.1) discard;
    color = color * vertexColor * ColorModulator;
    color = make_emissive(color, lightColor, dist, alpha);
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}