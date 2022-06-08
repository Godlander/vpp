#version 150

uniform sampler2D DiffuseSampler;
uniform sampler2D TimeSampler;
uniform vec2 OutSize;

flat in float blur;

out vec4 fragColor;

const float[21] gauss = float[](0.04395898518126313, 0.04501528145376974, 0.045981873661850185, 0.0468519572388689, 0.047619322425857036, 0.04827842934039481, 0.04882447632370965, 0.049253460498130903, 0.04956222959597895, 0.04974852427081081, 0.04981092001873177, 0.04974852427081081, 0.04956222959597895, 0.049253460498130903, 0.04882447632370965, 0.04827842934039481, 0.047619322425857036, 0.0468519572388689, 0.045981873661850185, 0.04501528145376974, 0.04395898518126313);

void main() {
    fragColor = vec4(0);
    for (int i = -10; i <=10; i++) {
        fragColor += gauss[i+10]*texelFetch(DiffuseSampler, ivec2(clamp(gl_FragCoord.xy + vec2(0,i*blur), vec2(0), OutSize-1.0)), 0);
    }

    //ivec2 coord = ivec2(gl_FragCoord.xy/20);
    //if (all(lessThan(coord, ivec2(2,1)))) {
    //    fragColor = texelFetch(TimeSampler, coord, 0);
    //}
}
