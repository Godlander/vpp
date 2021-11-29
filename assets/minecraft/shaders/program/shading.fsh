#version 150

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform vec2 OutSize;
uniform float Time;

in vec2 texCoord;
in vec2 oneTexel;
in mat4 ProjInv;
in float near;
in float far;
in float fogEnd;

out vec4 fragColor;

// moj_import doesn't work in post-process shaders ;_; Felix pls fix
#define NUMCONTROLS 27
#define THRESH 0.5
#define FPRECISION 4000000.0
#define PROJNEAR 0.05
#define FUDGE 32.0

int inControl(vec2 screenCoord, float screenWidth) {
    if (screenCoord.y < 1.0) {
        float index = floor(screenWidth / 2.0) + THRESH / 2.0;
        index = (screenCoord.x - index) / 2.0;
        if (fract(index) < THRESH && index < NUMCONTROLS && index >= 0) {
            return int(index);
        }
    }
    return -1;
}

vec4 getNotControl(sampler2D inSampler, vec2 coords, bool inctrl) {
    if (inctrl) {
        return (texture(inSampler, coords - vec2(oneTexel.x, 0.0)) + texture(inSampler, coords + vec2(oneTexel.x, 0.0)) + texture(inSampler, coords + vec2(0.0, oneTexel.y))) / 3.0;
    } else {
        return texture(inSampler, coords);
    }
}

float linearizeDepth(float depth) {
    return (2.0 * near * far) / (far + near - depth * (far - near));    
}

float luma(vec3 color){
    return dot(color,vec3(0.299, 0.587, 0.114));
}

vec4 backProject(vec4 vec) {
    vec4 tmp = ProjInv * vec;
    return tmp / tmp.w;
}

#define SAMPLES 64
#define INTENSITY 3.0
#define SCALE 2.5
#define BIAS 0.1
#define SAMPLE_RAD 0.5
#define MAX_DISTANCE 3.0
#define SNAPRANGE 100.0
#define GOLDEN_ANGLE 2.4

#define MOD3 vec3(.1031,.11369,.13787)

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float doAmbientOcclusion(vec2 tcoord, vec2 uv, vec3 p, vec3 cnorm)
{
    vec3 diff = backProject(vec4(2.0 * (tcoord + uv - vec2(0.5)), texture(DiffuseDepthSampler, tcoord + uv).r, 1.0)).xyz - p;
    float l = length(diff);
    vec3 v = diff/(l + 0.0000001);
    float d = l*SCALE;
    float ao = max(0.0,dot(cnorm,v)-BIAS)*(1.0/(1.0+d));
    ao *= smoothstep(MAX_DISTANCE,MAX_DISTANCE * 0.5, l);
    return ao;

}

float spiralAO(vec2 uv, vec3 p, vec3 n, float rad)
{
    float ao = 0.;
    float inv = 1. / float(SAMPLES);
    float radius = 0.;

    float rotatePhase = hash12( uv*101. + Time * 69. ) * 6.28;
    float rStep = inv * rad;
    vec2 spiralUV;

    for (int i = 0; i < SAMPLES; i++) {
        spiralUV.x = sin(rotatePhase);
        spiralUV.y = cos(rotatePhase);
        radius += rStep;
        ao += doAmbientOcclusion(uv, spiralUV * radius, p, n);
        rotatePhase += GOLDEN_ANGLE;
    }
    ao *= inv;
    return ao;
}

void main() {
    bool inctrl = inControl(texCoord * OutSize, OutSize.x) > -1;

    fragColor = texture(DiffuseSampler, texCoord);
    float depth = texture(DiffuseDepthSampler, texCoord).r;

    // not control and sunDir exists
    if (linearizeDepth(depth) < far - FUDGE) {
        vec2 normCoord = texCoord;

        depth = getNotControl(DiffuseDepthSampler, normCoord, inctrl).r;
        float depth2 = getNotControl(DiffuseDepthSampler, normCoord + vec2(0.0, oneTexel.y), inControl((normCoord + vec2(0.0, oneTexel.y)) * OutSize, OutSize.x) > -1).r;
        float depth3 = getNotControl(DiffuseDepthSampler, normCoord + vec2(oneTexel.x, 0.0), inControl((normCoord + vec2(oneTexel.x, 0.0)) * OutSize, OutSize.x) > -1).r;
        float depth4 = getNotControl(DiffuseDepthSampler, normCoord - vec2(0.0, oneTexel.y), inControl((normCoord - vec2(0.0, oneTexel.y)) * OutSize, OutSize.x) > -1).r;
        float depth5 = getNotControl(DiffuseDepthSampler, normCoord - vec2(oneTexel.x, 0.0), inControl((normCoord - vec2(oneTexel.x, 0.0)) * OutSize, OutSize.x) > -1).r;
        vec2 scaledCoord = 2.0 * (normCoord - vec2(0.5));
        vec3 fragpos = backProject(vec4(scaledCoord, depth, 1.0)).xyz;
        vec3 p2 = backProject(vec4(scaledCoord + 2.0 * vec2(0.0, oneTexel.y), depth2, 1.0)).xyz;
        p2 = p2 - fragpos;
        vec3 p3 = backProject(vec4(scaledCoord + 2.0 * vec2(oneTexel.x, 0.0), depth3, 1.0)).xyz;
        p3 = p3 - fragpos;
        vec3 p4 = backProject(vec4(scaledCoord - 2.0 * vec2(0.0, oneTexel.y), depth4, 1.0)).xyz;
        p4 = p4 - fragpos;
        vec3 p5 = backProject(vec4(scaledCoord - 2.0 * vec2(oneTexel.x, 0.0), depth5, 1.0)).xyz;
        p5 = p5 - fragpos;
        vec3 normal = normalize(cross(p2, p3)) 
                    + normalize(cross(-p4, p3)) 
                    + normalize(cross(p2, -p5)) 
                    + normalize(cross(-p4, -p5));
        normal = normal == vec3(0.0) ? vec3(0.0, 1.0, 0.0) : normalize(-normal);

        normal = normal.x >  (1.0 - 0.05 * clamp(length(fragpos) / SNAPRANGE, 0.0, 1.0)) ? vec3(1.0, 0.0, 0.0) : normal;
        normal = normal.x < -(1.0 - 0.05 * clamp(length(fragpos) / SNAPRANGE, 0.0, 1.0)) ? vec3(-1.0, 0.0, 0.0) : normal;
        normal = normal.y >  (1.0 - 0.05 * clamp(length(fragpos) / SNAPRANGE, 0.0, 1.0)) ? vec3(0.0, 1.0, 0.0) : normal;
        normal = normal.y < -(1.0 - 0.05 * clamp(length(fragpos) / SNAPRANGE, 0.0, 1.0)) ? vec3(0.0, -1.0, 0.0) : normal;
        normal = normal.z >  (1.0 - 0.05 * clamp(length(fragpos) / SNAPRANGE, 0.0, 1.0)) ? vec3(0.0, 0.0, 1.0) : normal;
        normal = normal.z < -(1.0 - 0.05 * clamp(length(fragpos) / SNAPRANGE, 0.0, 1.0)) ? vec3(0.0, 0.0, -1.0) : normal;

        // apply ambient occlusion.
        float rad = SAMPLE_RAD/linearizeDepth(depth);
        float ao = 1.0 - spiralAO(normCoord, fragpos, normal, rad) * INTENSITY;

        //fade ao with fog
        float vertexDistance = length(backProject(vec4(scaledCoord, depth, 1.0)).xyz);
        float aov = vertexDistance < fogEnd ? smoothstep(fogEnd * 0.01, fogEnd, vertexDistance) : 1.0;
        ao = mix(ao, 1.0, aov);

        fragColor.rgb *= ao;

        // desaturate bright pixels for more realistic feel
        fragColor.rgb = mix(fragColor.rgb, vec3(length(fragColor.rgb)/sqrt(3.0)), luma(fragColor.rgb) * 0.3);
    }
}
