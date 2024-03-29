#version 330

in vec4 Position;

uniform mat4 ProjMat;
uniform vec2 OutSize;
uniform vec2 AuxSize0;
uniform sampler2D DataSampler;

out vec2 texCoord;
out vec2 oneTexel;
out vec3 sunDir;
out vec3 moonDir;
out float near;
out float far;
out vec4 fogColor;
out vec4 skyColor;
out float underWater;
out float dim;
out float rain;
out float cave;
out float cosFOVsq;
out float aspectRatio;
out float sdu;
out float mdu;
out mat4 Proj;
out mat4 ProjInv;

// moj_import doesn't work in post-process shaders ;_; Felix pls fix
#define FPRECISION 4000000.0
#define FPRECISION_L 400000.0
#define PROJNEAR 0.05
#define PROJFAR 1024.0
#define PI 3.1415926535897932
#define FUDGE 32.0

#define FLAG_UNDERWATER 1<<0

vec2 get_control(int index, vec2 screenSize) {
    return vec2(float(index) + 0.5, 0.5) / screenSize;
}

vec3 encode_int(int i) {
    int s = int(i < 0) * 128;
    i = abs(i);
    int r = i % 256;
    i = i / 256;
    int g = i % 256;
    i = i / 256;
    int b = i % 128;
    return vec3(float(r) / 255.0, float(g) / 255.0, float(b + s) / 255.0);
}

int decode_int(vec3 ivec) {
    ivec *= 255.0;
    int s = ivec.b >= 128.0 ? -1 : 1;
    return s * (int(ivec.r) + int(ivec.g) * 256 + (int(ivec.b) - 64 + s * 64) * 256 * 256);
}

vec3 encode_float(float f) {
    return encode_int(int(f * FPRECISION));
}

float decode_float(vec3 vec) {
    return decode_int(vec) / FPRECISION;
}

// Control Map:
#define CTL_SUNDIRX         0
#define CTL_SUNDIRY         1
#define CTL_SUNDIRZ         2
#define CTL_ATAN_PMAT00     3
#define CTL_ATAN_PMAT11     4
#define CTL_PMAT10          5
#define CTL_PMAT01          6
#define CTL_PMAT12          7
#define CTL_PMAT13          8
#define CTL_PMAT20          9
#define CTL_PMAT21          10
#define CTL_PMAT22          11
#define CTL_PMAT23          12
#define CTL_PMAT30          13
#define CTL_PMAT31          14
#define CTL_PMAT32          15
#define CTL_MVMAT00         16
#define CTL_MVMAT01         17
#define CTL_MVMAT02         18
#define CTL_MVMAT10         19
#define CTL_MVMAT11         20
#define CTL_MVMAT12         21
#define CTL_MVMAT20         22
#define CTL_MVMAT21         23
#define CTL_MVMAT22         24
#define CTL_FOGCOLOR        25
#define CTL_FOGSTART        26
#define CTL_FOGEND          27
#define CTL_DIM             28
#define CTL_RAINSTRENGTH    29
#define CTL_MISCFLAGS       30 // bit0:underwater
#define CTL_FARCLIP         31
#define CTL_SKYCOL          32

// Additional Post Map:
#define CTL_EXP0            47
#define CTL_EXP1            48
#define CTL_EXP2            49
#define CTL_EXP3            50
#define CTL_EXP4            51
#define CTL_EXP5            52
#define CTL_EXP6            53
#define CTL_EXP7            54
#define CTL_EXP8            55
#define CTL_EXPAVG          56
#define CTL_APPLYLIGHT0     57
#define CTL_APPLYLIGHT1     58
#define CTL_APPLYLIGHT2     59
#define CTL_APPLYLIGHT3     60
#define CTL_APPLYLIGHT4     61
#define CTL_APPLYLIGHTAVG   62
#define CTL_CAVE            63

void main(){
    vec4 outPos = ProjMat * vec4(Position.xy, 0.0, 1.0);
    gl_Position = vec4(outPos.xy, 0.2, 1.0);
    texCoord = Position.xy / OutSize;
    oneTexel = 1.0 / OutSize;

    //simply decoding all the control data and constructing the sunDir, ProjMat, ModelViewMat

    vec2 start = get_control(0, AuxSize0);
    vec2 inc = vec2(1.0 / AuxSize0.x, 0.0);

    // RealProjMat constructed fully
    mat4 RealProjMat = mat4(tan(decode_float(texture(DataSampler, start + CTL_ATAN_PMAT00 * inc).xyz)), decode_float(texture(DataSampler, start + CTL_PMAT01 * inc).xyz), 0.0, 0.0,
                        decode_float(texture(DataSampler, start + CTL_PMAT10 * inc).xyz), tan(decode_float(texture(DataSampler, start + CTL_ATAN_PMAT11 * inc).xyz)), decode_float(texture(DataSampler, start + CTL_PMAT12 * inc).xyz), decode_float(texture(DataSampler, start + CTL_PMAT13 * inc).xyz),
                        decode_float(texture(DataSampler, start + CTL_PMAT20 * inc).xyz), decode_float(texture(DataSampler, start + CTL_PMAT21 * inc).xyz), decode_float(texture(DataSampler, start + CTL_PMAT22 * inc).xyz),  decode_float(texture(DataSampler, start + CTL_PMAT23 * inc).xyz),
                        decode_float(texture(DataSampler, start + CTL_PMAT30 * inc).xyz), decode_float(texture(DataSampler, start + CTL_PMAT31 * inc).xyz), decode_float(texture(DataSampler, start + CTL_PMAT32 * inc).xyz), 0.0);

    mat4 ModelViewMat = mat4(decode_float(texture(DataSampler, start + CTL_MVMAT00 * inc).xyz), decode_float(texture(DataSampler, start + CTL_MVMAT01 * inc).xyz), decode_float(texture(DataSampler, start + CTL_MVMAT02 * inc).xyz), 0.0,
                        decode_float(texture(DataSampler, start + CTL_MVMAT10 * inc).xyz), decode_float(texture(DataSampler, start + CTL_MVMAT11 * inc).xyz), decode_float(texture(DataSampler, start + CTL_MVMAT12 * inc).xyz), 0.0,
                        decode_float(texture(DataSampler, start + CTL_MVMAT20 * inc).xyz), decode_float(texture(DataSampler, start + CTL_MVMAT21 * inc).xyz), decode_float(texture(DataSampler, start + CTL_MVMAT22 * inc).xyz), 0.0,
                        0.0, 0.0, 0.0, 1.0);

    sunDir = vec3(decode_float(texture(DataSampler, start + CTL_SUNDIRX * inc).xyz), 
                  decode_float(texture(DataSampler, start + CTL_SUNDIRY * inc).xyz), 
                  decode_float(texture(DataSampler, start + CTL_SUNDIRZ * inc).xyz));
    sunDir = normalize(sunDir);
    
    near = PROJNEAR;
    far = float(decode_int(texture(DataSampler, start + CTL_FARCLIP * inc).xyz));

    aspectRatio = OutSize.x / OutSize.y;
    cosFOVsq = RealProjMat[1][1] * RealProjMat[1][1];
    cosFOVsq = cosFOVsq / (1 + cosFOVsq); 
    Proj = RealProjMat * ModelViewMat;
    ProjInv = inverse(Proj);

    fogColor = texture(DataSampler, start + CTL_FOGCOLOR * inc);
    skyColor = texture(DataSampler, start + CTL_SKYCOL * inc);

    dim = texture(DataSampler, start + CTL_DIM * inc).r * 255.0;

    rain = texture(DataSampler, start + CTL_RAINSTRENGTH * inc).r;

    int flags = int(texture(DataSampler, start + CTL_MISCFLAGS * inc).r * 255.0);
    underWater = float((flags & FLAG_UNDERWATER) > 0);

    cave = smoothstep(0.2, 0.07, decode_float(texture(DataSampler, start + CTL_EXPAVG * inc).rgb) + 2.0) * decode_float(texture(DataSampler, start + CTL_CAVE * inc).rgb);

    moonDir = normalize(vec3(-sunDir.xy, 0.0));
    sdu = dot(vec3(0.0, 1.0, 0.0), sunDir);
    mdu = dot(vec3(0.0, 1.0, 0.0), moonDir);
}
