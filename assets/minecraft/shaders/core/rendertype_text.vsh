#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec2 vertexCorner;
out float custom;

vec2[4] corners = vec2[](vec2(0, 0), vec2(0, 1), vec2(1, 1), vec2(1, 0));
vec2[4] corners2 = vec2[](vec2(-1, -1),vec2(-1, 1),vec2(1, 1),vec2(1, -1));

void main() {
    vec3 pos = Position;
    custom = 0.0;
    texCoord0 = UV0;
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);

    if (Color.r == 1/255.) {
        vertexColor.rgb = vec3(1);
        texCoord0 = vec2(corners[gl_VertexID % 4]);
        custom = 1.0;

        pos.xy += corners2[gl_VertexID % 4]; // to scale, multiply this by any amount
    }

    sphericalVertexDistance = fog_spherical_distance(pos);
    cylindricalVertexDistance = fog_cylindrical_distance(pos);

    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
}
