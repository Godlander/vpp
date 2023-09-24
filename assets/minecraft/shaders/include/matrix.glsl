#version 330

mat2 mat2_rotate_z(float radians) {
    return mat2(
        cos(radians), -sin(radians),
        sin(radians), cos(radians)
    );
}

vec4 quaternion_multiply(vec4 a, vec4 b) {
    return vec4(
        a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x,
        -a.x * b.z + a.y * b.w + a.z * b.x + a.w * b.y,
        a.x * b.y - a.y * b.x + a.z * b.w + a.w * b.z,
        -a.x * b.x - a.y * b.y - a.z * b.z + a.w * b.w
    );
}
vec3 quaternion_rotate(vec3 pos, vec4 q) {
    vec4 qInv = vec4(-q.xyz, q.w);
    return quaternion_multiply(quaternion_multiply(q, vec4(pos, 0)), qInv).xyz;
}

#define X 0
#define Y 1
#define Z 2
#define ROTSPEED 1200.

mat4 MakeMat4() {
    return mat4(1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1);
}
mat4 Translate(float x, float y, float z) {
    return mat4(1, 0, 0, x,
                0, 1, 0, y,
                0, 0, 1, z,
                0, 0, 0, 1);
}
mat4 Translate(vec3 offset) {
    return mat4(1, 0, 0, offset.x,
                0, 1, 0, offset.y,
                0, 0, 1, offset.z,
                0, 0, 0, 1);
}
mat4 Scale(float x, float y, float z) {
    return mat4(x, 0, 0, 0,
                0, y, 0, 0,
                0, 0, z ,0,
                0, 0, 0, 1);
}
mat4 Scale(vec3 s) {
    return mat4(s.x,  0 ,  0 , 0,
                 0 , s.y,  0 , 0,
                 0 ,  0 , s.z, 0,
                 0 ,  0 ,  0 , 1);
}
mat4 Rotate(float angle, int type) {
    switch (type) {
        case 0:
        return mat4(1,     0     ,      0     , 0,
                    0, cos(angle), -sin(angle), 0,
                    0, sin(angle),  cos(angle), 0,
                    0,     0     ,      0     , 1);
        case 1:
        return mat4( cos(angle), 0, sin(angle), 0,
                         0     , 1,     0     , 0,
                    -sin(angle), 0, cos(angle), 0,
                         0     , 0,     0     , 1);
        case 2:
        return mat4(cos(angle), -sin(angle), 0, 0,
                    sin(angle),  cos(angle), 0, 0,
                        0     ,      0     , 1, 0,
                        0     ,      0     , 0, 1);
    }
    return mat4(0);
}