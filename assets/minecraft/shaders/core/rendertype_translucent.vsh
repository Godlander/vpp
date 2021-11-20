#version 150

#moj_import <tools.glsl>
#moj_import <light.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;
uniform float GameTime;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord0;
out vec4 normal;

#define pi 3.1415926535897932

void main() {
    vec3 position = Position + ChunkOffset;
    float time = GameTime * 512;
    float anim = GameTime * pi;
    float xx = Position.x/16. * 2 * pi;
    float zz = Position.z/16. * 2 * pi;
    float dropoff = max((position.x*position.x) + (position.z*position.z) - 128., 512.) / 512.;
    float far = ProjMat[3][2] * 0.05 / (ProjMat[3][2] + 2.0 * 0.05) / 3.0 * sqrt(3);

    float offset = 0.0;
    if (rougheq(texture(Sampler0, UV0).a*255., 131.)) { //water

        if ((mod(Position.y, 1.0) > 0.1) || (mod(Position.y, 1.0) < 0.01)) {
            offset = ((sin(time + xx) + cos(time + zz)) * 0.02) - 0.02;
            offset += ((sin(time*7 + xx*4.) + cos(time*7 + zz*4.)) * 0.01) - 0.01;
            offset += 0.01 * sin((Position.z * pi / 4.0 + anim * 700)) * 1.0 * (1.0 - smoothstep(0.0, 1.0, vertexDistance / far));
            offset += 0.01 * cos((Position.z * pi / 8.0 + Position.x * pi / 4.0 + anim * 400) + pi / 13.0) * 1.2 * (1.0 - smoothstep(0.1, 1.0, vertexDistance / far));
            offset += 0.01 * sin((Position.z * pi / 8.0 - Position.x * pi / 2.0 - anim * 900) - pi / 7.0) * 0.75 * (1.0 - smoothstep(0.0, 0.3, vertexDistance / far));
            offset += 0.01 * cos((Position.z * pi * 7.0 + Position.x * pi / 2.0 - anim * 870) + pi / 5.0) * 0.75 * (1.0 - smoothstep(0.0, 0.9, vertexDistance / far));
            offset /= dropoff;
        }
    }

    gl_Position = ProjMat * ModelViewMat * vec4(position + vec3(0., offset, 0.), 1.);

    vertexDistance = length((ModelViewMat * vec4(position, 1.0)).xyz);
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);
    vertexColor = Color * lightColor;
    texCoord0 = UV0;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
}
