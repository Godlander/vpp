#version 150

bool rougheq(float a, float b) {
    return (abs(a - b) < 1.);
}

vec4 make_emissive(vec4 inputColor, vec4 lightColor, float vertexDistance, float inputAlpha) {
    if (rougheq(inputAlpha, 252.0)) return inputColor; // Default case, checks for alpha 252 and just returns the input color if it is.
    return inputColor * (0.2*lightColor + 0.8); // If none of the pixels are supposed to be emissive, then it adds the light.
}

vec4 make_emissive_entity(vec4 inputColor, vec4 lightColor, float vertexDistance, float inputAlpha) {
    if (rougheq(inputAlpha, 252.0)) return inputColor; // Default case, checks for alpha 252 and just returns the input color if it is.
    return inputColor * lightColor; // If none of the pixels are supposed to be emissive, then it adds the light.
}

float remap_alpha(float inputAlpha) {
    if (rougheq(inputAlpha, 252.0)) return 255.0; // Default case, checks for alpha 252 and converts all pixels of that to alpha 255.
    return inputAlpha; // If none of the pixels are meant to be mapped then it just doesn't map.
}