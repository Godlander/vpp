#version 150

#moj_import <emissive_utils.glsl>
#moj_import <utils.glsl>

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform vec4 ColorModulator;

in vec4 vertexColor;
in vec4 lightColor;
in vec2 texCoord0;
in vec4 normal;

out vec4 fragColor;

void main() {
    discardControlGLPos(gl_FragCoord.xy, glpos);
    vec4 color = texture(Sampler0, texCoord0) * vertexColor;
    color = make_emissive(color, lightColor, vertexDistance, alpha);
    if (color.a < 0.1) {
        discard;
    }
    fragColor = color * ColorModulator;
}