#version 150

vec3 rgbhsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsvrgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

bool rougheq(float a, float b, float acc) {
    return (abs(a - b) < acc);
}

bool rougheq(vec3 a, vec3 b, float acc) {
    return (lessThan(a,b+acc)==bvec3(true) && lessThan(b-acc,a)==bvec3(true));
}

const vec2[4] corners = vec2[4](
    vec2(0, 1),vec2(0, 0),vec2(1, 0),vec2(1, 1)
);

float luma(vec4 color){
    return dot(color.rgb,vec3(0.2126, 0.7152, 0.0722));
}

vec4 greater(vec4 a, vec4 b) {
    return mix(a,b, luma(b));
}

vec4 make_emissive(vec4 color, vec4 lightColor, float dist, float alpha) {
    if (abs(alpha - 252.0) < 1.0) {
        return greater(color, color * lightColor);
    }
    dist = 1. - clamp(dist-1, 0.0, 5.0)/5.0;
    color.rgb *= (lightColor.rgb + (1-luma(lightColor)) * dist / 20);
    return color;
}