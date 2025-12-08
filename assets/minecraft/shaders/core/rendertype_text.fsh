#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:globals.glsl>

uniform sampler2D Sampler0;

// must be after Sampler0 is defined
#moj_import <minecraft:portrait.glsl>

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in float custom;

out vec4 fragColor;

void main() {

    if (custom > 0.0) {
        // for legs to show, multiply the texCoord0 by something, i.e 2
        fragColor = portraitRender(texCoord0, 68./70., GameTime);
        if (fragColor.a < .1) discard;
        fragColor.a = vertexColor.a;
        return;
    }

    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1 || color.rgb == vec3(0)) {
        discard;
    }
    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
}
