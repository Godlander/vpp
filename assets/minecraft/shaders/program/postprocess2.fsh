#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D BloomSampler;

uniform float BloomAmount;
uniform float AutoExposure;
uniform float ExposurePoint;
uniform float Vibrance;
uniform float Curve;

in vec2 texCoord;
in vec2 oneTexel;
in float exposureNorm;
in float exposureClamp;

out vec4 fragColor;

// moj_import doesn't work in post-process shaders ;_; Felix pls fix
#define FPRECISION 4000000.0
#define FPRECISION_L 400000.0
#define PROJNEAR 0.05
#define PROJFAR 1024.0
#define PI 3.1415926535897932
#define FUDGE 32.0

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

float luma(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

#define CLAMP_EDGE oneTexel * 0.55
vec2 clampInBound(vec2 coords, float bound) {
    return clamp(coords, vec2(bound, 0.0) + CLAMP_EDGE, vec2(2.0 * bound, bound) - CLAMP_EDGE);
}

vec3 acesTonemap(vec3 x) {
  const float a = 2.51;
  const float b = 0.03;
  const float c = 2.1;
  const float d = 0.59;
  const float e = 0.14;
  return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

float customRolloff9(float x) {
    return x > 0.5555 ? 0.9 * (x - 0.5555) / (x - 0.5555 + 1.0) + 0.5 : 0.9 * x;
}

float customRolloff10(float x) {
    return x > 0.5 ? (x - 0.5) / (x - 0.5 + 1.0) + 0.5 : x;
}

float customRolloff2(float x) {
    return x > 0.2945 ? 1.2 * (x - 0.2) / (x - 0.2 + 1.0) + 0.190891 : x;
}

vec3 jodieReinhardTonemap(vec3 c, float upper) {
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    vec3 tc = c / (upper * c + 1.0);

    return mix(c / (upper * l + 1.0), tc, tc);
}

// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec4 outColor = texture(DiffuseSampler, texCoord);

    float bound = 0.5;
    vec2 scaledCoord = (texCoord + vec2(1.0, 0.0)) * bound;

    vec4 bloomCol = 4.0 * (texture(BloomSampler, clampInBound(scaledCoord, bound)))
                  + 2.0 * (texture(BloomSampler, clampInBound(scaledCoord + 0.99 * vec2(oneTexel.x, 0.0), bound)))
                  + 2.0 * (texture(BloomSampler, clampInBound(scaledCoord - 0.99 * vec2(oneTexel.x, 0.0), bound)))
                  + 2.0 * (texture(BloomSampler, clampInBound(scaledCoord + 0.99 * vec2(0.0, oneTexel.y), bound)))
                  + 2.0 * (texture(BloomSampler, clampInBound(scaledCoord - 0.99 * vec2(0.0, oneTexel.y), bound)))
                  + (texture(BloomSampler, clampInBound(scaledCoord + 0.99 * vec2(oneTexel.x, oneTexel.y), bound)))
                  + (texture(BloomSampler, clampInBound(scaledCoord - 0.99 * vec2(oneTexel.x, oneTexel.y), bound)))
                  + (texture(BloomSampler, clampInBound(scaledCoord + 0.99 * vec2(oneTexel.x, -oneTexel.y), bound)))
                  + (texture(BloomSampler, clampInBound(scaledCoord - 0.99 * vec2(oneTexel.x, -oneTexel.y), bound)));
    bloomCol /= 16.0;

    // apply bloom
    outColor += bloomCol * BloomAmount * (pow(1.0 - exposureNorm, 2.0) * 0.75 + 0.5);
    // outColor = bloomCol;

    // apply crosstalk
    outColor.rgb += vec3(0.02) * (outColor.r + outColor.g + outColor.b);

    if (AutoExposure > 0.5) {
        // apply exposure
        outColor.rgb /= exposureClamp * ExposurePoint;

        // apply tonemap
        outColor.rgb = pow(outColor.rgb, vec3(1.0 / Curve));
        // outColor.rgb = vec3(customRolloff9(outColor.r), customRolloff9(outColor.g), customRolloff9(outColor.b));
    }
    else {
        outColor.rgb /= ExposurePoint;
        outColor.rgb = pow(outColor.rgb, vec3(1.0 / Curve));
        // outColor.rgb = jodieReinhardTonemap(outColor.rgb, 0.25);
    }
    // outColor.rgb = acesTonemap(outColor.rgb);

    // saturation
    outColor.rgb = rgb2hsv(outColor.rgb);
    outColor.g *= Vibrance;
    outColor.rgb = hsv2rgb(outColor.rgb);

    fragColor = outColor;
}