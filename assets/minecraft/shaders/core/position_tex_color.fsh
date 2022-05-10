#version 150

#moj_import <utils.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform vec2 ScreenSize;

in vec2 texCoord0;
in vec4 vertexColor;
in vec2 Pos;

out vec4 fragColor;

#define CHANGE_SPEED 10
#define TIMES 1

void main() {
    int index = inControl(gl_FragCoord.xy, ScreenSize.x);
    if (index != -1) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
    else {
        vec4 color = texture(Sampler0, texCoord0) * vertexColor;
        if (Pos.y == -1999) {
            #moj_import <menus-enchanted.glsl>
        }
        else {
            #moj_import <background-transitions.glsl>
        }

        if (color.a < 0.1) discard;

        fragColor = color * ColorModulator;
    }
}
