#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D ReflectionSampler;
uniform sampler2D ItemEntitySampler;
uniform sampler2D ItemEntityDepthSampler;
uniform sampler2D ParticlesWeatherSampler;
uniform sampler2D ParticlesWeatherDepthSampler;
uniform sampler2D CloudsSampler;
uniform sampler2D CloudsDepthSampler;
uniform vec2 OutSize;

in vec2 texCoord;
in vec2 oneTexel;
in vec3 sunDir;
in mat4 ProjInv;
in float near;
in float far;
in vec4 fogColor;
in vec4 skyColor;
in float underWater;
in float rain;
in float cave;
in float dim;
in float sdu;

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

#define DIM_UNKNOWN 0
#define DIM_OVER 1
#define DIM_END 2
#define DIM_NETHER 3

#define NUM_LAYERS 5

#define DEFAULT 0u
#define FOGFADE 1u
#define BLENDMULT 2u
#define BLENDADD 4u
#define HASREFLECT 8u

vec4 color_layers[NUM_LAYERS];
float depth_layers[NUM_LAYERS];
uint op_layers[NUM_LAYERS];
int index_layers[NUM_LAYERS] = int[NUM_LAYERS](0, 1 ,2, 3, 4);
int active_layers = 0;

out vec4 fragColor;

vec2 scaledCoord = 2.0 * (texCoord - vec2(0.5));

float hash21(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p3) {
	p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

vec4 encode_uint(uint i) {
    uint r = (i) % 256u;
    uint g = (i >> 8u) % 256u;
    uint b = (i >> 16u) % 256u;
    uint a = (i >> 24u) % 256u;
    return vec4(float(r) / 255.0, float(g) / 255.0, float(b) / 255.0 , float(a) / 255.0);
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

uint decode_uint(vec4 ivec) {
    ivec *= 255.0;
    return uint(ivec.r) + (uint(ivec.g) << 8u) + (uint(ivec.b) << 16u) + (uint(ivec.a) << 24u);
}

vec3 encode_float(float f) {
    return encode_int(int(f * FPRECISION));
}

float decode_float(vec3 vec) {
    return decode_int(vec) / FPRECISION;
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

float linearstep(float edge0, float edge1, float x)
{
    return  clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

vec4 back_project(vec4 vec) {
    vec4 tmp = ProjInv * vec;
    return tmp / tmp.w;
}

float euclidianDistance(vec4 coord) {
    return length(back_project(coord).xyz);
}

float cylindricalDistance(vec4 coord) {
    return length(back_project(coord).xz);
}

void try_insert( vec4 color, float depth, uint op ) {
    if (color.a == 0.0) {
        return;
    }

    color_layers[active_layers] = color;
    depth_layers[active_layers] = depth;
    op_layers[active_layers] = op;

    int jj = active_layers++;
    int ii = jj - 1;
    while (jj > 0 && depth > depth_layers[index_layers[ii]]) {
        int indexTemp = index_layers[ii];
        index_layers[ii] = index_layers[jj];
        index_layers[jj] = indexTemp;

        jj = ii--;
    }
}

vec3 blend(vec3 dst, vec4 src) {
    return mix(dst.rgb, src.rgb, src.a);
}

vec3 blendadd(vec3 dst, vec4 src) {
    return ( dst * ( 1.0 - src.a ) ) + src.rgb;
}

#define BLENDMULT_FACTOR 0.5

vec3 blendmult(vec3 dst, vec4 src) {
    return BLENDMULT_FACTOR * dst * mix(vec3(1.0), src.rgb, src.a) + (1.0 - BLENDMULT_FACTOR) * mix(dst.rgb, src.rgb, src.a);
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

void main() {
    vec3 fragpos = back_project(vec4(scaledCoord, 1.0, 1.0)).xyz;

    fragpos = normalize(fragpos);
    fragpos.y = abs(fragpos.y * 0.5);
    fragpos = normalize(fragpos);

    vec4 calculatedFog = vec4(1.0);

    vec3 color = fogColor.rgb;
    if (abs(dim - DIM_OVER) < 0.01 && fogColor.a == 1.0) {
        color = get_atmospheric_scattering(fogColor, skyColor, fragpos, sunDir, sdu, rain, true);
    }
    if (underWater > 0.5) {
        calculatedFog.rgb = fogColor.rgb;
    }
    else {
        calculatedFog.rgb = mix(color, fogColor.rgb, cave);
    }

    op_layers[0] = DEFAULT;
    // crumbling, beacon_beam, leash, entity_translucent_emissive(warden glow), chunk border lines
    depth_layers[0] = decode_depth(texture(DiffuseDepthSampler, texCoord));
    vec4 diffusecolor = vec4(texture(DiffuseSampler, texCoord).rgb, 1.0);
    float currdist = euclidianDistance(vec4(scaledCoord, depth_layers[0], 1.0));
    bool sky = depth_layers[0] == 1.0;

    color_layers[0] = diffusecolor;
    active_layers = 1;
    vec4 reflection = texture(ReflectionSampler, texCoord);

    try_insert( texture(CloudsSampler, texCoord), texture(CloudsDepthSampler, texCoord).r, FOGFADE);

    // glass, water
    uint flags = HASREFLECT;
    try_insert( texture(TranslucentSampler, texCoord), texture(TranslucentDepthSampler, texCoord).r, flags); 
    // rain, snow, tripwire
    try_insert( texture(ParticlesWeatherSampler, texCoord), decode_depth(texture(ParticlesWeatherDepthSampler, texCoord)), DEFAULT);
    // translucent_moving_block, lines, item_entity_translucent_cull
    try_insert( texture(ItemEntitySampler, texCoord), texture(ItemEntityDepthSampler, texCoord).r, BLENDADD);

    vec4 texelAccum = vec4(color_layers[index_layers[0]].rgb, 1.0);
    for ( int ii = 1; ii < active_layers; ++ii ) {
        int index = index_layers[ii];
        uint flags = op_layers[index];
        float dist = euclidianDistance(vec4(scaledCoord, depth_layers[index], 1.0));
        currdist = dist;
        if ((flags & FOGFADE) == 0u) {
            sky = false;
        }
        if ((flags & BLENDMULT) > 0u) {
            texelAccum.rgb = blendmult( texelAccum.rgb, color_layers[index]);
        } 
        else if ((flags & BLENDADD) > 0u) {
            texelAccum.rgb = blendadd( texelAccum.rgb, color_layers[index]);
        } 
        else {
            texelAccum.rgb = blend( texelAccum.rgb, color_layers[index]);
        }
        if ((flags & HASREFLECT) > 0u) {
            texelAccum.rgb = mix(texelAccum.rgb, reflection.rgb, reflection.a);
        }
    }

    if (sky && underWater > 0.5) {
        texelAccum = fogColor;
    }

    fragColor = texelAccum;
}