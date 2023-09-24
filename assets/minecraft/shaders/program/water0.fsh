#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D TranslucentDepthSampler;
uniform vec2 OutSize;
uniform float SSRLevel;

in vec2 texCoord;
in vec2 oneTexel;
in vec3 sunDir;
in vec3 moonDir;
in float near;
in float far;
in vec4 fogColor;
in vec4 skyColor;
in float underWater;
in float dim;
in float rain;
in float cave;
in float cosFOVsq;
in float aspectRatio;
in float sdu;
in float mdu;
in mat4 Proj;
in mat4 ProjInv;

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
    return smoothstep(0.08, 0.01, max(abs(p.x - lp.x), max(abs(p.y - lp.y), abs(p.z - lp.z)))) * 1.0;
}

#define SUNCOL_L vec3(0.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0)
#define SUNCOL_M vec3(252.0 / 255.0, 250.0 / 255.0, 150.0 / 255.0)
#define SUNCOL_H vec3(255.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0)

#define MOONCOL_L vec3(0.0 / 255.0, 0.0 / 255.0, 0.0 / 255.0)
#define MOONCOL_M vec3(255.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0)
#define MOONCOL_H vec3(255.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0)

vec3 get_atmospheric_scattering(vec4 fogCol, vec4 skyCol, vec3 p, vec3 lp, float sdu, float rain, bool fog) {
    float ndusq = clamp(dot(normalize(p), vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
    ndusq = ndusq * ndusq;

    vec3 outCol = linear_fog(skyCol + NIGHT_BOOST, pow(1.0 - ndusq, 8.0), 0.0, 1.0, fogCol).rgb;
    return outCol;
}

#define APPROX_TAPS 6
#define APPROX_THRESH 0.5
#define APPROX_SCATTER 0.01
#define NORMAL_SCATTER 0.004
#define NORMAL_SMOOTHING 0.01
#define NORMAL_DEPTH_REJECT 0.15
#define NORMAL_DEPTH_REJECT_L 0.000001
#define NORMRAD 5

#define SSR_TAPS 1
#define SSR_SAMPLES 64
#define SSR_MAXREFINESAMPLES 8
#define SSR_STEPSIZE 0.7
#define SSR_STEPREFINE 0.25
#define SSR_STEPINCREASE 1.25
#define SSR_IGNORETHRESH 20.0
#define SSR_INVALIDTHRESH 30.0
#define SSR_BLURR 0.01
#define SSR_BLURTAPS 3
#define SSR_BLURSAMPLEOFFSET 17

float linearize_depth(float depth) {
    return (2.0 * near * far) / (far + near - depth * (far - near));    
}

float dither_grad_noise() {
  return fract(52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y));
}

float luma(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec4 SSR(vec3 fragpos, vec3 dir, float fragdepth, vec3 surfacenorm, vec2 randsamples[64]) {
    vec3 rayStart   = fragpos;
    vec3 rayDir     = reflect(normalize(dir), surfacenorm);
    vec3 rayStep    = (SSR_STEPSIZE + SSR_STEPSIZE * 0.05 * (dither_grad_noise()-0.5)) * rayDir;
    vec3 rayPos     = rayStart + rayStep;
    vec3 rayPrevPos = rayStart;
    vec3 rayRefine  = rayStep;

    int refine  = 0;
    vec4 pos    = vec4(0.0);
    float edge  = 0.0;
    float dtmp  = 0.0;
    float dtmp_nolin = 0.0;
    float dist  = 0.0;
    bool oob = false;

    for (int i = 0; i < SSR_SAMPLES; i += 1) {
        pos = Proj * vec4(rayPos.xyz, 1.0);
        pos.xyz /= pos.w;
        if (pos.x < -1.0 || pos.x > 1.0 || pos.y < -1.0 || pos.y > 1.0 || pos.z < 0.0 || pos.z > 1.0) {
            oob = true;
            break;
        }
        dtmp_nolin = texture(DiffuseDepthSampler, 0.5 * pos.xy + vec2(0.5)).r;
        dtmp = linearize_depth(dtmp_nolin);
        dist = abs(linearize_depth(pos.z) - dtmp);

        if (dist < length(rayStep) * pow(length(rayRefine), 0.25) * 3.0) {
            refine++;
            if (refine >= SSR_MAXREFINESAMPLES)    break;
            rayRefine  -= rayStep;
            rayStep    *= SSR_STEPREFINE;
        }

        rayStep        *= SSR_STEPINCREASE;
        rayPrevPos      = rayPos;
        rayRefine      += rayStep;
        rayPos          = rayStart+rayRefine;

    }

    vec3 skycol = fogColor.rgb;
    if (underWater < 0.5 && abs(dim - DIM_OVER) < 0.01) {
        skycol = get_atmospheric_scattering(fogColor, skyColor, rayDir, sunDir, sdu, rain, false);
        skycol = mix(skycol, fogColor.rgb, cave);

        // add sun and moon if visible
        vec3 adjustedSun = normalize(sunDir * far - fragpos);
        vec3 adjustedMoon = normalize(moonDir * far - fragpos);
        if (sdu > 0.0) {
            skycol += (1.0 - cave) * mix(SUNCOL_M, SUNCOL_H, abs(sdu)) * get_sun_point(rayDir, adjustedSun);
            skycol += (1.0 - cave) * mix(MOONCOL_M, MOONCOL_H, pow(abs(mdu), 0.1)) * get_moon_point(rayDir, adjustedMoon);
        }
        else {
            skycol += (1.0 - cave) * mix(SUNCOL_M, SUNCOL_L, pow(abs(sdu), 0.1)) * get_sun_point(rayDir, adjustedSun);
            skycol += (1.0 - cave) * mix(MOONCOL_M, MOONCOL_L, abs(mdu)) * get_moon_point(rayDir, adjustedMoon);
        }
    }
    
    vec4 candidate = vec4(skycol, 1.0);
    if (!oob && dtmp + SSR_IGNORETHRESH > fragdepth && linearize_depth(pos.z) < dtmp + SSR_INVALIDTHRESH) {
        vec3 colortmp = texture(DiffuseSampler, 0.5 * pos.xy + vec2(0.5)).rgb;

        float count = 1.0;
        float dtmptmp = 0.0;
        vec2 postmp = vec2(0.0);

        for (int i = 0; i < SSR_BLURTAPS; i += 1) {
            postmp = pos.xy + randsamples[i + SSR_BLURSAMPLEOFFSET] * SSR_BLURR * vec2(1.0 / aspectRatio, 1.0);
            dtmptmp = linearize_depth(texture(DiffuseDepthSampler, 0.5 * postmp + vec2(0.5)).r);
            if (abs(dtmp - dtmptmp) < SSR_IGNORETHRESH) {
                vec3 tmpcolortmp = texture(DiffuseSampler, 0.5 * postmp + vec2(0.5)).rgb;
                colortmp += tmpcolortmp;
                count += 1.0;
            }
        }
        
        colortmp /= count;

        if (dtmp >= far - FUDGE) {
            // add sun and moon if visible
            vec3 adjustedSun = normalize(sunDir * far - fragpos);
            if (sdu > 0.0) {
                colortmp += (1.0 - cave) * mix(SUNCOL_M, SUNCOL_H, abs(sdu)) * get_sun_point(rayDir, adjustedSun);
            }
            else {
                colortmp += (1.0 - cave) * mix(SUNCOL_M, SUNCOL_L, pow(abs(sdu), 0.1)) * get_sun_point(rayDir, adjustedSun);
            }
        }

        candidate = vec4(colortmp, 1.0);
    }

    candidate = mix(candidate, vec4(skycol, 1.0), clamp(pow(max(abs(pos.x), abs(pos.y)), 16.0), 0.0, 1.0));
    return candidate;
}

vec4 SSR_basic(vec3 fragpos, vec3 dir, float fragdepth, vec3 surfacenorm) {
    vec3 rayDir = reflect(normalize(dir), surfacenorm);
    vec3 skycol = fogColor.rgb;
    if (underWater < 0.5 && abs(dim - DIM_OVER) < 0.01) {
        skycol = get_atmospheric_scattering(fogColor, skyColor, rayDir, sunDir, sdu, rain, false);
        skycol = mix(skycol, fogColor.rgb, cave);

        // add sun and moon if visible
        vec3 adjustedSun = normalize(sunDir * far - fragpos);
        vec3 adjustedMoon = normalize(moonDir * far - fragpos);
        if (sdu > 0.0) {
            skycol += (1.0 - cave) * mix(SUNCOL_M, SUNCOL_H, abs(sdu)) * get_sun_point(rayDir, adjustedSun);
            skycol += (1.0 - cave) * mix(MOONCOL_M, MOONCOL_H, pow(abs(mdu), 0.1)) * get_moon_point(rayDir, adjustedMoon);
        }
        else {
            skycol += (1.0 - cave) * mix(SUNCOL_M, SUNCOL_L, pow(abs(sdu), 0.1)) * get_sun_point(rayDir, adjustedSun);
            skycol += (1.0 - cave) * mix(MOONCOL_M, MOONCOL_L, abs(mdu)) * get_moon_point(rayDir, adjustedMoon);
        }
    }
    return vec4(skycol, 1.0);
}

float get_fresnel(float n0, float n1, float theta0) {
    float snell = n0 / n1 * sin(theta0);
    if (snell >= 1.0) {
        return 1.0;
    }

    float theta1 = asin(snell);
    float costheta0 = cos(theta0);
    float costheta1 = cos(theta1);
    float rs = (n0 * costheta0 - n1 * costheta1) / (n0 * costheta0 + n1 * costheta1);
    float rp = (n0 * costheta1 - n1 * costheta0) / (n0 * costheta1 + n1 * costheta0);

    return (rs * rs + rp * rp) / 2;
}

void main() {
    vec4 outColor = vec4(0.0);
    vec4 color = texture(TranslucentSampler, texCoord);

    if (color.a > 0.0) {
        float ldepth = texture(TranslucentDepthSampler, texCoord).r;
        float lineardepth = linearize_depth(ldepth);
        float ldepth2 = (texture(TranslucentDepthSampler, texCoord + vec2(0.0, oneTexel.y)).r);
        float ldepth3 = (texture(TranslucentDepthSampler, texCoord + vec2(oneTexel.x, 0.0)).r);
        float ldepth4 = (texture(TranslucentDepthSampler, texCoord - vec2(0.0, oneTexel.y)).r);
        float ldepth5 = (texture(TranslucentDepthSampler, texCoord - vec2(oneTexel.x, 0.0)).r);
        float gdepth2 = (texture(DiffuseDepthSampler, texCoord + vec2(0.0, oneTexel.y)).r);
        float gdepth3 = (texture(DiffuseDepthSampler, texCoord + vec2(oneTexel.x, 0.0)).r);
        float gdepth4 = (texture(DiffuseDepthSampler, texCoord - vec2(0.0, oneTexel.y)).r);
        float gdepth5 = (texture(DiffuseDepthSampler, texCoord - vec2(oneTexel.x, 0.0)).r);


        vec2 scaledCoord = 2.0 * (texCoord - vec2(0.5));
        vec3 fragpos = back_project(vec4(scaledCoord, ldepth, 1.0)).xyz;

        vec3 p2 = back_project(vec4(scaledCoord + 2.0 * vec2(0.0, oneTexel.y), ldepth2, 1.0)).xyz;
        p2 = p2 - fragpos;
        vec3 p3 = back_project(vec4(scaledCoord + 2.0 * vec2(oneTexel.x, 0.0), ldepth3, 1.0)).xyz;
        p3 = p3 - fragpos;
        vec3 p4 = back_project(vec4(scaledCoord - 2.0 * vec2(0.0, oneTexel.y), ldepth4, 1.0)).xyz;
        p4 = p4 - fragpos;
        vec3 p5 = back_project(vec4(scaledCoord - 2.0 * vec2(oneTexel.x, 0.0), ldepth5, 1.0)).xyz;
        p5 = p5 - fragpos;

        bool p2v = ldepth2 < gdepth2 && length(p2) < length(NORMAL_DEPTH_REJECT * fragpos) && texCoord.y + oneTexel.y < 1.0;
        bool p3v = ldepth3 < gdepth3 && length(p3) < length(NORMAL_DEPTH_REJECT * fragpos);
        bool p4v = ldepth4 < gdepth4 && length(p4) < length(NORMAL_DEPTH_REJECT * fragpos) && texCoord.y - oneTexel.y > 0.0;
        bool p5v = ldepth5 < gdepth5 && length(p5) < length(NORMAL_DEPTH_REJECT * fragpos);

        vec3 normal = normalize(cross(p2, p3)) * float(p2v && p3v)
                    + normalize(cross(-p4, p3)) * float(p4v && p3v) 
                    + normalize(cross(p2, -p5)) * float(p2v && p5v) 
                    + normalize(cross(-p4, -p5)) * float(p4v && p5v);

        normal = length(normal) < 0.9 ? vec3(0.0, 1.0, 0.0) : normalize(-normal);

        vec2 alignedSmoothing = oneTexel * vec2(ivec2(OutSize * vec2(aspectRatio * NORMAL_SMOOTHING, NORMAL_SMOOTHING)));
        float smoothingNY = clamp(texCoord.y - oneTexel.y * 0.5, 0.0, alignedSmoothing.y);
        float smoothingPY = clamp(1.0 - texCoord.y - oneTexel.y * 0.5, 0.0, alignedSmoothing.y);

        float ldepth6 = (texture(TranslucentDepthSampler, texCoord + vec2(0.0, smoothingPY)).r);
        float ldepth7 = (texture(TranslucentDepthSampler, texCoord + vec2(alignedSmoothing.x, 0.0)).r);
        float ldepth8 = (texture(TranslucentDepthSampler, texCoord - vec2(0.0, smoothingNY)).r);
        float ldepth9 = (texture(TranslucentDepthSampler, texCoord - vec2(alignedSmoothing.x, 0.0)).r);
        float gdepth6 = (texture(DiffuseDepthSampler, texCoord + vec2(0.0, smoothingPY)).r);
        float gdepth7 = (texture(DiffuseDepthSampler, texCoord + vec2(alignedSmoothing.x, 0.0)).r);
        float gdepth8 = (texture(DiffuseDepthSampler, texCoord - vec2(0.0, smoothingNY)).r);
        float gdepth9 = (texture(DiffuseDepthSampler, texCoord - vec2(alignedSmoothing.x, 0.0)).r);

        vec3 p6 = back_project(vec4(scaledCoord + 2.0 * vec2(0.0, smoothingPY), ldepth6, 1.0)).xyz;
        p6 = p6 - fragpos;
        vec3 p7 = back_project(vec4(scaledCoord + 2.0 * vec2(alignedSmoothing.x, 0.0), ldepth7, 1.0)).xyz;
        p7 = p7 - fragpos;
        vec3 p8 = back_project(vec4(scaledCoord - 2.0 * vec2(0.0, smoothingNY), ldepth8, 1.0)).xyz;
        p8 = p8 - fragpos;
        vec3 p9 = back_project(vec4(scaledCoord - 2.0 * vec2(alignedSmoothing.x, 0.0), ldepth9, 1.0)).xyz;
        p9 = p9 - fragpos;

        bool p6v = ldepth6 < gdepth6 && length(p6) < length(NORMAL_DEPTH_REJECT * fragpos) && length(p6) > length(NORMAL_DEPTH_REJECT_L * fragpos);
        bool p7v = ldepth7 < gdepth7 && length(p7) < length(NORMAL_DEPTH_REJECT * fragpos) && length(p7) > length(NORMAL_DEPTH_REJECT_L * fragpos);
        bool p8v = ldepth8 < gdepth8 && length(p8) < length(NORMAL_DEPTH_REJECT * fragpos) && length(p8) > length(NORMAL_DEPTH_REJECT_L * fragpos);
        bool p9v = ldepth9 < gdepth9 && length(p9) < length(NORMAL_DEPTH_REJECT * fragpos) && length(p9) > length(NORMAL_DEPTH_REJECT_L * fragpos);

        vec3 normalsmooth = normalize(cross(p6, p7)) * float(p6v && p7v) 
                            + normalize(cross(-p8, p7)) * float(p8v && p7v) 
                            + normalize(cross(p6, -p9)) * float(p6v && p9v) 
                            + normalize(cross(-p8, -p9)) * float(p8v && p9v);

        if (normalsmooth != vec3(0.0)) {
            normalsmooth = normalize(-normalsmooth);
            normal = mix(normal, normalsmooth, clamp(smoothstep(0.7, 0.9, dot(normal, normalsmooth)) + smoothstep(0.0, 0.1, dot(-normalize(fragpos), normal)), 0.0, 1.0));
            normal = normalize(normal);
        }

        vec4 reflection = vec4(0.0);

        float fresnel = 0.0;
        float indexair = 1.0;
        float indexwater = 1.333;

        if (SSRLevel > 1.5) {
            vec4 r = vec4(0.0);
            for (int i = 0; i < SSR_TAPS; i += 1) {
                r += SSR(fragpos, back_project(vec4(scaledCoord, 1.0, 1.0)).xyz, linearize_depth(ldepth), normalize(normal + NORMAL_SCATTER * (normalize(p2) * poissonDisk[i].x + normalize(p3) * poissonDisk[i].y)), poissonDisk);
            }
            reflection = r / SSR_TAPS;
        }
        else if (SSRLevel > 0.5) {
            reflection = SSR_basic(fragpos, back_project(vec4(scaledCoord, 1.0, 1.0)).xyz, linearize_depth(ldepth), normal);
        }

        float theta = acos(clamp(dot(normalize(fragpos), -normal), -1.0, 1.0));
        fresnel = get_fresnel(indexair, indexwater, theta);

        float maxelem = max(reflection.r, max(reflection.g, reflection.b));
        if (maxelem > 1.0) {
            float scale = min(maxelem, 1.0 / (fresnel + 0.001));
            reflection.rgb /= scale;
            fresnel *= scale;
        }
        fresnel = min(fresnel, reflection.a);

        outColor = vec4(reflection.rgb, fresnel);
    }

    fragColor = outColor;
}
