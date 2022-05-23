#version 150

#moj_import <fog.glsl>
#moj_import <utils.glsl>

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform vec2 ScreenSize;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform float GameTime;

in mat4 ProjInv;
in float isSky;
in float vertexDistance;

out vec4 fragColor;

//at this point, the entire sky is drawable: isSky for sky, stars and void plane for everything else.
//similar logic can be added in vsh to separate void plane from stars.
void main() {
    int index = inControl(gl_FragCoord.xy, ScreenSize.x);
    if (index != -1) {
        if (isSky > 0.5) {
            int c, r;
            switch (index) {
                //store ProjMat in control pixels
                case 5: case 6: case 7: case 8: case 9: case 10: case 11: case 12: case 13: case 14: case 15:
                    c = (index - 5) / 4;
                    r = (index - 5) - c * 4;
                    c = (c == 0 && r == 1) ? c : c + 1;
                    fragColor = vec4(encodeFloat(ProjMat[c][r]), 1.0);
                    break;
                //store ModelViewMat in control pixels
                case 16: case 17: case 18: case 19: case 20: case 21: case 22: case 23: case 24:
                    c = (index - 16) / 3;
                    r = (index - 16) - c * 3;
                    fragColor = vec4(encodeFloat(ModelViewMat[c][r]), 1.0);
                    break;
                //store ProjMat[0][0] and ProjMat[1][1] in control pixels
                case 3: case 4:
                    fragColor = vec4(encodeFloat(atan(ProjMat[index - 3][index - 3])), 1.0);
                    break;
                //store FogColor in control pixels
                case 25:
                    fragColor = FogColor;
                    break;
                //store FogEnd
                case 26:
                    fragColor = vec4(encodeInt(int(round(FogEnd))), 1.0);
                    break;
                //store GameTime
                case 27:
                    fragColor = vec4(vec3(fract(GameTime*1200)), 1.0);
                    break;
                //blackout control pixels for sunDir so sun can write to them (by default, all pixels are FogColor)
                default:
                    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
            }
        } else {
            discard;
        }
    }
    //not a control pixel, draw sky like normal
    else if (isSky > 0.5) {
        vec4 screenPos = gl_FragCoord;
        screenPos.xy = (screenPos.xy / ScreenSize - vec2(0.5)) * 2.0;
        screenPos.zw = vec2(1.0);
        vec3 view = normalize((ProjInv * screenPos).xyz);
        float ndusq = clamp(dot(view, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
        ndusq = ndusq * ndusq;
        fragColor = linear_fog(ColorModulator, pow(1.0 - ndusq, 8.0), 0.0, 1.0, FogColor);
    }
    else {
        fragColor = linear_fog(ColorModulator, vertexDistance, FogStart, FogEnd, FogColor);
    }

}
