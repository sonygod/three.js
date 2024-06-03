#if USE_SKINNING

import js.html.WebGLRenderingContext;

class SkinningParsVertex {
    public var bindMatrix: Float32Array;
    public var bindMatrixInverse: Float32Array;
    public var boneTexture: WebGLRenderingContext.Any;

    public function getBoneMatrix(i: Float): Float32Array {
        var size = (Js.cast(boneTexture).textureSize(0)).x;
        var j = (Std.int(i)) * 4;
        var x = j % size;
        var y = j / size;

        var v1 = Js.cast(boneTexture).texelFetch(Js.cast(boneTexture), {x: x, y: y}, 0);
        var v2 = Js.cast(boneTexture).texelFetch(Js.cast(boneTexture), {x: x + 1, y: y}, 0);
        var v3 = Js.cast(boneTexture).texelFetch(Js.cast(boneTexture), {x: x + 2, y: y}, 0);
        var v4 = Js.cast(boneTexture).texelFetch(Js.cast(boneTexture), {x: x + 3, y: y}, 0);

        return new Float32Array([v1[0], v1[1], v1[2], v1[3],
                                 v2[0], v2[1], v2[2], v2[3],
                                 v3[0], v3[1], v3[2], v3[3],
                                 v4[0], v4[1], v4[2], v4[3]]);
    }
}

#end