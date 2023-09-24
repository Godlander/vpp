#version 330

#moj_import <utils.glsl>
#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <matrix.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

uniform float GameTime;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;
uniform float FogStart;
uniform float FogEnd;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out vec2 texCoord0;
out float fogDistance;
out float Distance;
out vec4 vertexColor;
out vec4 lightColor;
out vec4 glpos;

#ifdef OVERLAY
out vec4 overlayColor;
#endif

#ifdef PLAYER
flat out int skinEffects;
flat out int isFace;
flat out vec3 Times;
#endif

void main() {
    texCoord0 = UV0;
    vec3 pos = Position;
    vec3 normal = Normal;

#ifdef PLAYER
    //skin effects
    skinEffects = 0;
    isFace = 0;
    vec4 skindata = textureLod(Sampler0, vec2(0.5, 0.0), -4);
    //face vertices
    if(((gl_VertexID >= 16 && gl_VertexID < 20) || (gl_VertexID >= 160 && gl_VertexID < 164))) {
        isFace = 1;
    }
    //enable blink
    if (abs(skindata.a - 0.918) < 0.005) {
        skinEffects = 1;
        Times = skindata.rgb;
    }
#endif

    Distance = length(pos);
    fogDistance = fog_distance(ModelViewMat, IViewRotMat * pos, FogShape);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, normal, Color);
    lightColor = getlight(Sampler2, UV2);
    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
    glpos = gl_Position;

#ifdef OVERLAY
    overlayColor = texelFetch(Sampler1, UV1, 0);
#endif
}