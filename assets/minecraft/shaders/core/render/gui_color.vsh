#version 150

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
out vec3 pos1;
out vec3 pos2;
out vec3 pos3;

void main() {
    pos1 = pos2 = pos3 = vec3(0);
    switch (gl_VertexID % 4) {
        case 0: pos1 = vec3(Position.xy,1); break;
        case 1: pos2 = vec3(Position.xy,1); break;
        case 2: pos3 = vec3(Position.xy,1); break;
    }
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    vertexColor = Color;
}