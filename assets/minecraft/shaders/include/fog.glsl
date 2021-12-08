#version 150

vec4 linear_fog(vec4 inColor, float vertexDistance, float fogStart, float fogEnd, vec4 fogColor) {
    fogStart *= 0.8;
    if (vertexDistance <= fogStart) {
        return inColor;
    }
    float fogValue = vertexDistance < fogEnd ? smoothstep(fogStart, fogEnd, vertexDistance) : 1.0;
    return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a);
}

vec4 linear_fog_translucent(vec4 inColor, float vertexDistance, float fogStart, float fogEnd, vec4 fogColor) {
    fogEnd *= 0.9;
    fogStart *= 0.7;
    if (vertexDistance <= fogStart) {
        return inColor;
    }
    float fogValue = vertexDistance < fogEnd ? smoothstep(fogStart, fogEnd, vertexDistance) : 1.0;
    return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a*(1.0-fogValue));
}

float linear_fog_fade(float vertexDistance, float fogStart, float fogEnd) {
    fogStart *= 0.8;
    if (vertexDistance <= fogStart) {
        return 1.0;
    } else if (vertexDistance >= fogEnd) {
        return 0.0;
    }
    return smoothstep(fogEnd, fogStart, vertexDistance);
}