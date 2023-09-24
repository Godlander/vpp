#version 330
#define FSH

#moj_import <utils.glsl>

uniform mat4 ProjMat;
uniform sampler2D Sampler0;

uniform vec4 ColorModulator;

in vec4 vertexColor;
in vec2 texCoord0;
in vec3 Pos;
in vec3 rNormal;
in mat3 mat;
in vec4 glpos;

out vec4 fragColor;

#define DEPTH 0.5

void main() {
    discard_control_glpos(gl_FragCoord.xy, glpos);

    fragColor = texture(Sampler0, texCoord0) * vertexColor;
    if (fragColor.a < 0.1) discard;

    vec2 texSize = textureSize(Sampler0, 0);
    vec3 viewDir = normalize(Pos * mat);
    vec2 offs = viewDir.xy / -viewDir.z / texSize.x * DEPTH;

    if (abs(rNormal.z) >= 0.9) {offs.x *= -1;}
    if (rNormal.y > -0.9) {offs.y *= -1;}

    float i;
    vec4 rayCol;
    for (i = 1; i <= 16; i++) {
        rayCol = texture(Sampler0, texCoord0 + offs / 16.0 * i);
        if (rayCol.a < 0.1) {
            fragColor = vec4(0.2, 0.2, 0.2, 1);
            break;
        }
    }
    if (i > 16) {fragColor = vec4(0.5, 0.5, 0.5, 1);}
}