#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D ShadingSampler;
uniform vec2 OutSize;

in vec2 texCoord;
in vec2 oneTexel;
in vec3 sunDir;
in vec3 moonDir;
in vec4 fogColor;
in float fogStart;
in float fogEnd;
in vec4 skyColor;
in mat4 Proj;
in mat4 ProjInv;
in float near;
in float far;
in float dim;
in float rain;
in float underWater;
in float mdu;
in float sdu;
in vec3 direct;
in vec3 ambient;
in vec3 backside;

out vec4 fragColor;

// moj_import doesn't work in post-process shaders ;_; Felix pls fix
#define FPRECISION 4000000.0
#define FPRECISION_L 400000.0
#define PROJNEAR 0.05
#define PROJFAR 1024.0
#define PI 3.1415926535897932
#define FUDGE 32.0

#define NIGHT_BOOST vec4(0.0, 0.02, 0.05, 0.0)
#define TINT_WATER vec3(0.0 / 255.0, 248.0 / 255.0, 255.0 / 255.0)
#define TINT_WATER_DISTANCE 48.0

#define FLAG_UNDERWATER 1<<0

#define DIM_UNKNOWN 0
#define DIM_OVER 1
#define DIM_END 2
#define DIM_NETHER 3

const vec2 poissonDisk[64] = vec2[64](
    vec2(-0.613392, 0.617481), vec2(0.170019, -0.040254), vec2(-0.299417, 0.791925), vec2(0.645680, 0.493210), vec2(-0.651784, 0.717887), vec2(0.421003, 0.027070), vec2(-0.817194, -0.271096), vec2(-0.705374, -0.668203), 
    vec2(0.977050, -0.108615), vec2(0.063326, 0.142369), vec2(0.203528, 0.214331), vec2(-0.667531, 0.326090), vec2(-0.098422, -0.295755), vec2(-0.885922, 0.215369), vec2(0.566637, 0.605213), vec2(0.039766, -0.396100),
    vec2(0.751946, 0.453352), vec2(0.078707, -0.715323), vec2(-0.075838, -0.529344), vec2(0.724479, -0.580798), vec2(0.222999, -0.215125), vec2(-0.467574, -0.405438), vec2(-0.248268, -0.814753), vec2(0.354411, -0.887570),
    vec2(0.175817, 0.382366), vec2(0.487472, -0.063082), vec2(-0.084078, 0.898312), vec2(0.488876, -0.783441), vec2(0.470016, 0.217933), vec2(-0.696890, -0.549791), vec2(-0.149693, 0.605762), vec2(0.034211, 0.979980),
    vec2(0.503098, -0.308878), vec2(-0.016205, -0.872921), vec2(0.385784, -0.393902), vec2(-0.146886, -0.859249), vec2(0.643361, 0.164098), vec2(0.634388, -0.049471), vec2(-0.688894, 0.007843), vec2(0.464034, -0.188818),
    vec2(-0.440840, 0.137486), vec2(0.364483, 0.511704), vec2(0.034028, 0.325968), vec2(0.099094, -0.308023), vec2(0.693960, -0.366253), vec2(0.678884, -0.204688), vec2(0.001801, 0.780328), vec2(0.145177, -0.898984),
    vec2(0.062655, -0.611866), vec2(0.315226, -0.604297), vec2(-0.780145, 0.486251), vec2(-0.371868, 0.882138), vec2(0.200476, 0.494430), vec2(-0.494552, -0.711051), vec2(0.612476, 0.705252), vec2(-0.578845, -0.768792),
    vec2(-0.772454, -0.090976), vec2(0.504440, 0.372295), vec2(0.155736, 0.065157), vec2(0.391522, 0.849605), vec2(-0.620106, -0.328104), vec2(0.789239, -0.419965), vec2(-0.545396, 0.538133), vec2(-0.178564, -0.596057));

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p3) {
	p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);

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

#define SNAPRANGE 100.0
#define S_FLIP_BIAS -0.2

float linearize_depth(float depth) {
    return (2.0 * near * far) / (far + near - depth * (far - near));    
}

float luma(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec4 back_project(vec4 vec) {
    vec4 tmp = ProjInv * vec;
    return tmp / tmp.w;
}

vec4 linear_fog(vec4 inColor, float vertexDistance, float fogStart, float fogEnd, vec4 fogColor) {
    if (vertexDistance <= fogStart) {
        return inColor;
    }
    float fogValue = vertexDistance < fogEnd ? smoothstep(fogStart, fogEnd, vertexDistance) : 1.0;
    return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a);
}

float get_sun_point(vec3 p, vec3 lp) {
    return smoothstep(0.08, 0.01, max(abs(p.x - lp.x), max(abs(p.y - lp.y), abs(p.z - lp.z)))) * 2.0;
}

float get_moon_point(vec3 p, vec3 lp) {
    return smoothstep(0.05, 0.01, distance(p, lp)) * 1.0;
}

vec3 get_atmospheric_scattering(vec4 fogCol, vec4 skyCol, vec3 p, vec3 lp, float sdu, float rain, bool fog) {
    float ndusq = clamp(dot(normalize(p), vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
    ndusq = ndusq * ndusq;

    return linear_fog(skyCol + NIGHT_BOOST, pow(1.0 - ndusq, 8.0), 0.0, 1.0, fogCol).rgb;
}

vec3 blend( vec3 dst, vec4 src ) {
    return mix(dst.rgb, src.rgb, src.a);
}

#define BLENDMULT_FACTOR 0.5

vec3 blendmult( vec3 dst, vec4 src) {
    return BLENDMULT_FACTOR * dst * mix(vec3(1.0), src.rgb, src.a) + (1.0 - BLENDMULT_FACTOR) * mix(dst.rgb, src.rgb, src.a);
}

void main() {
    vec4 outColor = texture(DiffuseSampler, texCoord);
    float depth = decode_depth(texture(DiffuseDepthSampler, texCoord));
    bool isSky = linearize_depth(depth) >= far - FUDGE;

    // sunDir exists
    if (length(sunDir) > 0.99) {

        // only do lighting if not sky
        if (!isSky) {
            depth = decode_depth(texture(DiffuseDepthSampler, texCoord));

            vec2 scaledCoord = 2.0 * (texCoord - vec2(0.5));

            vec3 fragpos = back_project(vec4(scaledCoord, depth, 1.0)).xyz;

            vec3 shading = texture(ShadingSampler, texCoord).rgb;

            // get ambient occlusion.
            vec3 ao = vec3(shading.b);
            ao += vec3(hash21(gl_FragCoord.xy)) / 255.0;
            
            ao = linear_fog(vec4(ao, 1.0), length(fragpos), fogStart, fogEnd, vec4(1.0)).rgb;
            
            // calculate final lighting color
            vec3 lightColor = vec3(1.0);
        
            // final shading
            outColor.rgb *= lightColor * ao;
        } 
        // if sky do atmosphere
        else if (abs(dim - DIM_OVER) < 0.01 && fogColor.a == 1.0) {
            // depth = decode_depth(texture(DiffuseDepthSampler, texCoord));
            // vec2 scaledCoord = 2.0 * (texCoord - vec2(0.5));
            // vec3 fragpos = back_project(vec4(scaledCoord, depth, 1.0)).xyz;
            // outColor.rgb = get_atmospheric_scattering(fogColor, skyColor, fragpos, sunDir, sdu, rain, false);
            // nothing for now
        }
    }

    fragColor = outColor;
}
