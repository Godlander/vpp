#version 330

vec3 rgbhsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsvrgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

bool rougheq(float a, float b, float acc) {return (abs(a - b) < acc);}
bool rougheq(vec3 a, vec3 b, float acc) {return (lessThan(a,b+acc)==bvec3(true) && lessThan(b-acc,a)==bvec3(true));}

const vec2[4] corners = vec2[4](vec2(0, 1),vec2(0, 0),vec2(1, 0),vec2(1, 1));

#define PI 3.1415926535897932
#define PHI 1.61803398875
#define NUMCONTROLS 33
#define FPRECISION 4000000.0
#define PROJNEAR 0.05

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
#define CTL_FOGEND          27 // also FogLambda
#define CTL_DIM             28
#define CTL_RAINSTRENGTH    29
#define CTL_MISCFLAGS       30 // bit0:underwater
#define CTL_FARCLIP         31
#define CTL_SKYCOL          32

#define DIM_UNKNOWN 0
#define DIM_OVER    1
#define DIM_END     2
#define DIM_NETHER  3

#ifdef FSH
// returns control pixel index or -1 if not control
int in_control(vec2 screenCoord, float screenWidth) {
    float start = floor(screenWidth / 4.0) * 2.0;
    int index = int(screenCoord.x - start) / 2;
    if (screenCoord.y < 1.0 && screenCoord.x > start && int(screenCoord.x) % 2 == 0 && index < NUMCONTROLS) {
        return index;
    }
    return -1;
}

// discards the current pixel if it is control
void discard_control(vec2 screenCoord, float screenWidth) {
    if (in_control(screenCoord, screenWidth) >= 0) {
        discard;
    }
}

// discard but for when ScreenSize is not given
void discard_control_glpos(vec2 screenCoord, vec4 glpos) {
    float screenWidth = round(screenCoord.x * 2.0 / (glpos.x / glpos.w + 1.0));
    discard_control(screenCoord, screenWidth);
}
#endif

bool is_gui(mat4 ProjMat) {return ProjMat[2][3] == 0.0;}
bool is_hand(float fogs, float foge) {return fogs > foge;}

// get screen coordinates of a particular control index
vec2 get_control(int index, vec2 screenSize) {
    return vec2(floor(screenSize.x / 4.0) * 2.0 + float(index) * 2.0 + 0.5, 0.5) / screenSize;
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
vec3 encode_float(float f) {return encode_int(int(round(f * FPRECISION)));}
float decode_float(vec3 vec) {return decode_int(vec) / FPRECISION;}

// Gets the dimension that an object is in, -1 for The Nether, 0 for The Overworld, 1 for The End.
int get_dimension(sampler2D lightmap) {
    vec4 minLightColor = texelFetch(lightmap, ivec2(0), 0);
    if (minLightColor.r == minLightColor.g && minLightColor.g == minLightColor.b) return DIM_OVER; // Shadows are grayscale in The Overworld
    else if (minLightColor.r > minLightColor.g) return DIM_NETHER; // Shadows are more red in The Nether
    else return DIM_END; // Shadows are slightly green in The End
}

float get_fov(mat4 ProjMat) {
    return atan(1.0, ProjMat[1][1]) * 360.0 / PI;
}

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}
vec3 hash13(float p) {
   vec3 p3 = fract(vec3(p, p, p) * vec3(0.1031, 0.1030, 0.0973));
   p3 += dot(p3, p3.yzx + 33.33);
   return fract((p3.xxy + p3.yzz) * p3.zyx);
}
vec4 hash14(float p) {
    vec4 p4 = fract(vec4(p, p, p, p) * vec4(0.1031, 0.1030, 0.0973, 0.1099));
    p4 += dot(p4, p4.wzxy + 33.33);
    return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}
float hash21(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}
vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

float get_far(mat4 ProjMat) {
    vec4 probe = inverse(ProjMat) * vec4(0.0, 0.0, 1.0, 1.0);
    return length(probe.xyz / probe.w);
}