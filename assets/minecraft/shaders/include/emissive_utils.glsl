#version 150

bool rougheq(float a, float b) {
    return (abs(a - b) < 1.);
}

bool rougheq(vec3 a, vec3 b) {
    return (rougheq(a.x,b.x) && rougheq(a.y,b.y) && rougheq(a.z,b.z));
}

vec4 greater(vec4 a, vec4 b) {
    a.r = max(a.r, b.r);
    a.g = max(a.g, b.g);
    a.b = max(a.b, b.b);
    a.a = 1.0;
    return a;
}

vec4 make_emissive(vec4 inputColor, vec4 lightColor, float vertexDistance, float inputAlpha) {
    if (rougheq(inputAlpha, 252.0)) {
        return greater(inputColor, inputColor * lightColor);
    }
    return inputColor * lightColor;
}
vec4 apply_lightmap(vec4 inputColor, vec4 lightMapColor, float vertexDistance, float inputAlpha) {
    if (rougheq(inputAlpha, 252.0)) {
        return greater(inputColor, inputColor * lightMapColor);
    }
    return inputColor * lightMapColor;
}