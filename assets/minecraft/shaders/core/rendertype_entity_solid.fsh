#version 150

#moj_import <fog.glsl>
#moj_import <emissive_utils.glsl>
#moj_import <utils.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightColor;
in vec4 overlayColor;
in vec2 texCoord0;
in vec4 normal;
in vec4 glpos;

out vec4 fragColor;

void main() {
    if (vertexDistance < FogEnd) discardControlGLPos(gl_FragCoord.xy, glpos);
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    float alpha = color.a * 255.0;
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color = make_emissive_entity(color, lightColor, vertexDistance, alpha);
    color.a = remap_alpha(alpha) / 255.0;
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
