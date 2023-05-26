#version 150

#moj_import <utils.glsl>

uniform sampler2D Sampler0;
uniform vec4 ColorModulator;
uniform vec2 ScreenSize;
uniform mat4 ModelViewMat;

in mat4 ProjInv;
in vec3 cscale;
in vec3 c1;
in vec3 c2;
in vec3 c3;
in vec2 texCoord0;
in float isSun;
in float isNeg;
in vec2 ScrSize;

out vec4 fragColor;

#define PRECISIONSCALE 1000.0
#define MAGICSUNSIZE 3.0

void main() {
    vec4 color = vec4(0.0);
    int index = inControl(gl_FragCoord.xy, ScreenSize.x);
    vec2 atlassize = textureSize(Sampler0, 0);
    if (atlassize == vec2(80)) {
        #moj_import <menus-enchanted.glsl>
    }
    //currently in a control/message pixel
    else if (index != -1) {
        //store the sun position in eye space indices [0,2]
        if (isSun > 0.75 && index >= 0 && index <= 2) {
            vec4 sunDir = ModelViewMat * vec4(normalize(c1 / cscale.x + c3 / cscale.z), 0.0);
            color = vec4(encodeFloat(sunDir[index]), 1.0);
        }
        else if (isSun < 0.25) {
            color = texture(Sampler0, texCoord0) * ColorModulator;
        }
    }
    //calculate screen space UV of the sun since it was transformed to cover the entire screen in vsh so texCoord0 no longer works
    else if (isSun > 0.75) {
        vec3 p1 = c1 / cscale.x;
        vec3 p2 = c2 / cscale.y;
        vec3 p3 = c3 / cscale.z;
        vec3 center = (p1 + p3) / (2 * PRECISIONSCALE); //scale down vector to reduce fp issues
        vec4 tmp = (ProjInv * vec4(2.0 * (gl_FragCoord.xy / ScreenSize - 0.5), 1.0, 1.0));
        vec3 planepos = tmp.xyz / tmp.w;
        float lookingat = dot(planepos, center);
        planepos = planepos / lookingat;
        vec2 uv = vec2(dot(p2 - p1, planepos - center), dot(p3 - p2, planepos - center));
        uv = uv / PRECISIONSCALE * MAGICSUNSIZE + vec2(0.5);
        //only draw one sun lol
        if (lookingat > 0.0 && all(greaterThanEqual(uv, vec2(0.0))) && all(lessThanEqual(uv, vec2(1.0)))) {
            color = texture(Sampler0, uv) * ColorModulator;
        }
    } else {
        color = texture(Sampler0, texCoord0) * ColorModulator;
    }
    if (color.a == 0.0) {
        discard;
    }
    fragColor = color;
}
