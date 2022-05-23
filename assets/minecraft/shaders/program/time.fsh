#version 150

uniform sampler2D DiffuseSampler;

in vec2 texCoord;
in vec2 oneTexel;
in float time;

out vec4 fragColor;

//duration in frames of blur
#define DURATION 10

void main() {
    float oldtime = texelFetch(DiffuseSampler, ivec2(0), 0).r;
    switch(int(gl_FragCoord.x)) {
        case 0:
            fragColor = vec4(time);
            break;
        case 1:
            if (oldtime == time) {
                fragColor = texelFetch(DiffuseSampler, ivec2(1,0), 0);
                fragColor += vec4(1.0/DURATION);
            } else {
                fragColor = vec4(0);
            }
            break;
    }
}
