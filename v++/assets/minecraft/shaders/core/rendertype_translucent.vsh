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
out vec2 texCoord0;
out vec4 normal;

void main() {
    vec3 position = Position + ChunkOffset;
    float time = GameTime * 512;
    float pi = 3.1415926535897932;
    float xx = Position.x/16. * 2 * pi;
    float zz = Position.z/16. * 2 * pi;
    float dropoff = max((position.x*position.x) + (position.z*position.z) - 64., 512.) / 512.;

    float offset_y = 0.0;
    if (rougheq(texture(Sampler0, UV0).a*255., 150.)) {
        offset_y = ((sin(time + xx) + cos(time + zz)) * 0.03) - 0.03;
        offset_y += ((sin(time*7 + xx*4.) + cos(time*7 + zz*4.)) * 0.01) - 0.01;
        offset_y /= dropoff;
    }

    gl_Position = ProjMat * ModelViewMat * vec4(position + vec3(0., offset_y, 0.), 1.);

    vertexDistance = length((ModelViewMat * vec4(position, 1.0)).xyz);
    vertexColor = Color * minecraft_sample_lightmap(Sampler2, UV2);
    texCoord0 = UV0;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
}
