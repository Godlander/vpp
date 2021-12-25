#version 150

#moj_import <fog.glsl>

in vec3 Position;
in vec2 UV0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform mat4 TextureMat;

out float vertexDistance;
out vec2 texCoord0;
out vec4 glpos;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    vertexDistance = cylindrical_distance(ModelViewMat, IViewRotMat * Position);
    texCoord0 = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
    glpos = gl_Position;
}
