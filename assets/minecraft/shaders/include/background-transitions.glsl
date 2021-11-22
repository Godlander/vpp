float panoramas = textureSize(Sampler0, 0).y / textureSize(Sampler0, 0).x;

float Time = Pos.x * panoramas / 6.2831853 * TIMES;

float frame = floor(Time);
float slide = Time - frame;

vec2 coords = texCoord0 * vec2(1, 1.0 / panoramas) + vec2(0, 1.0 / panoramas) * frame;

vec4 prev = texture(Sampler0, coords) * vertexColor;
vec4 next = texture(Sampler0, coords + vec2(0, 1.0 / panoramas)) * vertexColor;

color = mix(prev, next, clamp((slide) * CHANGE_SPEED, 0, 1));
