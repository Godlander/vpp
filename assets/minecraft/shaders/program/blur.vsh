#version 150

in vec4 Position;

uniform sampler2D TimeSampler;
uniform vec2 OutSize;

out vec2 texCoord;
flat out float blur;

void main() {
    float x = -1.0;
    float y = -1.0;

    if (Position.x > 0.001) {x = 1;}
    if (Position.y > 0.001) {y = 1;}

    blur = texelFetch(TimeSampler, ivec2(1,0), 0).r * 1.5;

    gl_Position = vec4(x, y, 0.2, 1.0);
    texCoord = Position.xy / OutSize;
}