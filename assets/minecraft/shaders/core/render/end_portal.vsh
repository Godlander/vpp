#version 330

#moj_import <projection.glsl>
#moj_import <fog.glsl>

in vec3 Position;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform mat3 IViewRotMat;
uniform int FogShape;

out float fogDistance;
out vec4 texProj0;
out vec4 glpos;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    glpos = gl_Position;
    fogDistance = fog_distance(ModelViewMat, IViewRotMat * Position, FogShape);
    texProj0 = projection_from_position(gl_Position);
}