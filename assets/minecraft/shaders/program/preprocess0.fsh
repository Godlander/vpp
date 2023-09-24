#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D PrevDataSampler;
uniform sampler2D PrevMainSampler;
uniform sampler2D CurrMainSampler;
uniform sampler2D CurrMainSamplerDepth;

uniform vec2 InSize;
uniform vec2 AuxSize0;
uniform float FOVGuess;

out vec4 fragColor;

// moj_import doesn't work in post-process shaders ;_; Felix pls fix
#define FPRECISION 4000000.0
#define FPRECISION_L 400000.0
#define PROJNEAR 0.05
#define PROJFAR 1024.0
#define PI 3.1415926535897932
#define FUDGE 32.0

#define DIM_UNKNOWN 0
#define DIM_OVER 1
#define DIM_END 2
#define DIM_NETHER 3
#define DIM_MAX 3

#define FOG_NETHER_GAIN vec3(0.14, 0.08, 0.02)
#define FOG_CAVE vec3(38.0 / 255.0, 38.0 / 255.0, 51.0 / 255.0)
#define FOG_DEFAULT_WATER vec3(25.0 / 255.0, 25.0 / 255.0, 255.0 / 255.0)
#define TINT_WATER vec3(0.0 / 255.0, 248.0 / 255.0, 255.0 / 255.0)
#define FOG_WATER vec3(0.0 / 255.0, 42.0 / 255.0, 42.0 / 255.0)
#define FOG_WATER_FAR 72.0
#define FOG_END vec3(19.0 / 255.0, 16.0 / 255.0, 19.0 / 255.0)
#define FOG_LAVA vec3(153.0 / 255.0, 25.0 / 255.0, 0.0)
#define FOG_LAVA_FAR 2.0
#define FOG_SNOW vec3(159.0 / 255.0, 187.0 / 255.0, 200.0 / 255.0)
#define FOG_SNOW_FAR 2.0
#define FOG_BLIND vec3(0.0)
#define FOG_BLIND_FAR 5.0
#define FOG_DARKNESS vec3(0.0)
#define FOG_DARKNESS_FAR 15.0
#define FOG_DEFAULT_FAR 150.0
#define FOG_TARGET 0.2
#define FOG_DIST_OVERCAST_REDUCE 2.0

#define FLAG_UNDERWATER 1<<0

#define EXPOSURE_SAMPLES 7
#define EXPOSURE_RADIUS 0.25
#define EXPOSURE_BIG_PRIME 7507

#define AL_SAMPLES 8
#define AL_RADIUS 0.25
#define AL_BIG_PRIME 7507

const vec2 offsets[9] = vec2[9](vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0), vec2(1.0, 1.0), vec2(-1.0, 1.0), vec2(-1.0, -1.0), vec2(1.0, -1.0));

const vec2 poissonDisk[64] = vec2[64](
    vec2(-0.613392, 0.617481), vec2(0.170019, -0.040254), vec2(-0.299417, 0.791925), vec2(0.645680, 0.493210), vec2(-0.651784, 0.717887), vec2(0.421003, 0.027070), vec2(-0.817194, -0.271096), vec2(-0.705374, -0.668203), 
    vec2(0.977050, -0.108615), vec2(0.063326, 0.142369), vec2(0.203528, 0.214331), vec2(-0.667531, 0.326090), vec2(-0.098422, -0.295755), vec2(-0.885922, 0.215369), vec2(0.566637, 0.605213), vec2(0.039766, -0.396100),
    vec2(0.751946, 0.453352), vec2(0.078707, -0.715323), vec2(-0.075838, -0.529344), vec2(0.724479, -0.580798), vec2(0.222999, -0.215125), vec2(-0.467574, -0.405438), vec2(-0.248268, -0.814753), vec2(0.354411, -0.887570),
    vec2(0.175817, 0.382366), vec2(0.487472, -0.063082), vec2(-0.084078, 0.898312), vec2(0.488876, -0.783441), vec2(0.470016, 0.217933), vec2(-0.696890, -0.549791), vec2(-0.149693, 0.605762), vec2(0.034211, 0.979980),
    vec2(0.503098, -0.308878), vec2(-0.016205, -0.872921), vec2(0.385784, -0.393902), vec2(-0.146886, -0.859249), vec2(0.643361, 0.164098), vec2(0.634388, -0.049471), vec2(-0.688894, 0.007843), vec2(0.464034, -0.188818),
    vec2(-0.440840, 0.137486), vec2(0.364483, 0.511704), vec2(0.034028, 0.325968), vec2(0.099094, -0.308023), vec2(0.693960, -0.366253), vec2(0.678884, -0.204688), vec2(0.001801, 0.780328), vec2(0.145177, -0.898984),
    vec2(0.062655, -0.611866), vec2(0.315226, -0.604297), vec2(-0.780145, 0.486251), vec2(-0.371868, 0.882138), vec2(0.200476, 0.494430), vec2(-0.494552, -0.711051), vec2(0.612476, 0.705252), vec2(-0.578845, -0.768792),
    vec2(-0.772454, -0.090976), vec2(0.504440, 0.372295), vec2(0.155736, 0.065157), vec2(0.391522, 0.849605), vec2(-0.620106, -0.328104), vec2(0.789239, -0.419965), vec2(-0.545396, 0.538133), vec2(-0.178564, -0.596057));

float linearize_depth(float depth) {
    return (2.0 * PROJNEAR * PROJFAR) / (PROJFAR + PROJNEAR - depth * (PROJFAR - PROJNEAR));    
}

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

vec3 encode_float(float f) {
    return encode_int(int(f * FPRECISION));
}

float decode_float(vec3 vec) {
    return decode_int(vec) / FPRECISION;
}

vec3 encode_floatL(float f) {
    return encode_int(int(f * FPRECISION_L));
}

float decode_floatL(vec3 vec) {
    return decode_int(vec) / FPRECISION_L;
}

float luma(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
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

void main() {

    //simply decoding all the control data and constructing the sunDir, ProjMat, ModelViewMat
    vec4 outColor = vec4(0.0);
    vec2 start = get_control(0, InSize);
    vec2 startData = 0.5 / AuxSize0;
    vec2 inc = vec2(2.0 / InSize.x, 0.0);
    vec2 incData = vec2(1.0 / AuxSize0.x, 0.0);
    vec4 temp = texture(DiffuseSampler, start + CTL_FOGCOLOR * inc);
    int index = int(gl_FragCoord.x);

    if (index >= CTL_EXP0) {
        if (index >= CTL_EXP0 && index <= CTL_EXP8) {
            vec2 offset = offsets[index - CTL_EXP0];
            float lum = 0.0;
            for (int i = 0; i < EXPOSURE_SAMPLES; i += 1) {
                lum += luma(texture(PrevMainSampler, EXPOSURE_RADIUS * (offset + poissonDisk[(i + (index - CTL_EXP0) * EXPOSURE_SAMPLES) % 64] * 0.75) + vec2(0.5)).rgb);
            }
            lum = lum / EXPOSURE_SAMPLES - 20.0; // Fixed point L only supports [-20, 20] so subtract 20
            outColor = vec4(encode_floatL(clamp(lum, -20.0, 20.0)), 1.0); 
        }
        else if (index == CTL_EXPAVG) {
            float lum = decode_floatL(texture(PrevDataSampler, startData + CTL_EXP0 * incData).rgb)
                      + decode_floatL(texture(PrevDataSampler, startData + CTL_EXP1 * incData).rgb)
                      + decode_floatL(texture(PrevDataSampler, startData + CTL_EXP2 * incData).rgb)
                      + decode_floatL(texture(PrevDataSampler, startData + CTL_EXP3 * incData).rgb)
                      + decode_floatL(texture(PrevDataSampler, startData + CTL_EXP4 * incData).rgb)
                      + decode_floatL(texture(PrevDataSampler, startData + CTL_EXP5 * incData).rgb)
                      + decode_floatL(texture(PrevDataSampler, startData + CTL_EXP6 * incData).rgb)
                      + decode_floatL(texture(PrevDataSampler, startData + CTL_EXP7 * incData).rgb)
                      + decode_floatL(texture(PrevDataSampler, startData + CTL_EXP8 * incData).rgb);

            lum /= 9.0;

            lum += 20.0 - 2.0; // convert from fixed point L to regular fixed point

            vec4 last = texture(PrevDataSampler, startData + CTL_EXPAVG * incData);
            if (last.a == 1.0) {
                lum = mix(lum, decode_float(last.rgb), 0.98);
            }
            outColor = vec4(encode_float(clamp(lum, -2.0, 2.0)), 1.0);
        }
        else if (index >= CTL_APPLYLIGHT0 && index <= CTL_APPLYLIGHT4) {
            vec2 offset = offsets[index - CTL_APPLYLIGHT0];
            float lightAvg = 0.0;
            for (int i = 0; i < AL_SAMPLES; i += 1) {
                vec2 coords = AL_RADIUS * (offset + poissonDisk[(i + (index - CTL_APPLYLIGHT0) * AL_SAMPLES) % 64]) + vec2(0.5);
                float depth = texture(CurrMainSamplerDepth, coords).r;
                if (linearize_depth(depth) < PROJFAR - FUDGE) {
                    lightAvg += float(int(round(texture(CurrMainSampler, coords).a * 255.0)) % 2 == 0);
                }
                else {
                    lightAvg += 1.0;
                }
            }
            lightAvg = lightAvg / AL_SAMPLES;
            outColor = vec4(encode_float(clamp(lightAvg, 0.0, 1.0)), 1.0);
        }
        else if (index == CTL_APPLYLIGHTAVG) {
            float al = decode_float(texture(PrevDataSampler, startData + CTL_APPLYLIGHT0 * incData).rgb)
                     + decode_float(texture(PrevDataSampler, startData + CTL_APPLYLIGHT1 * incData).rgb)
                     + decode_float(texture(PrevDataSampler, startData + CTL_APPLYLIGHT2 * incData).rgb)
                     + decode_float(texture(PrevDataSampler, startData + CTL_APPLYLIGHT3 * incData).rgb)
                     + decode_float(texture(PrevDataSampler, startData + CTL_APPLYLIGHT4 * incData).rgb);
            al /= 5.0;

            vec4 last = texture(PrevDataSampler, startData + CTL_APPLYLIGHTAVG * incData);
            vec4 currflags = texture(PrevDataSampler, startData + CTL_MISCFLAGS * incData);
            if (currflags.a == 1.0 && (int(currflags.r * 255.0) & FLAG_UNDERWATER) > 0) {
                al = decode_float(last.rgb);
            }
            else if (last.a == 1.0) {
                al = mix(al, decode_float(last.rgb), 0.99);
            }
            outColor = vec4(encode_float(clamp(al, 0.0, 1.0)), 1.0); // [0.6, 1.0] to reduce inertia for cave checks
        }
        else if (index == CTL_CAVE) {
            outColor = vec4(encode_float(smoothstep(3.0, 2.0, decode_float(texture(PrevDataSampler, startData + CTL_EXPAVG * incData).rgb) + 2.0) 
                                      * smoothstep(0.9, 0.6, decode_float(texture(PrevDataSampler, startData + CTL_APPLYLIGHTAVG * incData).rgb))), 
                            1.0);
        }
    }
    else if (temp.a < 1.0) {

        /* Basic Matricies as follows
        tanVFOV = tan(FOVGuess * PI / 180.0 / 2.0);
        tanHFOV = tanVFOV * InSize.x / InSize.y;
        ProjMat = mat4(tanHFOV, 0.0,     0.0,                                               0.0,
                       0.0,     tanVFOV, 0.0,                                               0.0,
                       0.0,     0.0,    -(PROJFAR + PROJNEAR) / (PROJFAR - PROJNEAR),      -1.0,
                       0.0,     0.0,    -2.0 * (PROJFAR * PROJNEAR) / (PROJFAR - PROJNEAR), 0.0);
        ModelViewMat = mat4(1.0);
        */
        if (index == CTL_SUNDIRX || index == CTL_SUNDIRZ) {
            outColor = vec4(encode_float(0.0), 0.0);
        }
        else if (index == CTL_SUNDIRY) {
            outColor = vec4(encode_float(-1.0), 0.0);
        }
        else if (index == CTL_ATAN_PMAT00) {
            outColor = vec4(encode_float(FOVGuess * PI / 180.0 / 2.0), 0.0);
        }
        else if (index == CTL_ATAN_PMAT11) {
            outColor = vec4(encode_float(atan(tan(FOVGuess * PI / 180.0 / 2.0) * InSize.x / InSize.y)), 0.0);
        }
        else if (index == CTL_PMAT22) {
            outColor = vec4(encode_float(-(PROJFAR + PROJNEAR) / (PROJFAR - PROJNEAR)), 0.0);
        }
        else if (index == CTL_PMAT23) {
            outColor = vec4(encode_float(-1.0), 0.0);
        }
        else if (index == CTL_PMAT32) {
            outColor = vec4(encode_float(-2.0 * (PROJFAR * PROJNEAR) / (PROJFAR - PROJNEAR)), 0.0);
        }
        else if (index == CTL_MVMAT00 || index == CTL_MVMAT11 || index == CTL_MVMAT22) {
            outColor = vec4(encode_float(1.0), 0.0);
        }
        // fog color
        else if (index == CTL_FOGCOLOR) {
            outColor = temp;
        }
        else if (index == CTL_FOGSTART) {
            outColor = vec4(encode_int(0), 0.0);
        }
        else if (index == CTL_FOGEND) {
            float range = FOG_DEFAULT_FAR;
            float lava = smoothstep(0.05, 0.0, length(temp.rgb - FOG_LAVA));
            range = mix(range, FOG_LAVA_FAR, lava);
            float snow = smoothstep(0.05, 0.0, length(temp.rgb - FOG_SNOW));
            range = mix(range, FOG_SNOW_FAR, snow);
            float blind = smoothstep(0.05, 0.0, length(temp.rgb - FOG_DARKNESS));
            range = mix(range, FOG_DARKNESS_FAR, blind);
            outColor = vec4(encode_int(int(round(range))), 0.0);
        }
        else if (index == CTL_DIM) {
            outColor = texture(PrevDataSampler, startData + CTL_DIM * incData);
            if(outColor.a != 1.0 || int(outColor.r * 255.0) > DIM_MAX || outColor.r == 0.0) {
                vec4 dimtmp = texture(DiffuseSampler, start + CTL_DIM * inc);
                if (dimtmp.a == 1.0) {
                    outColor = dimtmp;
                }
                else if(length(temp.rgb - FOG_END) < 0.005) {
                    outColor = vec4(vec3(float(DIM_END) / 255.0), 1.0);
                }
                else {
                    outColor = vec4(0.0, 0.0, 0.0, 1.0);
                }
            }
        }
        else if (index == CTL_MISCFLAGS) {
            int currflags = 0;
            vec4 dimtmp = texture(PrevDataSampler, startData + CTL_DIM * incData);
            float dim = DIM_UNKNOWN;
            if (dimtmp.a == 1.0) {
                dim = int(dimtmp.r * 255.0);
            }
            if (((dim == DIM_UNKNOWN || dim == DIM_END) && temp.b > 0.2) || (dim == DIM_NETHER && temp.b > temp.g * 9.0)) {
                currflags |= FLAG_UNDERWATER;
                outColor = vec4(float(currflags) / 255.0, 0.0, 0.0, 1.0);
            }
            else if (dim == DIM_OVER) {
                outColor = texture(PrevDataSampler, startData + CTL_MISCFLAGS * incData);
            }
        }
        else if (index == CTL_FARCLIP) {
            outColor = vec4(encode_int(int(PROJFAR)), 1.0);
        }
        // base case zero
        else {
            outColor = vec4(0.0);
        }
    }
    else {
        if (index == CTL_DIM) {
            outColor = texture(PrevDataSampler, startData + CTL_DIM * incData);
            if (outColor.a != 1.0 || int(outColor.r * 255.0) > DIM_MAX || outColor.r == 0.0) {
                outColor = texture(DiffuseSampler, start + CTL_DIM * inc);
            }
        }
        else if (index == CTL_MISCFLAGS) {
            int currflags = int(texture(DiffuseSampler, start + CTL_MISCFLAGS * inc).r * 255.0);
            int fstart = decode_int(texture(DiffuseSampler, start + CTL_FOGSTART * inc).rgb);
            if (fstart == -8) {
                currflags |= FLAG_UNDERWATER;
            }
            outColor = vec4(float(currflags) / 255.0, 0.0, 0.0, 1.0);
        }
        // base case passthrough
        else {
            outColor = texture(DiffuseSampler, start + float(index) * inc);
        }
    }
    
    fragColor = outColor;
}
