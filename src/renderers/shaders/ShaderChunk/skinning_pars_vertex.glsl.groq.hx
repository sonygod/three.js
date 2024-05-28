package three.js.src.renderers.shaders.ShaderChunk;

import haxe.macro.Expr;

class SkinningParsVertex {
    @:glsl("
#ifdef USE_SKINNING

    uniform mat4 bindMatrix;
    uniform mat4 bindMatrixInverse;

    uniform sampler2D boneTexture;

    mat4 getBoneMatrix(float i) {
        int size = textureSize(boneTexture, 0).x;
        int j = Std.int(i) * 4;
        int x = j % size;
        int y = Std.int(j / size);
        vec4 v1 = texelFetch(boneTexture, ivec2(x, y), 0);
        vec4 v2 = texelFetch(boneTexture, ivec2(x + 1, y), 0);
        vec4 v3 = texelFetch(boneTexture, ivec2(x + 2, y), 0);
        vec4 v4 = texelFetch(boneTexture, ivec2(x + 3, y), 0);

        return mat4(v1, v2, v3, v4);
    }

#endif
");
}