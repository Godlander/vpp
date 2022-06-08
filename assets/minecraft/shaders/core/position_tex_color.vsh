#version 150

in vec3 Position;
in vec2 UV0;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec2 texCoord0;
out vec4 vertexColor;
out vec4 Pos;
out float isNeg;
out vec2 ScrSize;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    texCoord0 = UV0;
    vertexColor = Color;
    isNeg = float(UV0.y < 0);
    Pos.x = atan(ModelViewMat[0][2], ModelViewMat[0][0]);
    Pos.y = (ModelViewMat * vec4(1)).z;
    Pos.zw = vec2(gl_Position.zw);
    ScrSize = 2 / vec2(ProjMat[0][0], -ProjMat[1][1]);
}
