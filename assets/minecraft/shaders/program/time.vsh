#version 150

in vec4 Position;

uniform sampler2D DiffuseSampler;
uniform sampler2D MainSampler;
uniform vec2 OutSize;
uniform vec2 Scale;
uniform float Time;

out vec2 texCoord;
flat out vec4 oldtime;
flat out vec4 time;

vec2 getControl(int index, vec2 screenSize) {
    return vec2(floor(screenSize.x / 2.0) + float(index) * 2.0 + 0.5, 0.5) / screenSize;
}
void main() {
    float x = -1.0;
    float y = -1.0;

    if (Position.x > 0.001) {x = 2.0 * Scale.x - 1.0;}
    if (Position.y > 0.001) {y = 2.0 * Scale.y - 1.0;}

    vec2 size = textureSize(MainSampler, 0);
    vec2 start = getControl(0, size);
    vec2 inc = vec2(2.0 / size.x, 0.0);

    oldtime = texelFetch(DiffuseSampler, ivec2(0), 0);
    time = vec4(texture(MainSampler, start + 27.0 * inc).r, Time, 0, 1);

    gl_Position = vec4(x, y, 0.2, 1.0);
    texCoord = Position.xy / OutSize;
}