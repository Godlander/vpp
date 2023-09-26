#version 330
#define FSH

#moj_import <utils.glsl>
#moj_import <light.glsl>
#moj_import <fog.glsl>

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform float GameTime;
uniform mat4 ProjMat;
uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in vec2 texCoord0;
in float fogDistance;
in float Distance;
in vec4 vertexColor;
in vec4 lightColor;
in vec4 glpos;

#ifdef PLAYER
flat in int skinEffects;
flat in int isFace;
flat in vec3 Times;
#endif

#ifdef OVERLAY
in vec4 overlayColor;
#endif

out vec4 fragColor;

void main() {
if (in_control(gl_FragCoord.xy, round(gl_FragCoord.x * 2.0 / (glpos.x / glpos.w + 1.0))) == CTL_DIM) {
    fragColor = vec4(vec3(float(get_dimension(Sampler2)) / 255.0), 1.0);
}
else {
    bool gui = is_gui(ProjMat);
    bool hand = is_hand(FogStart, FogEnd);
    if (!gui) discard_control_glpos(gl_FragCoord.xy, glpos);

    vec4 color = texture(Sampler0, texCoord0);

#ifdef PLAYER
    //blink effect
    vec2 texSize = textureSize(Sampler0,0);
    if(skinEffects == 1 && (texCoord0.y > 0.125 && texCoord0.y < 0.25) && ((texCoord0.x > 0.125 && texCoord0.x < 0.25) || (texCoord0.x > 0.625 && texCoord0.x < 0.75))) {
        //grab second frame with offset
        vec4 color2 = texture(Sampler0, texCoord0 + vec2(16.0/texSize.x, -8.0/texSize.y));
        //calculate timing
        vec2 duration = vec2(Times.r * 25.5, Times.g * 25.5);
        float time = mod(GameTime * 1200, duration.x + duration.y);
        if (Times.b > 0) { //blend color if interpolate
            float progress = (time <= duration.y)? ((time) / duration.y)-1. : (time - duration.y) / duration.x;
            color = mix(color2, color, (progress + 1.) / 2.);
        }
        else { //no interpolation
            color = (time < duration.y)? color2 : color;
        }
    }
    if (!gui) color *= lightColor;
#endif

    if (color.a < 0.01) discard;
    color *= vertexColor * ColorModulator;

#ifdef OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif

#ifndef PLAYER
    if (!gui) color = emissive(color, lightColor, Distance);
#endif

    fragColor = linear_fog(color, fogDistance, FogStart, FogEnd, FogColor);
}
}