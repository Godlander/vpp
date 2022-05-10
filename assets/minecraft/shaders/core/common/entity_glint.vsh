#version 150

#moj_import <matf.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec2 UV0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform mat4 TextureMat;
uniform int FogShape;

uniform float GameTime;

out float vertexDistance;
out vec2 texCoord0;
out vec4 glpos;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    vertexDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    texCoord0 = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;

    float depth = -(ModelViewMat * vec4(1.0)).z;
    if (depth == 1602.) {
        mat4 rot = Rotate(GameTime * ROTSPEED, Y) * Scale(1.1, 1.1, 1.1);
        gl_Position = ProjMat * ModelViewMat * vec4((vec4(Position, 0) * rot).xyz, 1.0);
    }
    glpos = gl_Position;
}