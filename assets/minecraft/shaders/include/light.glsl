#version 330

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

float getSun(sampler2D lightmap) {
    vec3 sunlight = normalize(texture(lightmap, vec2(0.5 / 16.0, 15.5 / 16.0)).rgb);
    return clamp(pow(length(sunlight - NCOLOR) / length(DCOLOR - NCOLOR), 4.0), 0.0, 1.0);
}

vec4 getlight(sampler2D lightmap, ivec2 uv) {
    float sun = uv.y / 256. * getSun(lightmap);
    float torch = uv.x / 256.;
    vec4 light = texture(lightmap, clamp(uv / 256.0, vec2(0.5 / 16.0), vec2(15.5 / 16.0)));

    vec3 map = texelFetch(lightmap, ivec2(0), 0).rgb;
    //warmer blocklight (torch AND (NOT sun))
    light *= mix(vec4(1.0), vec4(1.7, 1.0, 0.5, 1.0), torch * (1.0-sun));
    //shadows colors (NOT (torch OR sun))
    if (map.r == map.g && map.g == map.b) { //bluer shadows in overworld
        light *= mix(vec4(1.0), vec4(0.2, 0.2, 0.8, 1.0), max(1.0 - (torch + sun), 0.0));
    } else if (map.r > map.g) { //redder shadows in nether
        light *= mix(vec4(1.0), vec4(0.9, 0.6, 0.5, 1.0), max(1.0 - (torch + sun), 0.0));
    } else { //purple shadows in end
        light *= mix(vec4(1.0), vec4(0.8, 0.5, 0.8, 1.0), max(1.0 - (torch + sun), 0.0));
    }
    return light;
}

float luma(vec4 color) {return dot(color.rgb,vec3(0.2126, 0.7152, 0.0722));}

#define EMISSIVE_ALPHA 252./255.
vec4 emissive(vec4 color, vec4 light, float dist) {
    vec4 cl = color * light;
    float lum = luma(light);
    if (color.a - EMISSIVE_ALPHA < 0.001) {
        return mix(color, cl, lum);
    }
    //small light around camera
    dist = 1. - clamp(dist-1, 0.0, 5.0)/5.0;
    color.rgb *= (light.rgb + (1-lum) * dist / 20);
    return color;
}