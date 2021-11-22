vec2 texCoord = abs(texCoord0);
ivec2 block = ivec2(texCoord);
int variate;

#define VOID        vec2(0.4, 0)
#define GRASS       vec2(0.2)
#define DIRT        vec2(0.0)
#define STONE       vec2(0.2, 0)
#define COAL        vec2(0.6)
#define COPPER      vec2(0.4)
#define IRON        vec2(0.4, 0.6)
#define GOLD        vec2(0.2, 0.6)
#define LAPIS       vec2(0.2, 0.4)
#define REDSTONE    vec2(0, 0.4)
#define DIAMONDS    vec2(0, 0.6)
#define DEEPSLATE   vec2(0.4, 0.2)
#define DIRON       vec2(0.4, 0.8)
#define DGOLD       vec2(0.2, 0.8)
#define DLAPIS      vec2(0.8)
#define DREDSTONE   vec2(0.8, 0.6)
#define DDIAMONDS   vec2(0, 0.8)
#define BEDROCK     vec2(0, 0.2)

vec2 offset = VOID;

if (block.y < 1)                                                                            offset = GRASS;
else if (block.y < 4) {                                                                     offset = DIRT;
    variate = ((block.x * block.x + 6) % 10) / 5;                                           //transition dirt to stone
    if (block.y == 3 && clamp(variate, 0, 1) == 1)                                          offset = STONE;
}

else if (block.y < 70) {                                                                    offset = STONE;
    if                  (int(block.y * 3   + sin(block.x * 5.1)        * 2.4 ) % 20 == 0)   offset = COAL;
    if                  (int(block.y * 6.5 + sin(block.x * 3.0  + 2.3) * 32.1) % 30 == 0)   offset = COPPER;
    if (block.y >= 16 && int(block.y * 5.5 + sin(block.x * 2.0  + 4.3) * 30.1) % 30 == 0)   offset = IRON;
    if (block.y >= 32 && int(block.y * 8.5 + sin(block.x * 4.05 + 2.7) * 24.7) % 40 == 0)   offset = GOLD;
    if (block.y >= 32 && int(block.y * 6.2 + sin(block.x * 1.05 + 2.8) * 21.7) % 50 == 0)   offset = LAPIS;
    if (block.y >= 64 && int(block.y * 4.5 + sin(block.x * 2.05 + 2.8) * 23.7) % 50 == 0)   offset = REDSTONE;
    if (block.y >= 64 && int(block.y * 1.5 + sin(block.x * 1.05 + 4  ) * 21.6) % 80 == 0)   offset = DIAMONDS;
    variate = ((block.x * block.x + 6 * block.y) % 10) / 5;                                 //transition stone to deepslate
    if (block.y >= 68 && clamp(variate, 0, 1) == 1)                                         offset = DEEPSLATE;
}

else if (block.y < 135) {                                                                   offset = DEEPSLATE;
    if (int(block.y * 5.5 + sin(block.x * 2.0  + 4.3) * 30.1) % 20 == 0)                    offset = DIRON;
    if (int(block.y * 8.5 + sin(block.x * 4.05 + 2.7) * 24.7) % 30 == 0)                    offset = DGOLD;
    if (int(block.y * 6.2 + sin(block.x * 1.05 + 2.8) * 21.7) % 40 == 0)                    offset = DLAPIS;
    if (int(block.y * 4.5 + sin(block.x * 2.05 + 2.8) * 23.7) % 40 == 0)                    offset = DREDSTONE;
    if (int(block.y * 1.5 + sin(block.x * 1.05 + 4  ) * 21.6) % 60 == 0)                    offset = DDIAMONDS;
    variate = ((block.x * block.x + 6 * block.y + 5) % 10) / 5;                             //transition deepslate to bedrock
    if (block.y >= 132 && clamp(variate, 0, 1) == 1)                                        offset = BEDROCK;
}

else {
    if (block.y == 135)                                                                     offset = BEDROCK;
    variate = ((block.x * block.x + 4 * block.y + 5) % 10) / 5;                             //transition bedrock to void
    if (block.y < 139 && clamp(variate, 0, 1) == 1)                                         offset = BEDROCK;
}

if (vertexColor.r > 0.15) { //separate out top/bottom bar
    if (texCoord.y > 13.)                                                                   offset = DIRT;
    if (block.y == 12)                                                                      offset = GRASS;
}

color = texture(Sampler0, (texCoord - block) / 5.0 + offset) * (vertexColor + 0.2);