#version 330

#moj_import <utils.glsl>
#moj_import <matrix.glsl>
#moj_import <light.glsl>
#moj_import <fog.glsl>

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
uniform int FogShape;
uniform float FogStart;
uniform float FogEnd;

out float fogDistance;
out float Distance;
out vec4 vertexColor;
out vec4 tintColor;
out vec4 lightColor;
out vec2 texCoord0;
out vec4 normal;
out vec4 glpos;

void main() {
    vec3 pos = Position + ChunkOffset;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
    Distance = length(pos);
    float far = get_far(ProjMat);

    vec3 relpos = Position + ChunkOffset;
    vec3 position = Position / 2 * PI;
    float animation = GameTime * 2048.;
    float anim = GameTime * PI;
    float time = GameTime * 2048;
    vec3 pp = Position / 2 * PI;
    float dropoff = max((relpos.x*relpos.x) + (relpos.z*relpos.z) - 128., 512.) / 512.;
    vec3 offset = vec3(0.0,0.0,0.0);
    int alpha = int(texture(Sampler0, UV0).a * 255.5);
    switch (alpha) {
        //waving foliage
        case 1: case 253: // Most plants like grass and flowers use this
            offset.x = sin(position.x + animation) * -1.0 / 32.;
            offset.z = cos(position.z + position.y + animation) * -1.0 / 32.;
            break;
        case 2: // Used for the edges of multi-blocks, like the top block of tall grass or the bottom block of twisting vines
            offset.x = sin(position.x + position.y + animation) * -2.0 / 32.;
            offset.z = cos(position.z + position.y + animation) * -2.0 / 32.;
            break;
        case 3 :
            offset.x = sin(position.x + position.y + animation) * -1.0 / 32.;
            offset.y = sin(position.y + (animation / 1.5)) / 9.0;
            offset.z = cos(position.z + position.y + animation) * -1.0 / 32.;
            break;
        case 4 :
            offset.x = sin(position.x + position.y + animation) / 32.;
            offset.z = cos(position.z + position.y + animation) / 32.;
            break;
        case 5: case 254: //leaves
            offset.x = ((sin(time * 0.9 + pp.y) + cos(time * 0.9 + pp.z)) * 0.02);
            offset.y = ((cos(time / 3.0 + pp.x) + sin(time / 3.0 + pp.z)) * 0.01);
            offset.z = ((sin(time + 256 + pp.y) + cos(time + 256 + pp.x)) * 0.02);
            break;
        //waving liquid
        case 131: //water
            time = GameTime * 512;
            pp = Position/16. * 2 * PI;
            if ((mod(Position.y, 1.0) > 0.1) || (mod(Position.y, 1.0) < 0.01)) {
                offset.y = ((sin(time + pp.x) + cos(time + pp.z)) * 0.02) - 0.02;
                offset.y += ((sin(time*7 + pp.x*4.) + cos(time*7 + pp.z*4.)) * 0.01) - 0.01;
                offset.y += 0.01 * sin((Position.z * PI / 4.0 + anim * 700)) * 1.0 * (1.0 - smoothstep(0.0, 1.0, Distance / far));
                offset.y += 0.01 * cos((Position.z * PI / 8.0 + Position.x * PI / 4.0 + anim * 400) + PI / 13.0) * 1.2 * (1.0 - smoothstep(0.1, 1.0, Distance / far));
                offset.y += 0.01 * sin((Position.z * PI / 8.0 - Position.x * PI / 2.0 - anim * 900) - PI / 7.0) * 0.75 * (1.0 - smoothstep(0.0, 0.3, Distance / far));
                offset.y += 0.01 * cos((Position.z * PI * 7.0 + Position.x * PI / 2.0 - anim * 870) + PI / 5.0) * 0.75 * (1.0 - smoothstep(0.0, 0.9, Distance / far));
                offset.y /= dropoff;
            }
            break;
        case 165: //lava
            time = GameTime * 128;
            pp = Position/16. * 2 * PI;
            if ((mod(Position.y, 1.0) > 0.1) || (mod(Position.y, 1.0) < 0.01)) {
                offset.y = ((sin(time + pp.x) + cos(time + pp.z)) * 0.02) - 0.01;
                offset.y /= dropoff;
                offset.y += 0.03 * sin((Position.z * PI / 4.0 + anim * 700)) * 1.0 * (1.0 - smoothstep(0.0, 1.0, Distance / far));
                offset.y += 0.03 * cos((Position.z * PI / 8.0 + Position.x * PI / 4.0 + anim * 400) + PI / 13.0) * 1.2 * (1.0 - smoothstep(0.1, 1.0, Distance / far));
                offset.y += 0.03 * sin((Position.z * PI / 8.0 - Position.x * PI / 2.0 - anim * 900) - PI / 7.0) * 0.75 * (1.0 - smoothstep(0.0, 0.3, Distance / far));
                offset.y += 0.03 * cos((Position.z * PI * 7.0 + Position.x * PI / 2.0 - anim * 870) + PI / 5.0) * 0.75 * (1.0 - smoothstep(0.0, 0.9, Distance / far));
            }
            break;
        //other
        case 250: //hanging lanterns
            vec3 relativePos = fract(Position);
            if (relativePos.y > 0.001) {
                animation = GameTime * 1000.0 + dot(floor(Position), vec3(1.0)) * 1234.0;
                vec3 newDown = normalize(vec3(
                    sin(animation * PHI) * 0.015,
                    -1.0,
                    sin(animation) * 0.015
                ));
                vec3 axis = normalize(cross(vec3(0, 1, 0), newDown));
                float cosAngle = newDown.y;
                vec4 quat = vec4(sqrt(1 - cosAngle * cosAngle) * axis, cosAngle);
                vec3 newPos = quaternion_rotate(relativePos - vec3(0.5, 1.0, 0.5), quat) + vec3(0.5, 1.0, 0.5);
                offset = newPos - relativePos;
            }
            break;
        case 251: //portal
            animation = GameTime * 4000.0;
            float m0 = distance(Position.xz, vec2(8.0, 8.0)) * 10.0;
            vec3 absNormal = abs(Normal);
            if (absNormal.z > absNormal.x && absNormal.z > absNormal.y) offset.z = (sin(Position.x * PI / 2.0 + animation) + cos(m0 + animation) * 0.65) / 24.0; // North/South wobble
            if (absNormal.x > absNormal.z && absNormal.x > absNormal.y) offset.x = (cos(Position.z * PI / 2.0 + animation) + sin(m0 + animation) * 0.65) / 24.0; // East / West wobble
            break;
    }
    pos += offset;

    texCoord0 = UV0;
    vertexColor = Color;
    lightColor = getlight(Sampler2, UV2);
    fogDistance = fog_distance(ModelViewMat, pos, FogShape);
    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
    glpos = gl_Position;
}