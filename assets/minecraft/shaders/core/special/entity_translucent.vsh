#version 150

#moj_import <fog.glsl>
#moj_import <light.glsl>
#moj_import <matf.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;

uniform float GameTime;
uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec4 overlayColor;
out vec2 texCoord0;
out vec4 normal;
out vec4 glpos;

flat out int skinEffects;
flat out int isFace;
flat out vec3 Times;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);

    //rotating items
    float dist = -(ModelViewMat * vec4(1.0)).z;
    if (dist == 1602.) {
        mat4 rot = Rotate(GameTime * ROTSPEED, Y) * Scale(1.1, 1.1, 1.1);
        gl_Position = ProjMat * ModelViewMat * vec4((vec4(Position, 0) * rot).xyz, 1.0);
        normal = vec4((vec4(Normal, 0) * rot).xyz, 1.0);
        vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, normal.xyz, Color);
    }

    //animated skin
    skinEffects = 0;
    isFace = 0;
    vec4 skindata = texture(Sampler0, vec2(0.5, 0.0));
    if (abs(skindata.a - 0.918) < 0.001) {
        skinEffects = 1;
        Times = skindata.rgb;
        //mark face vertices
        if(((gl_VertexID >= 16 && gl_VertexID < 20) || (gl_VertexID >= 160 && gl_VertexID < 164))) {
            isFace = 1;
        }
    }

    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);
    overlayColor = texelFetch(Sampler1, UV1, 0);
    texCoord0 = UV0;
    glpos = gl_Position;
}