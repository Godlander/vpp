#version 150

uniform sampler2D DiffuseSampler;

in vec2 texCoord;
in vec2 oneTexel;
flat in vec4 oldtime;
flat in vec4 time;

out vec4 fragColor;

//duration in frames of blur
#define DURATION 10

void main() {
    switch(int(gl_FragCoord.x)) {
        case 0:
            fragColor = time;
            break;
        case 1:
            if (oldtime.r == time.r && abs(oldtime.g - time.g) < 0.004) {
                fragColor = texelFetch(DiffuseSampler, ivec2(1,0), 0);
                fragColor += vec4(1.0/DURATION);
            } else {
                fragColor = vec4(0);
            }
            break;
    }
}
