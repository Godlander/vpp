#version 330

uniform sampler2D DiffuseSampler;
uniform float Level;

in vec2 texCoord;
in vec2 oneTexel;

out vec4 fragColor;

#define CLAMP_EDGE oneTexel * 0.55
vec2 clampInBound(vec2 coords, float bound) {
    return clamp(coords, vec2(bound, 0.0) + CLAMP_EDGE, vec2(2.0 * bound, bound) - CLAMP_EDGE);
}

void main() {
    vec4 outColor;
    float bound = pow(0.5, Level);
    if (texCoord.x > bound && texCoord.x < 2.0 * bound && texCoord.y > 0.0 && texCoord.y < bound) {
        vec2 scaledCoord = 0.5 * texCoord;
        outColor = 4.0 * (texture(DiffuseSampler, clampInBound(scaledCoord, 0.5 * bound)))
                 + 2.0 * (texture(DiffuseSampler, clampInBound(scaledCoord + 0.99 * vec2(oneTexel.x, 0.0), 0.5 * bound)))
                 + 2.0 * (texture(DiffuseSampler, clampInBound(scaledCoord - 0.99 * vec2(oneTexel.x, 0.0), 0.5 * bound)))
                 + 2.0 * (texture(DiffuseSampler, clampInBound(scaledCoord + 0.99 * vec2(0.0, oneTexel.y), 0.5 * bound)))
                 + 2.0 * (texture(DiffuseSampler, clampInBound(scaledCoord - 0.99 * vec2(0.0, oneTexel.y), 0.5 * bound)))
                 + (texture(DiffuseSampler, clampInBound(scaledCoord + 0.99 * vec2(oneTexel.x, oneTexel.y), 0.5 * bound)))
                 + (texture(DiffuseSampler, clampInBound(scaledCoord - 0.99 * vec2(oneTexel.x, oneTexel.y), 0.5 * bound)))
                 + (texture(DiffuseSampler, clampInBound(scaledCoord + 0.99 * vec2(oneTexel.x, -oneTexel.y), 0.5 * bound)))
                 + (texture(DiffuseSampler, clampInBound(scaledCoord - 0.99 * vec2(oneTexel.x, -oneTexel.y), 0.5 * bound)));
        outColor /= 16.0;
    }
    else {
        outColor = texture(DiffuseSampler, texCoord);
    }
    fragColor = outColor;
}