#version 150

in vec4 Position;

uniform sampler2D DiffuseSampler;
uniform mat4 ProjMat;
uniform vec2 InSize;
uniform vec2 OutSize;

out vec2 texCoord;
out vec2 oneTexel;
out vec3 approxNormal;
out float aspectRatio;
out float fogEnd;

vec2 getControl(int index, vec2 screenSize) {
    return vec2(floor(screenSize.x / 2.0) + float(index) * 2.0 + 0.5, 0.5) / screenSize;
}

int intmod(int i, int base) {
    return i - (i / base * base);
}

vec3 encodeInt(int i) {
    int s = int(i < 0) * 128;
    i = abs(i);
    int r = intmod(i, 256);
    i = i / 256;
    int g = intmod(i, 256);
    i = i / 256;
    int b = intmod(i, 128);
    return vec3(float(r) / 255.0, float(g) / 255.0, float(b + s) / 255.0);
}
int decodeInt(vec3 ivec) {
    ivec *= 255.0;
    int s = ivec.b >= 128.0 ? -1 : 1;
    return s * (int(ivec.r) + int(ivec.g) * 256 + (int(ivec.b) - 64 + s * 64) * 256 * 256);
}

#define FPRECISION 4000000.0
vec3 encodeFloat(float f) {
    return encodeInt(int(f * FPRECISION));
}
float decodeFloat(vec3 vec) {
    return decodeInt(vec) / FPRECISION;
}

void main(){
    vec2 start = getControl(0, OutSize);
    vec2 inc = vec2(2.0 / OutSize.x, 0.0);
    mat4 ModelViewMat = mat4(
        decodeFloat(texture(DiffuseSampler, start + 16.0 * inc).xyz),
        decodeFloat(texture(DiffuseSampler, start + 17.0 * inc).xyz),
        decodeFloat(texture(DiffuseSampler, start + 18.0 * inc).xyz), 0.0,

        decodeFloat(texture(DiffuseSampler, start + 19.0 * inc).xyz),
        decodeFloat(texture(DiffuseSampler, start + 20.0 * inc).xyz),
        decodeFloat(texture(DiffuseSampler, start + 21.0 * inc).xyz), 0.0,

        decodeFloat(texture(DiffuseSampler, start + 22.0 * inc).xyz),
        decodeFloat(texture(DiffuseSampler, start + 23.0 * inc).xyz),
        decodeFloat(texture(DiffuseSampler, start + 24.0 * inc).xyz), 0.0,

        0.0, 0.0, 0.0, 1.0
    );

    vec4 outPos = ProjMat * vec4(Position.xy, 0.0, 1.0);
    gl_Position = vec4(outPos.xy, 0.2, 1.0);
    texCoord = outPos.xy * 0.5 + 0.5;
    oneTexel = 1.0 / InSize;

    aspectRatio = InSize.x / InSize.y;
    approxNormal = normalize(transpose(inverse(mat3(ModelViewMat))) * vec3(0.0, 1.0, 0.0));
    approxNormal.y *= -1;
    fogEnd = float(decodeInt(texture(DiffuseSampler, start + 26.0 * inc).xyz));
}