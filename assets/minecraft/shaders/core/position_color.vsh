#version 150

in vec3 Position;
in vec4 Color;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec4 vertexColor;
out float isHorizon;
out float isSpyglass;

#define HORIZONDIST 128

bool rougheq(float a, float b) {
    return (abs(a - b) < 0.001);
}
bool rougheq(vec3 a, vec3 b)
{
    return (lessThan(a, b+0.0001)==bvec3(true) && lessThan(b-0.0001,a)==bvec3(true));
}

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    vec3 offset = vec3(0.0);
    vertexColor = Color;

    isHorizon = 0.0;
    isSpyglass = 0.0;
    vec3 pos = (ProjMat * vec4(Position, 1.0)).xyz;
    if ((ModelViewMat * vec4(Position, 1.0)).z > -HORIZONDIST - 10.0) {isHorizon = 1.0;}
    else if ((ModelViewMat * vec4(Position, 1.0)).z < -2050 && (ModelViewMat * vec4(Position, 1.0)).z > -2100) {isSpyglass = 1.0;}
    //full screen
    else if(rougheq(min(abs(pos.x),1.0), 1.0) && rougheq(min(abs(pos.y),1.0), 1.0)) {
        //gui menu and loading bg
        if (Position.z == 0.0) {
            //bottom vertices
            if (gl_VertexID > -1 && gl_VertexID < 2) {
                vertexColor = vec4(0.0);
            }
            //top vertices
            else {
                vertexColor = vec4(0.0,0.0,0.0,0.8);
            }
        }
    }
    //vertexColor.r += (Position.z - 100.)/100.;
    //else if (Position.z > 100.) {
    //    //tooltip
    //    if (Color.g == 0.0) {
    //    //if(rougheq(Color.a,0.94118) && rougheq(Color.r, 0.06275) && rougheq(Color.b, 0.06275)) {}
    //    //outline
    //    //else if(rougheq(Color.a,0.31373) && ((rougheq(Color.b,1.0) && rougheq(Color.r,0.31373)) || (rougheq(Color.b,0.49804) && rougheq(Color.r,0.15686)))) {}
    //    }
    //}
    //hover
    //else if (Color.rgb == vec3(1.0)) {
    //    
    //}

    gl_Position = ProjMat * ModelViewMat * vec4(Position + offset, 1.0);
}
