#version 150

#moj_import <tools.glsl>
#moj_import <utils.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;

in float vertexDistance;
in float dist;
in vec4 vertexColor;
in vec4 lightColor;
in vec2 texCoord0;
in vec4 glpos;

out vec4 fragColor;

void main() {
    discardControlGLPos(gl_FragCoord.xy, glpos);
    vec4 color = texture(Sampler0, texCoord0) * vertexColor;
    float alpha = textureLod(Sampler0, texCoord0, 0.0).a * 255.0;
    color = make_emissive(color, lightColor, dist, alpha);
    if (color.a < 0.01) discard;
    fragColor = color * ColorModulator;
}