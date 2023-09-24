#version 330

#moj_import <utils.glsl>

in vec3 Position;
in vec2 UV0;

uniform sampler2D Sampler0;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec2 ScreenSize;
uniform float FogStart;
uniform float FogEnd;

out vec4 vertexColor;
out mat4 ProjInv;
out vec2 texCoord0;
out vec2 progress;
out float isNeg;
out vec2 ScrSize;
out float isSun;
out vec4 pos1;
out vec4 pos2;
out vec4 pos3;

//0 3
//1 2

#define SUNSIZE 60
#define SUNDIST 110
#define OVERLAYSCALE 2

void main() {
    bool gui = is_gui(ProjMat);
    bool hand = is_hand(FogStart, FogEnd);

    vec2 atlassize = textureSize(Sampler0, 0);
    vec4 pos = vec4(Position, 1);
    vertexColor = vec4(1);
    ProjInv = mat4(0);
    pos1 = pos2 = pos3 = vec4(0);
    isSun = 0;

    if (!gui && !hand && pos.y < SUNDIST  && pos.y > -SUNDIST && (ModelViewMat * pos).z > -SUNDIST) {
        // only the sun has a square texture
        if (atlassize.x == atlassize.y) {
            isSun = 1;
            vec4 candidate = vec4(-2 * OVERLAYSCALE, -OVERLAYSCALE, 0, 1);

            // modify position of sun so that it covers the entire screen and store pos1, pos2, pos3 so player space position of sun can be extracted in fsh.
            // this is the key to get everything working since it guarantees that we can access sun info in the control pixels in fsh.
            if (UV0.x < 0.5) {
                pos1 = pos;
            }
            else {
                candidate.x = OVERLAYSCALE;
                if (UV0.y < 0.5) {
                    pos2 = pos;
                }
                else {
                    candidate.y = 2 * OVERLAYSCALE;
                    pos3 = pos;
                }
            }

            pos = candidate;
            ProjInv = inverse(ProjMat * ModelViewMat);
        }
        else {
            isSun = 0.5;
            texCoord0 = UV0;
            pos = ProjMat * ModelViewMat * pos;
        }
    }
    else {
        texCoord0 = UV0;
        float guiscale = ProjMat[0][0] * ScreenSize.x * 0.5;
        if (atlassize.y == 1335) {
            ivec2 uv = ivec2(UV0*256);
            switch (gl_VertexID % 4) {
                case 0: if (uv.x == 176 && uv.y < 14) {
                    progress = vec2(uv.y,1);
                    pos.xy += vec2(-56,-36 - uv.y);
                    uv = ivec2(0, 173);
                } break;
                case 1: if (uv == ivec2(176, 13)) {
                    progress = vec2(0);
                    pos.xy += vec2(-56, 34);
                    uv = ivec2(0, 256);
                } break;
                case 2: if (uv == ivec2(190, 13)) {
                    progress = vec2(0);
                    pos.xy += vec2(106, 34);
                    uv = ivec2(176, 256);
                } break;
                case 3: if (uv.x == 190 && uv.y < 14) {
                    progress = vec2(uv.y,1);
                    pos.xy += vec2(106,-36 - uv.y);
                    uv = ivec2(176, 173);
                } break;
            }
            texCoord0 = uv / atlassize;
        }
        isNeg = float(UV0.y < 0);
        ScrSize = 2 / vec2(ProjMat[0][0], -ProjMat[1][1]);
        pos = ProjMat * ModelViewMat * pos;
    }

    gl_Position = pos;
}