#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform vec2 OutSize;

in vec2 texCoord;
in vec2 oneTexel;
in float near;
in float far;
in float fov;

out vec4 fragColor;

// moj_import doesn't work in post-process shaders ;_; Felix pls fix
#define FPRECISION 4000000.0
#define FPRECISION_L 400000.0
#define PROJNEAR 0.05
#define PROJFAR 1024.0
#define PI 3.1415926535897932
#define FUDGE 32.0


#define EMISSMULT 6.0

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

vec4 encode_uint(uint i) {
    uint r = (i) % 256u;
    uint g = (i >> 8u) % 256u;
    uint b = (i >> 16u) % 256u;
    uint a = (i >> 24u) % 256u;
    return vec4(float(r) / 255.0, float(g) / 255.0, float(b) / 255.0 , float(a) / 255.0);
}

uint decode_uint(vec4 ivec) {
    ivec *= 255.0;
    return uint(ivec.r) + (uint(ivec.g) << 8u) + (uint(ivec.b) << 16u) + (uint(ivec.a) << 24u);
}

vec4 encode_depth(float depth) {
    return encode_uint(floatBitsToUint(depth)); 
}

float decode_depth(vec4 depth) {
    return uintBitsToFloat(decode_uint(depth)); 
}

float linearize_depth(float depth) {
    return (2.0 * near * far) / (far + near - depth * (far - near));    
}

#define BLF_SAMPLES 4.0
#define BLF_SIGV_MIN 0.0
#define BLF_SIGV_MAX 0.03
#define BLF_SIGV_MULT 0.000002
#define BLF_STRIDE_MIN 0.1
#define BLF_STRIDE_MAX 2.0
#define BLF_STRIDE_MULT 0.07
#define BLF_STD_MIN 1.0
#define BLF_STD_MAX 10.0
#define BLF_STD_MULT 0.2
#define BLF_IS_X false

float gaussian(float sigma, float x) {
    return exp(-(x*x) / (2.0 * sigma*sigma));
}

vec3 joined_bilateral_gaussian_blur_y(vec2 uv, float sigX, float sigY, float sigV, float stride) {   

    float total = 0.0;
    vec3 ret = vec3(0.0);

    float depth = decode_depth(texture(DiffuseDepthSampler, uv));
    
    for (float i = -BLF_SAMPLES * stride; i <= BLF_SAMPLES * stride; i+= stride)
    {
        float fg = gaussian(sigY, i);

        float offsety = i * oneTexel.y;

        float sd = decode_depth(texture(DiffuseDepthSampler, uv + vec2(0.0, offsety)));
                    
        float fv = gaussian(sigV, abs(sd - depth));
        
        total += fg * fv;
        ret += fg * fv * texture(DiffuseSampler, uv + vec2(0.0, offsety / 2.0)).rgb;
    }
        
    return ret / total;
}

void main() {
    vec4 outColor = vec4(0.0);

    float ratio = linearize_depth(decode_depth(texture(DiffuseDepthSampler, texCoord))) / far  * (fov / 70.0);
    float sigV = clamp(BLF_SIGV_MULT / ratio, BLF_SIGV_MIN, BLF_SIGV_MAX);
    float stride = clamp(BLF_STRIDE_MULT * OutSize.y / 1440.0 / ratio, BLF_STRIDE_MIN, BLF_STRIDE_MAX);
    float st_dev = clamp(BLF_STD_MULT * OutSize.y / 1440.0 / ratio, BLF_STD_MIN, BLF_STD_MAX);

    outColor = vec4(joined_bilateral_gaussian_blur_y(texCoord, st_dev, st_dev, sigV, stride), 1.0);

    fragColor = outColor;
}
