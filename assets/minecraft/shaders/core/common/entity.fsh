#version 150

#moj_import <fog.glsl>
#moj_import <emissive_utils.glsl>
#moj_import <utils.glsl>

uniform mat4 ProjMat;
uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec2 texCoord0;
in vec4 vertexColor;
in vec4 lightColor;
in vec4 overlayColor;
in vec4 normal;
in vec4 glpos;

out vec4 fragColor;

void main() {
    if (!isGUI(ProjMat)) discardControlGLPos(gl_FragCoord.xy, glpos);
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    if (!isGUI(ProjMat)) {
        float alpha = textureLod(Sampler0, texCoord0, 0.0).a * 255.0;
        color = make_emissive(color, lightColor, vertexDistance, alpha);
    }
    if (color.a < 0.01) {
        discard;
    }
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
