// Mostly the same as JNNGL's gui_player_models_base just in a .glsl file

#version 330

const float PORTRAIT_FAR = 1024.0;

struct intersection {
    float t, t2;
    bool inside;
    vec3 position;
    vec3 normal, normal2;
    vec2 uv;
    vec4 albedo;
};

void boxTexCoord(inout intersection it, vec3 origin, vec3 size, const vec4 uvs[12], int offset) {
    vec3 t = it.position - origin;
    vec3 mask = abs(it.normal);
    vec2 uv = mask.x * t.zy + mask.y * t.xz + mask.z * t.xy;
    vec2 dim = mask.x * size.zy + mask.y * size.xz + mask.z * size.xy;
    uv = mod(uv / (dim * 2.0) + 0.5, 1.0);

    vec4 uvmap;
    vec3 normal = it.normal * (it.t == it.t2 ? -1 : 1);
    if (normal.x == 1) uvmap = uvs[offset];
    else if (normal.x == -1) uvmap = uvs[offset + 1];
    else if (normal.y == 1) uvmap = uvs[offset + 2];
    else if (normal.y == -1) uvmap = uvs[offset + 3];
    else if (normal.z == 1) uvmap = uvs[offset + 4];
    else if (normal.z == -1) uvmap = uvs[offset + 5];

    it.uv = floor(mix(uvmap.xy, uvmap.zw, uv));
}

bool boxIntersect(inout intersection it, vec3 origin, vec3 direction, vec3 position, vec3 size) {
    vec3 invDir = 1.0 / direction;
    vec3 ext = abs(invDir) * size;
    vec3 tMin = -invDir * (origin - position) - ext;
    vec3 tMax = tMin + ext * 2;
    float near = max(max(tMin.x, tMin.y), tMin.z);
    float far = min(min(tMax.x, tMax.y), tMax.z);
    if (near > far || far < 0.0 || near > it.t) return false;
    it.inside = near <= 0.0;
    it.t = it.inside ? far : near;
    it.t2 = far;
    it.normal = (it.inside ? step(tMax, vec3(far)) : step(vec3(near), tMin)) * -sign(direction);
    it.normal2 = step(tMax, vec3(far)) * -sign(direction);
    it.position = direction * it.t + origin;
    return true;
}

void box(inout intersection it, vec3 origin, vec3 direction, mat3 transform, vec3 position, vec3 size, const vec4 uvs[12], int layer) {
    intersection temp = it;
    vec3 originT = transform * origin;
    vec3 directionT = transform * direction;
    if (!boxIntersect(temp, originT, directionT, position, size)) return;
    boxTexCoord(temp, position, size, uvs, layer * 6);
    temp.albedo = texelFetch(Sampler0, ivec2(temp.uv), 0);
    if (temp.albedo.a < 0.1) {
        if (temp.t == temp.t2 || temp.t2 >= PORTRAIT_FAR) return;
        temp.t = temp.t2;
        temp.normal = temp.normal2;
        temp.position = directionT * temp.t + originT;
        boxTexCoord(temp, position, size, uvs, layer * 6);
        temp.albedo = texelFetch(Sampler0, ivec2(temp.uv), 0);
        if (temp.albedo.a < 0.1) return;
    }
    temp.normal = temp.normal * transform;
    temp.position = direction * temp.t + origin;
    it = temp;
}

intersection rayTrace(vec3 origin, vec3 direction, float far) {
    const vec4 headUV[12] = vec4[](
        vec4(0, 16, 8, 8),
        vec4(24, 16, 16, 8),
        vec4(16, 0, 8, 8),
        vec4(24, 0, 16, 8),
        vec4(16, 16, 8, 8),
        vec4(24, 16, 32, 8),

        vec4(24, 16, 16, 8) + vec4(32, 0, 32, 0),
        vec4(0, 16, 8, 8) + vec4(32, 0, 32, 0),
        vec4(16, 0, 8, 8) + vec4(32, 0, 32, 0),
        vec4(24, 0, 16, 8) + vec4(32, 0, 32, 0),
        vec4(16, 16, 8, 8) + vec4(32, 0, 32, 0),
        vec4(24, 16, 32, 8) + vec4(32, 0, 32, 0)
    );

    const vec4 bodyUV[12] = vec4[](
        vec4(28, 32, 32, 20),
        vec4(20, 32, 16, 20),
        vec4(28, 16, 20, 20),
        vec4(36, 16, 28, 20),
        vec4(28, 32, 20, 20),
        vec4(32, 32, 40, 20),

        vec4(28, 32, 32, 20) + vec4(0, 16, 0, 16),
        vec4(20, 32, 16, 20) + vec4(0, 16, 0, 16),
        vec4(28, 16, 20, 20) + vec4(0, 16, 0, 16),
        vec4(36, 16, 28, 20) + vec4(0, 16, 0, 16),
        vec4(28, 32, 20, 20) + vec4(0, 16, 0, 16),
        vec4(32, 32, 40, 20) + vec4(0, 16, 0, 16)
    );

    const vec4 rightArmUV[12] = vec4[](
        vec4(40, 32, 44, 20),
        vec4(51, 32, 47, 20),
        vec4(47, 16, 44, 20),
        vec4(50, 16, 47, 20),
        vec4(47, 32, 44, 20),
        vec4(51, 32, 54, 20),

        vec4(40, 32, 44, 20) + vec4(0, 16, 0, 16),
        vec4(51, 32, 47, 20) + vec4(0, 16, 0, 16),
        vec4(47, 16, 44, 20) + vec4(0, 16, 0, 16),
        vec4(50, 16, 47, 20) + vec4(0, 16, 0, 16),
        vec4(47, 32, 44, 20) + vec4(0, 16, 0, 16),
        vec4(51, 32, 54, 20) + vec4(0, 16, 0, 16)
    );

    const vec4 leftArmUV[12] = vec4[](
        vec4(32, 64, 36, 52),
        vec4(43, 64, 39, 52),
        vec4(39, 48, 36, 52),
        vec4(42, 48, 39, 52),
        vec4(39, 64, 36, 52),
        vec4(43, 64, 46, 52),

        vec4(32, 64, 36, 52) + vec4(16, 0, 16, 0),
        vec4(43, 64, 39, 52) + vec4(16, 0, 16, 0),
        vec4(39, 48, 36, 52) + vec4(16, 0, 16, 0),
        vec4(42, 48, 39, 52) + vec4(16, 0, 16, 0),
        vec4(39, 64, 36, 52) + vec4(16, 0, 16, 0),
        vec4(43, 64, 46, 52) + vec4(16, 0, 16, 0)
    );

    // uncomment for legs
    /*
    const vec4 rightLegUV[12] = vec4[](
        vec4(0, 32, 4, 20),
        vec4(12, 32, 8, 20),
        vec4(8, 16, 4, 20),
        vec4(12, 16, 8, 20),
        vec4(8, 32, 4, 20),
        vec4(12, 32, 16, 20),

        vec4(0, 32, 4, 20) + vec4(0, 16, 0, 16),
        vec4(12, 32, 8, 20) + vec4(0, 16, 0, 16),
        vec4(8, 16, 4, 20) + vec4(0, 16, 0, 16),
        vec4(12, 16, 8, 20) + vec4(0, 16, 0, 16),
        vec4(8, 32, 4, 20) + vec4(0, 16, 0, 16),
        vec4(12, 32, 16, 20) + vec4(0, 16, 0, 16)
    );

    const vec4 leftLegUV[12] = vec4[](
        vec4(16, 64, 20, 52),
        vec4(28, 64, 24, 52),
        vec4(24, 48, 20, 52),
        vec4(28, 48, 24, 52),
        vec4(24, 64, 20, 52),
        vec4(28, 64, 32, 52),

        vec4(16, 64, 20, 52) + vec4(-16, 0, -16, 0),
        vec4(28, 64, 24, 52) + vec4(-16, 0, -16, 0),
        vec4(24, 48, 20, 52) + vec4(-16, 0, -16, 0),
        vec4(28, 48, 24, 52) + vec4(-16, 0, -16, 0),
        vec4(24, 64, 20, 52) + vec4(-16, 0, -16, 0),
        vec4(28, 64, 32, 52) + vec4(-16, 0, -16, 0)
    );
    */

    const float rightArmR = radians(6.);
    const float leftArmR = radians(-6.);
    const mat3 rightArmT = mat3(cos(rightArmR), -sin(rightArmR), 0, sin(rightArmR), cos(rightArmR), 0, 0, 0, 1);
    const mat3 leftArmT = mat3(cos(leftArmR), -sin(leftArmR), 0, sin(leftArmR), cos(leftArmR), 0, 0, 0, 1);

    intersection it = intersection(far, far, false, vec3(0.0), vec3(0.0), vec3(0.0), vec2(0.0), vec4(1.0, 1.0, 1.0, 0.0));

    // overlay
    // uncomment for legs
    /*
    box(it, origin, direction, mat3(1), vec3(-2, -6, 0), vec3(2, 6, 2) + .25, leftLegUV, 1);
    box(it, origin, direction, mat3(1), vec3(2, -6, 0), vec3(2, 6, 2) + .25, rightLegUV, 1);
    */
    box(it, origin, direction, mat3(1), vec3(0, 6, 0), vec3(4, 6, 2) + .25, bodyUV, 1);
    box(it, origin, direction, leftArmT, vec3(-6.725, 5.5, 0), vec3(1.5, 6, 2) + .25, leftArmUV, 1);
    box(it, origin, direction, rightArmT, vec3(6.725, 5.5, 0), vec3(1.5, 6, 2) + .25, rightArmUV, 1);
    box(it, origin, direction, mat3(1), vec3(0, 16, 0), vec3(4, 4, 4) + .5, headUV, 1);

    // base layer
    // uncomment for legs
    /*
    box(it, origin, direction, mat3(1), vec3(-2, -6, 0), vec3(2, 6, 2), leftLegUV, 0);
    box(it, origin, direction, mat3(1), vec3(2, -6, 0), vec3(2, 6, 2), rightLegUV, 0);
    */
    box(it, origin, direction, mat3(1), vec3(0, 6, 0), vec3(4, 6, 2), bodyUV, 0);
    box(it, origin, direction, leftArmT, vec3(-6.725, 5.5, 0), vec3(1.5, 6, 2), leftArmUV, 0);
    box(it, origin, direction, rightArmT, vec3(6.725, 5.5, 0), vec3(1.5, 6, 2), rightArmUV, 0);
    box(it, origin, direction, mat3(1), vec3(0, 16, 0), vec3(4, 4, 4), headUV, 0);

    return it;
}

vec3 portraitCalculateLighting(vec3 normal, vec3 lightDir) {
    float NdotL = max(dot(normal, lightDir), 0.);
    return sqrt(vec3(.3 + .7 * NdotL));
}

mat3 rotateY(float rad) {
    float cosT = cos(rad);
    float sinT = sin(rad);
    return mat3(cosT, 0, sinT, 0, 1, 0, -sinT, 0, cosT);
}

vec4 portraitRender(vec2 uv, float aspectRatio, float gameTime) {
    vec4 result = vec4(0);

    const float rotationSpeed = 0.0;
    mat3 cameraRot = rotateY(gameTime * rotationSpeed);

    vec3 direction = cameraRot * normalize(vec3(-1));
    vec3 side = normalize(cross(vec3(0, 1, 0), direction));
    vec3 up = cross(direction, side);

    vec2 clip = uv * 2 - 1;
    vec3 origin = cameraRot * vec3(1, 1.75, 1) * 20;

    origin += 10 * (side * clip.x * aspectRatio - up * clip.y);

    intersection it = rayTrace(origin, direction, PORTRAIT_FAR);

    if (it.t < PORTRAIT_FAR) {
        vec3 lightDir = normalize(vec3(0, 1, .5));
        vec3 lighting = portraitCalculateLighting(it.normal, lightDir);

        vec4 c = it.albedo;

        c.rgb *= lighting;

        result = c;
    }

    return result;
}
