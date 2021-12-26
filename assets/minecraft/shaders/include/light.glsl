#version 150

#define MINECRAFT_LIGHT_POWER   (0.6)
#define MINECRAFT_AMBIENT_LIGHT (0.4)

vec4 minecraft_mix_light(vec3 lightDir0, vec3 lightDir1, vec3 normal, vec4 color) {
    lightDir0 = normalize(lightDir0);
    lightDir1 = normalize(lightDir1);
    float light0 = max(0.0, dot(lightDir0, normal));
    float light1 = max(0.0, dot(lightDir1, normal));
    float lightAccum = min(1.0, (light0 + light1) * MINECRAFT_LIGHT_POWER + MINECRAFT_AMBIENT_LIGHT);
    return vec4(color.rgb * lightAccum, color.a);
}

#define NCOLOR normalize(vec3(0.0, 0.0, 1.0))
#define DCOLOR normalize(vec3(1.0))

float getSun(sampler2D lightMap) {
    vec3 sunlight = normalize(texture(lightMap, vec2(0.5 / 16.0, 15.5 / 16.0)).rgb);
    return clamp(pow(length(sunlight - NCOLOR) / length(DCOLOR - NCOLOR), 4.0), 0.0, 1.0);
}

vec4 minecraft_sample_lightmap(sampler2D lightMap, ivec2 uv) {
    float sun = uv.y / 256.0 * getSun(lightMap);
    float torch = uv.x / 256.;
    vec4 light = texture(lightMap, clamp(uv / 256.0, vec2(0.8 / 16.0), vec2(15.5 / 16.0)));

    //warmer blocklight
    light *= mix(vec4(1.0), vec4(1.7, 1.0, 0.4, 1.0), torch * (1.0-sun));

    //darker shadows
    light *= mix(vec4(1.0), vec4(0.0, 0.1, 0.8, 1.0), max(1.0 - (torch + sun), 0.0));

    return light;
}