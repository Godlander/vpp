#version 150

#moj_import <tools.glsl>
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
    float anim = GameTime * pi;
    float time = GameTime * 2048;
    float xx = Position.x / 2 * pi;
    float yy = Position.y / 2 * pi;
    float zz = Position.z / 2 * pi;
    float dropoff = max((position.x*position.x) + (position.z*position.z) - 64., 512.) / 512.;
    float far = ProjMat[3][2] * 0.05 / (ProjMat[3][2] + 2.0 * 0.05) / 3.0 * sqrt(3);

    vec3 offset = vec3(0.0,0.0,0.0);
    int alpha = int(texture(Sampler0, UV0).a * 255.5);

    //waving foliage
    if (alpha == 1 || alpha == 253 ) { // Most plants like grass and flowers use this
        offset.x = sin(position.x + animation) * -1.0 / 32.;
        offset.z = cos(position.z + position.y + animation) * -1.0 / 32.;
    } else if (alpha == 2) { // Used for the edges of multi-blocks, like the top block of tall grass or the bottom block of twisting vines
        offset.x = sin(position.x + position.y + animation) * -2.0 / 32.;
        offset.z = cos(position.z + position.y + animation) * -2.0 / 32.;
    } else if (alpha == 3) {
        offset.x = sin(position.x + position.y + animation) * -1.0 / 32.;
        offset.y = sin(position.y + (animation / 1.5)) / 9.0;
        offset.z = cos(position.z + position.y + animation) * -1.0 / 32.;
    } else if (alpha == 4 || alpha == 2) {
        offset.x = sin(position.x + position.y + animation) / 32.;
        offset.z = cos(position.z + position.y + animation) / 32.;
    } else if (alpha == 5 || alpha == 254) { //leaves
        offset.x = ((sin(time * 0.9 + yy) + cos(time * 0.9 + zz)) * 0.02);
        offset.y = ((cos(time / 3.0 + xx) + sin(time / 3.0 + zz)) * 0.01);
        offset.z = ((sin(time + 256 + yy) + cos(time + 256 + xx)) * 0.02);
    }
    //waving liquid
    else if (alpha == 131) { //water
        time = GameTime * 512;
        if ((mod(Position.y, 1.0) > 0.1) || (mod(Position.y, 1.0) < 0.01)) {
            offset.y = ((sin(time + xx) + cos(time + zz)) * 0.02) - 0.02;
            offset.y += ((sin(time*7 + xx*4.) + cos(time*7 + zz*4.)) * 0.01) - 0.01;
            offset.y += 0.01 * sin((Position.z * pi / 4.0 + anim * 700)) * 1.0 * (1.0 - smoothstep(0.0, 1.0, vertexDistance / far));
            offset.y += 0.01 * cos((Position.z * pi / 8.0 + Position.x * pi / 4.0 + anim * 400) + pi / 13.0) * 1.2 * (1.0 - smoothstep(0.1, 1.0, vertexDistance / far));
            offset.y += 0.01 * sin((Position.z * pi / 8.0 - Position.x * pi / 2.0 - anim * 900) - pi / 7.0) * 0.75 * (1.0 - smoothstep(0.0, 0.3, vertexDistance / far));
            offset.y += 0.01 * cos((Position.z * pi * 7.0 + Position.x * pi / 2.0 - anim * 870) + pi / 5.0) * 0.75 * (1.0 - smoothstep(0.0, 0.9, vertexDistance / far));
            offset.y /= dropoff;
        }
    } else if (alpha == 165) { //lava
        time = GameTime * 128;
        if ((mod(Position.y, 1.0) > 0.1) || (mod(Position.y, 1.0) < 0.01)) {
            offset.y = ((sin(time + xx) + cos(time + zz)) * 0.02) - 0.01;
            offset.y /= dropoff;
            offset.y += 0.03 * sin((Position.z * pi / 4.0 + anim * 700)) * 1.0 * (1.0 - smoothstep(0.0, 1.0, vertexDistance / far));
            offset.y += 0.03 * cos((Position.z * pi / 8.0 + Position.x * pi / 4.0 + anim * 400) + pi / 13.0) * 1.2 * (1.0 - smoothstep(0.1, 1.0, vertexDistance / far));
            offset.y += 0.03 * sin((Position.z * pi / 8.0 - Position.x * pi / 2.0 - anim * 900) - pi / 7.0) * 0.75 * (1.0 - smoothstep(0.0, 0.3, vertexDistance / far));
            offset.y += 0.03 * cos((Position.z * pi * 7.0 + Position.x * pi / 2.0 - anim * 870) + pi / 5.0) * 0.75 * (1.0 - smoothstep(0.0, 0.9, vertexDistance / far));
        }
    }
    
    gl_Position = ProjMat * ModelViewMat * (vec4(Position + ChunkOffset + offset, 1.0));

    //hanging lanterns
    if (alpha == 250) {
        vec3 relativePos = fract(Position);
        if (relativePos.y > 0.001) {
            time = GameTime * 1000.0 + dot(floor(Position), vec3(1.0)) * 1234.0;
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
