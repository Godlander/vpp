#version 150

#moj_import <light.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;
uniform sampler2D Sampler0;
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
    float time = GameTime * 2048;
    float xx = Position.x / 2 * pi;
    float yy = Position.y / 2 * pi;
    float zz = Position.z / 2 * pi;

    float xs = 0.0;
    float ys = 0.0;
    float zs = 0.0;
	float alpha = texture(Sampler0, UV0).a * 255;
    if (alpha == 1.0 || alpha == 253.0) { //leaves
        xs = ((sin(time + yy) + cos(time + zz)) * 0.02);
        zs = ((sin(time + 256 + yy) + cos(time + 256 + xx)) * 0.02);
    }

    gl_Position = ProjMat * ModelViewMat * (vec4(Position + ChunkOffset, 1.0) + vec4(xs, ys, zs, 0.0));

    vertexDistance = length((ModelViewMat * vec4(Position + ChunkOffset, 1.0)).xyz);
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);
    vertexColor = Color * lightColor;
    texCoord0 = UV0;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
}