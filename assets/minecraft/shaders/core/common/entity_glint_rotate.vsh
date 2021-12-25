#version 150

#moj_import <matf.glsl>

in vec3 Position;
in vec2 UV0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat4 TextureMat;

uniform float GameTime;

out float vertexDistance;
out vec2 texCoord0;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    vertexDistance = length((ModelViewMat * vec4(Position, 1.0)).xyz);
    texCoord0 = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;

    float dist = -(ModelViewMat * vec4(1.0)).z;
    if (dist == 1602.) {
        mat4 rot = Rotate(GameTime * ROTSPEED, Y) * Scale(1.1, 1.1, 1.1);
        gl_Position = ProjMat * ModelViewMat * vec4((vec4(Position, 0) * rot).xyz, 1.0);
    }
}