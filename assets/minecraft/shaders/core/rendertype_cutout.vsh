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

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;
uniform float GameTime;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightColor;
out vec2 texCoord0;
out vec4 normal;
out vec4 glpos;

#define pi 3.1415926535897932
#define phi 1.61803398875

vec4 quaternionMultiply(vec4 a, vec4 b) {
    return vec4(
        a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x,
        -a.x * b.z + a.y * b.w + a.z * b.x + a.w * b.y,
        a.x * b.y - a.y * b.x + a.z * b.w + a.w * b.z,
        -a.x * b.x - a.y * b.y - a.z * b.z + a.w * b.w
    );
}
vec3 quaternionRotate(vec3 pos, vec4 q) {
    vec4 qInv = vec4(-q.xyz, q.w);
    return quaternionMultiply(quaternionMultiply(q, vec4(pos, 0)), qInv).xyz;
}

void main() {
    vec3 position = Position / 2 * pi;
    float animation = GameTime * 2048.;

    //waving foliage
    vec3 offset = vec3(0.0,0.0,0.0);
    float alpha = texture(Sampler0, UV0).a * 255;
    if (alpha == 1.0 || alpha == 253.0 ) { // Most plants like grass and flowers use this
        offset.x = sin(position.x + animation) * -1.0 / 32.;
        offset.z = cos(position.z + position.y + animation) * -1.0 / 32.;
        
    } else if (alpha == 2.0) { // Used for the edges of multi-blocks, like the top block of tall grass or the bottom block of twisting vines
        offset.x = sin(position.x + position.y + animation) * -2.0 / 32.;
        offset.z = cos(position.z + position.y + animation) * -2.0 / 32.;
        
    } else if (alpha == 3.0) {
        offset.x = sin(position.x + position.y + animation) * -1.0 / 32.;
        offset.y = sin(position.y + (animation / 1.5)) / 9.0;
        offset.z = cos(position.z + position.y + animation) * -1.0 / 32.;
        
    } else if (alpha == 4.0) {
        offset.x = sin(position.x + position.y + animation) / 32.;
        offset.z = cos(position.z + position.y + animation) / 32.;

    }

    gl_Position = ProjMat * ModelViewMat * (vec4(Position + ChunkOffset + offset, 1.0));

    //hanging lanterns
    if (alpha == 250.) {
        vec3 relativePos = fract(Position);
        if (relativePos.y > 0.001) {
            float time = GameTime * 1000.0 + dot(floor(Position), vec3(1.0)) * 1234.0;
            vec3 newDown = normalize(vec3(
                sin(time * phi) * 0.015,
                -1.0,
                sin(time) * 0.015
            ));
        
            relativePos -= vec3(0.5, 1.0, 0.5);
            vec3 axis = normalize(cross(vec3(0, 1, 0), newDown));
            float cosAngle = newDown.y;
            vec4 quat = vec4(sqrt(1 - cosAngle * cosAngle) * axis, cosAngle);
            relativePos = quaternionRotate(relativePos, quat);
            offset = relativePos + vec3(0.5, 1.0, 0.5);
            gl_Position = ProjMat * ModelViewMat * vec4(floor(Position) + offset + ChunkOffset, 1.0);
        }
    }

    vertexDistance = length((ModelViewMat * vec4(Position + ChunkOffset, 1.0)).xyz);
    lightColor = minecraft_sample_lightmap(Sampler2, UV2);
    vertexColor = Color;
    texCoord0 = UV0;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
    glpos = gl_Position;
}
