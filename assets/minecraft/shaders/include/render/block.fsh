#version 330
#define FSH

#moj_import <utils.glsl>
#moj_import <light.glsl>
#moj_import <fog.glsl>

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ProjMat;
uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float fogDistance;
in float Distance;
in vec4 vertexColor;
in vec4 lightColor;
in vec2 texCoord0;
in vec4 glpos;

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
    if (color.a < 0.1) discard;
    color = color * vertexColor * ColorModulator;
    color = emissive(color, lightColor, Distance);
    fragColor = linear_fog(color, fogDistance, FogStart, FogEnd, FogColor);
}
}