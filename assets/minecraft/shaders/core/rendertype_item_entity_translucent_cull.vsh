#version 150

#moj_import <light.glsl>
#moj_import <matf.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;

uniform float GameTime;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord0;
out vec4 normal;
out vec4 glpos;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);

    float dist = -(ModelViewMat * vec4(1.0)).z;
    if (dist == 1602.) {
        mat4 rot = Rotate(GameTime * ROTSPEED, Y) * Scale(1.1, 1.1, 1.1);
        gl_Position = ProjMat * ModelViewMat * vec4((vec4(Position, 0) * rot).xyz, 1.0);
        normal = vec4((vec4(Normal, 0) * rot).xyz, 1.0);
        vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, normal.xyz, Color);
    }

    vertexDistance = length((ModelViewMat * vec4(Position, 1.0)).xyz);
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);
    texCoord0 = UV0;
    glpos = gl_Position;
}
