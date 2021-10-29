#version 150

#moj_import <light.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV_Texture;
in ivec2 UV_Mipped_Texture;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform float GameTime;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec4 normal;

// Settings
#define wind_strength 0.5
#define wind_oscillation_speed 0.8
#define wind_dir_change_speed 0.005
#define wobble_strength 1.5
#define wobble_speed 1.5
#define gust_strength 0.5

// Utils

#define atlasTileDim 1024.0 // Atlas dimensions in texture tiles
#define tileSizePixels 16.0 // Texture tile size in pixels

#define VERTICES_ATLAS_TEXTURE(u, v, x, y) x >= u/atlasTileDim && x <= (u+16)/atlasTileDim && y >= v/atlasTileDim && y <= (v+16)/atlasTileDim
#define VERTICES_ATLAS_TEXTURE_TOP(u, v, x, y) x >= u/atlasTileDim && x <= (u+16)/atlasTileDim && y >= v/atlasTileDim && y <= (v+1)/atlasTileDim

// Leaves
#define VERTICES_ACACIA_LEAVES(x, y) VERTICES_ATLAS_TEXTURE(160, 96, x, y)
#define VERTICES_AZALEA_LEAVES(x, y) VERTICES_ATLAS_TEXTURE(192, 0, x, y)
#define VERTICES_BIRCH_LEAVES(x, y) VERTICES_ATLAS_TEXTURE(256, 32, x, y)
#define VERTICES_DARK_OAK_LEAVES(x, y) VERTICES_ATLAS_TEXTURE(288, 128, x, y)
#define VERTICES_FLOWERING_AZALEA_LEAVES(x, y) VERTICES_ATLAS_TEXTURE(368, 208, x, y)
#define VERTICES_JUNGLE_LEAVES(x, y) VERTICES_ATLAS_TEXTURE(448, 112, x, y)
#define VERTICES_OAK_LEAVES(x, y) VERTICES_ATLAS_TEXTURE(336, 272, x, y)
#define VERTICES_SPRUCE_LEAVES(x, y) VERTICES_ATLAS_TEXTURE(400, 368, x, y)

// Grass
#define VERTICES_GRASS(x, y) VERTICES_ATLAS_TEXTURE_TOP(384, 256, x, y)
#define VERTICES_TALL_GRASS_TOP(x, y) VERTICES_ATLAS_TEXTURE(32, 400, x, y)
#define VERTICES_TALL_GRASS_TOP_TOP(x, y) VERTICES_ATLAS_TEXTURE_TOP(32, 400, x, y)
#define VERTICES_TALL_GRASS_BOTTOM(x, y) VERTICES_ATLAS_TEXTURE_TOP(16, 400, x, y)

// Other
#define VERTICES_AZALEA_SIDE(x, y) VERTICES_ATLAS_TEXTURE(192, 32, x, y)
#define VERTICES_AZALEA_TOP(x, y) VERTICES_ATLAS_TEXTURE(192, 48, x, y)
#define VERTICES_FLOWERING_AZALEA_SIDE(x, y) VERTICES_ATLAS_TEXTURE(368, 224, x, y)
#define VERTICES_FLOWERING_AZALEA_TOP(x, y) VERTICES_ATLAS_TEXTURE(368, 240, x, y)
#define VERTICES_AZALEA_PLANT_TOP(x, y) VERTICES_ATLAS_TEXTURE_TOP(192, 16, x, y)
#define VERTICES_VINE(x, y) VERTICES_ATLAS_TEXTURE(384, 400, x, y)

void main() {
    vec3 position = Position + ChunkOffset;
    float time = GameTime * 1000.0;

    float offset_x = 0.0;
    float offset_z = 0.0;

    

    gl_Position = ProjMat * ModelViewMat * vec4(Position + ChunkOffset + vec3(offset_x / tileSizePixels, 0.0, offset_z / tileSizePixels), 1.0);

    vertexDistance = length((ModelViewMat * vec4(Position + ChunkOffset, 1.0)).xyz);
    vertexColor = Color * minecraft_sample_lightmap(Sampler0, UV_Mipped_Texture);
    texCoord0 = UV_Texture;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
}
