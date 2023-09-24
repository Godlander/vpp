#version 330

#define FOG_END vec3(19.0 / 255.0, 16.0 / 255.0, 19.0 / 255.0)
#define FOG_LAVA vec3(153.0 / 255.0, 25.0 / 255.0, 0.0)
#define FOG_SNOW vec3(159.0 / 255.0, 187.0 / 255.0, 200.0 / 255.0)
#define FOG_BLIND vec3(0.0)
#define FOG_DARKNESS vec3(0.0)

#ifndef DIM_NETHER
#define DIM_NETHER  3
#endif

vec4 linear_fog(vec4 inColor, float fogDistance, float fogStart, float fogEnd, vec4 fogColor) {
    if (fogDistance <= fogStart) {
        return inColor;
    }
    float fogValue = fogDistance < fogEnd ? smoothstep(fogStart, fogEnd, fogDistance) : 1.0;
    return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a);
}

vec4 linear_fog_translucent(vec4 inColor, float fogDistance, float fogStart, float fogEnd, vec4 fogColor) {
    if (fogDistance <= fogStart) {
        return inColor;
    }
    float fogValue = fogDistance < fogEnd ? smoothstep(fogStart, fogEnd, fogDistance) : 1.0;
    return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a*(1.0-fogValue));
}

float linear_fog_fade(float fogDistance, float fogStart, float fogEnd) {
    if (fogDistance <= fogStart) {
        return 1.0;
    } else if (fogDistance >= fogEnd) {
        return 0.0;
    }
    return smoothstep(fogEnd, fogStart, fogDistance);
}

float fog_distance(mat4 modelViewMat, vec3 pos, int shape) {
    if (shape == 0) {
        return length((modelViewMat * vec4(pos, 1.0)).xyz);
    } else {
        float distXZ = length((modelViewMat * vec4(pos.x, 0.0, pos.z, 1.0)).xyz);
        float distY = length((modelViewMat * vec4(0.0, pos.y, 0.0, 1.0)).xyz);
        return max(distXZ, distY);
    }
}

float fog_end_comp(vec4 fogColor, float fogStart, float fogEnd, float fogEndTarget, int dim) {
    if (dim == DIM_NETHER && fogStart >= 0.0) {
        float val = smoothstep(0.0, 0.05, length(fogColor.rgb - FOG_BLIND)) * smoothstep(0.0, 0.05, length(fogColor.rgb - FOG_LAVA)) * smoothstep(0.0, 0.05, length(fogColor.rgb - FOG_SNOW));
        fogEnd = mix(fogEnd, max(fogEndTarget, fogEnd), val);
    }
    return fogEnd;
}

//backwards compatibility for pre 1.18.2 fog
float cylindrical_distance(mat4 ModelViewMat, vec3 pos) {
    float distXZ = length((ModelViewMat * vec4(pos.x, 0.0, pos.z, 1.0)).xyz);
    float distY = length((ModelViewMat * vec4(0.0, pos.y, 0.0, 1.0)).xyz);
    return max(distXZ, distY);
}