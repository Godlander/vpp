#version 330
#define FSH

#define POSITION_TEX
#define EXPECTED_TEXSIZE vec2(80)

#moj_import <utils.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform vec2 ScreenSize;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform vec4 FogColor;
uniform float FogStart;
uniform float FogEnd;

in vec4 vertexColor;
in mat4 ProjInv;
in vec2 texCoord0;
in vec2 progress;
in float isNeg;
in vec2 ScrSize;
in float isSun;
in vec4 pos1;
in vec4 pos2;
in vec4 pos3;

out vec4 fragColor;

#define PRECISIONSCALE 1000.0
#define MAGICSUNSIZE 3.0

// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
int hash(int x) {
    x += (x << 10);
    x ^= (x >>  6);
    x += (x <<  3);
    x ^= (x >> 11);
    x += (x << 15);
    return x;
}
int noise(ivec2 v, int seed) {
    return hash(v.x ^ hash(v.y + seed) ^ seed);
}

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (!is_gui(ProjMat)) {
        int index = in_control(gl_FragCoord.xy, ScreenSize.x);
        // currently in a control/message pixel
        if(index != -1) {
            if (isSun > 0.75) {
                // store the sun position in eye space indices [0,2]
                if (index >= CTL_SUNDIRX && index <= CTL_SUNDIRZ) {
                    vec3 p1 = pos1.rgb / pos1.a;
                    vec3 p2 = pos2.rgb / pos2.a;
                    vec3 p3 = pos3.rgb / pos3.a;
                    vec4 sunDir = mat4(IViewRotMat) * vec4(normalize(p1 + p3 + normalize(p2 - p1)), 0.0);
                    color = vec4(encode_float(sunDir[index]), 1.0);
                }
                // store sun alpha (RainStrength)
                else if (index == CTL_RAINSTRENGTH) {
                    color = vec4(1.0 - color.a, 0.0, 0.0, 1.0);
                }
                else {
                    discard;
                }
            }
            else if (isSun < 0.25) {
                //store fake sun pos
                if (index >= CTL_SUNDIRX && index <= CTL_SUNDIRZ) {
                    vec4 sunDir = vec4(0.0, -1.0, 0.0, 0.0);
                    color = vec4(encode_float(sunDir[index]), 1.0);
                }
                // store ProjMat in control pixels
                else if (index >= CTL_PMAT10 && index <= CTL_PMAT32) {
                    int c = (index - 5) / 4;
                    int r = (index - 5) - c * 4;
                    c = (c == 0 && r == 1) ? c : c + 1;
                    color = vec4(encode_float(ProjMat[c][r]), 1.0);
                }

                // store ModelViewMat in control pixels
                else if (index >= CTL_MVMAT00 && index <= CTL_MVMAT22) {
                    int c = (index - 16) / 3;
                    int r = (index - 16) - c * 3;
                    color = vec4(encode_float(ModelViewMat[c][r]), 1.0);
                }

                // store ProjMat[0][0] and ProjMat[1][1] in control pixels
                else if (index == CTL_ATAN_PMAT00 || index == CTL_ATAN_PMAT11) {
                    color = vec4(encode_float(atan(ProjMat[index - 3][index - 3])), 1.0);
                }

                // store FogColor in control pixels
                else if (index == CTL_FOGCOLOR) {
                    vec4 fc = FogColor;
                    color = vec4(fc.rgb, 1.0);
                }

                // store FogColor in control pixels as sky
                else if (index == CTL_SKYCOL) {
                    vec4 fc = FogColor;
                    color = vec4(fc.rgb, 1.0);
                }

                // store FogStart
                else if (index == CTL_FOGSTART) {
                    color = vec4(encode_int(int(round(FogStart))), 1.0);
                }

                // store FogEnd
                else if (index == CTL_FOGEND) {
                    color = vec4(encode_int(int(round(FogEnd))), 1.0);
                }

                // store Dimension
                else if (index == CTL_DIM) {
                    color = vec4(vec3(float(DIM_END) / 255.0), 1.0);
                }

                // store FarClip
                else if (index == CTL_FARCLIP) {
                    color = vec4(encode_int(int(round(get_far(ProjMat)))), 1.0);
                }

                // blackout remaining control pixels so other shaders can write to them (by default, all pixels are FogColor)
                else {
                    color = vec4(0.0, 0.0, 0.0, 1.0);
                }
            }
            else {
                discard;
            }
        }

        // calculate screen space UV of the sun since it was transformed to cover the entire screen in vsh so texCoord0 no longer works
        else if(isSun > 0.75) {
            vec3 p1 = pos1.rgb / pos1.a;
            vec3 p2 = pos2.rgb / pos2.a;
            vec3 p3 = pos3.rgb / pos3.a;
            vec3 center = (p1 + p3 + normalize(p2 - p1)) / (2 * PRECISIONSCALE); // scale down vector to reduce fp issues

            vec4 tmp = (ProjInv * vec4(2.0 * (gl_FragCoord.xy / ScreenSize - 0.5), 1.0, 1.0));
            vec3 planepos = tmp.xyz / tmp.w;
            float lookingat = dot(planepos, center);
            planepos = planepos / lookingat;
            vec2 uv = vec2(dot(p2 - p1, planepos - center), dot(p3 - p2, planepos - center));
            uv = uv / PRECISIONSCALE * MAGICSUNSIZE + vec2(0.5);

            // only draw one sun lol
            if (lookingat > 0.0 && all(greaterThanEqual(uv, vec2(0.0))) && all(lessThanEqual(uv, vec2(1.0)))) {
                color = texture(Sampler0, uv) * ColorModulator * vertexColor;
            }
            else discard;
        }
        else { // moon
            color *= ColorModulator * vertexColor;
        }
    }
    else {
        vec2 uv = texCoord0;
        vec2 atlassize = textureSize(Sampler0, 0);
        if(atlassize == EXPECTED_TEXSIZE) {
            #moj_import <menus-enchanted.glsl>
        }
    }

    if (color.a == 0.0) discard;
    fragColor = color;
}