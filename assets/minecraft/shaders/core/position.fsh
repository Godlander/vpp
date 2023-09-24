#version 330
#define FSH

#moj_import <utils.glsl>
#moj_import <fog.glsl>

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform vec2 ScreenSize;
uniform mat4 ProjMat;
uniform mat4 ModelViewMat;

in mat4 ProjInv;
in float isSky;
in float fogDistance;
in float seed;

out vec4 fragColor;

#define GRIDOFFSET 0.078
#define GRIDDENSITY 10.0
#define NIGHT_BOOST vec4(0.0, 0.02, 0.05, 0.0)

void main() {
    if (!is_gui(ProjMat)) {
        int index = in_control(gl_FragCoord.xy, ScreenSize.x);
        if (index != -1) {
            if (isSky > 0.5) {

                // store ProjMat in control pixels
                if (index >= CTL_PMAT10 && index <= CTL_PMAT32) {
                    int c = (index - 5) / 4;
                    int r = (index - 5) - c * 4;
                    c = (c == 0 && r == 1) ? c : c + 1;
                    fragColor = vec4(encode_float(ProjMat[c][r]), 1.0);
                }

                // store ModelViewMat in control pixels
                else if (index >= CTL_MVMAT00 && index <= CTL_MVMAT22) {
                    int c = (index - 16) / 3;
                    int r = (index - 16) - c * 3;
                    fragColor = vec4(encode_float(ModelViewMat[c][r]), 1.0);
                }

                // store ProjMat[0][0] and ProjMat[1][1] in control pixels
                else if (index == CTL_ATAN_PMAT00 || index == CTL_ATAN_PMAT11) {
                    fragColor = vec4(encode_float(atan(ProjMat[index - 3][index - 3])), 1.0);
                }

                // store FogColor in control pixels
                else if (index == CTL_FOGCOLOR) {
                    vec4 fc = FogColor;
                    fragColor = vec4(fc.rgb, 1.0);
                }

                // store ColorModulator in control pixels
                else if (index == CTL_SKYCOL) {
                    vec4 sc = ColorModulator + NIGHT_BOOST;
                    fragColor = vec4(sc.rgb, 1.0);
                }

                // store FogStart
                else if (index == CTL_FOGSTART) {
                    fragColor = vec4(encode_int(int(round(FogStart))), 1.0);
                }

                // store FogEnd
                else if (index == CTL_FOGEND) {
                    fragColor = vec4(encode_int(int(round(FogEnd))), 1.0);
                }

                // store Dimension
                else if (index == CTL_DIM) {
                    fragColor = vec4(vec3(float(DIM_OVER) / 255.0), 1.0);
                }

                // store FarClip
                else if (index == CTL_FARCLIP) {
                    fragColor = vec4(encode_int(int(round(get_far(ProjMat)))), 1.0);
                }

                // blackout remaining control pixels so other shaders can write to them (by default, all pixels are FogColor)
                else {
                    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
                }
            }
            else {
                discard;
            }
        }
        else {
            // get player space view vector
            vec4 screenPos = gl_FragCoord;
            screenPos.xy = (screenPos.xy / ScreenSize - vec2(0.5)) * 2.0;
            screenPos.zw = vec2(1.0);
            vec3 view = normalize((ProjInv * screenPos).xyz);

            float vdn = dot(view, vec3(0.0, 1.0, 0.0));
            float vdt = dot(view, vec3(1.0, 0.0, 0.0));
            float vdb = dot(view, vec3(0.0, 0.0, 1.0));

            // custom fog calculation if sky because sky disc is no longer above the head
            if (isSky > 0.5) {
                float ndusq = clamp(dot(view, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
                ndusq = ndusq * ndusq;

                vec4 noise = vec4(2.0 * vec3(hash21(gl_FragCoord.xy)) / 255.0, 0.0);

                fragColor = linear_fog(ColorModulator + NIGHT_BOOST + noise, pow(1.0 - ndusq, 8.0), 0.0, 1.0, FogColor);
            }
            // draw stars with random colors
            else if (isSky < -0.5) {
                vec4 rand = 2.0 * (hash14(float(int(round(seed)))) - 0.5);
                rand.rgb *= vec3(0.15, 0.1, 0.15);
                rand.a -= 0.6;
                fragColor = ColorModulator * 1.4 + rand;
            }
            // default shading for void plane
            else {
                fragColor = linear_fog(ColorModulator, fogDistance, FogStart, FogEnd, FogColor);
            }
        }
    }
    else {
        fragColor = linear_fog(ColorModulator, fogDistance, FogStart, FogEnd, FogColor);
    }
}