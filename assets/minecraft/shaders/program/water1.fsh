#version 330

uniform sampler2D DiffuseSampler;
uniform sampler2D TerrianDepthSampler;
uniform sampler2D TranslucentDepthSampler;

in vec2 texCoord;
in vec2 oneTexel;
in float near;
in float far;
in float underWater;
in float rain;

out vec4 fragColor;

#define TRANSLUCENT_COLOR_DEPTH 6.0
#define TRANSLUCENT_COLOR_BASE 0.75

float linearize_depth(float depth) {
    return (2.0 * near * far) / (far + near - depth * (far - near));
}

void main() {
    vec4 outColor = texture(DiffuseSampler, texCoord);

    if (underWater < 0.5) {
        outColor.a *= clamp(smoothstep(0.0, TRANSLUCENT_COLOR_DEPTH, linearize_depth(texture(TerrianDepthSampler, texCoord).r) - linearize_depth(texture(TranslucentDepthSampler, texCoord).r)), TRANSLUCENT_COLOR_BASE, 1.0);
    }

    fragColor = outColor;
}
