#version 150

#moj_import <fog.glsl>
#moj_import <tools.glsl>

in vec3 Position;
uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

float mapcolor(vec3 color, vec3 match) {
    if (rougheq(color/2, 0.5*match)) {return 1.;}
    if (rougheq(color/2, 0.5*match*0.53)) {return 0.53;}
    if (rougheq(color/2, 0.5*match*0.86)) {return 0.865;}
    if (rougheq(color/2, 0.5*match*0.71)) {return 0.71;}
    return 0.;
}

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a < 0.1) {
        discard;
    }

    if (textureSize(Sampler0, 0) == ivec2(128)) { //map
        float height = 1.;
        height = mapcolor(color.rgb*255., vec3(127.,178.,56.));  if (height > 0.) {color.rgb = vec3(94.,123.,57.)   * height / 255.;} else { //GRASS 
        height = mapcolor(color.rgb*255., vec3(247.,233.,163.)); if (height > 0.) {color.rgb = vec3(248.,235.,186.) * height / 255.;} else { //SAND
        height = mapcolor(color.rgb*255., vec3(160.,160.,255.)); if (height > 0.) {color.rgb = vec3(132.,171.,244.) * height / 255.;} else { //ICE
        height = mapcolor(color.rgb*255., vec3(167.,167.,167.)); if (height > 0.) {color.rgb = vec3(200.,200.,200.) * height / 255.;} else { //METAL
        height = mapcolor(color.rgb*255., vec3(0.,124.,0.));     if (height > 0.) {color.rgb = vec3(58.,86.,39. )   * height / 255.;} else { //PLANT
        height = mapcolor(color.rgb*255., vec3(164.,168.,184.)); if (height > 0.) {color.rgb = vec3(182.,189.,204.) * height / 255.;} else { //CLAY
        height = mapcolor(color.rgb*255., vec3(151.,109.,77.));  if (height > 0.) {color.rgb = vec3(157.,113.,80.)  * height / 255.;} else { //DIRT
        height = mapcolor(color.rgb*255., vec3(112.,112.,112.)); if (height > 0.) {color.rgb = vec3(143.,143.,143.) * height / 255.;} else { //STONE
        height = mapcolor(color.rgb*255., vec3(64.,64.,255.));   if (height > 0.) {color.rgb = vec3(41.,71.,130.)   * height / 255.;} else { //WATER
        height = mapcolor(color.rgb*255., vec3(143.,119.,72.));  if (height > 0.) {color.rgb = vec3(187.,152.,93.)  * height / 255.;} else { //WOOD
        height = mapcolor(color.rgb*255., vec3(250.,238.,77.));  if (height > 0.) {color.rgb = vec3(255.,239.,79.)  * height / 255.;} else { //GOLD
        height = mapcolor(color.rgb*255., vec3(74.,128.,255.));  if (height > 0.) {color.rgb = vec3(37.,79.,160.)   * height / 255.;} else { //LAPIS
        height = mapcolor(color.rgb*255., vec3(0.,217.,58.));    if (height > 0.) {color.rgb = vec3(66.,233.,113.)  * height / 255.;} else { //EMERALD
        height = mapcolor(color.rgb*255., vec3(129.,86.,49.));   if (height > 0.) {color.rgb = vec3(108.,75.,29.)   * height / 255.;} else { //PODZOL
        height = mapcolor(color.rgb*255., vec3(127.,63.,178.));  if (height > 0.) {color.rgb = vec3(133.,107.,153)  * height / 255.;} else { //MYCELIUM
        height = mapcolor(color.rgb*255., vec3(112.,2.,0.));     if (height > 0.) {color.rgb = vec3(113.,47.,47.)   * height / 255.;} else { //NETHER
        height = mapcolor(color.rgb*255., vec3(255.,0.,0.));     if (height > 0.) {color.rgb = vec3(230.,133.,44.)  * height / 255.;} }}}}}}}}}}}}}}}}//FIRE
    }                                                                                                                                //:works_as_intended:

    color = color * vertexColor * ColorModulator;

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
