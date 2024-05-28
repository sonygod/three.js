package three.shader;

import haxe.io.Float32Array;

class MorphTargetParsVertex {
    #ifdef USE_MORPHTARGETS

    private var morphTargetBaseInfluence:Float;
    #ifndef USE_INSTANCING_MORPH
    private var morphTargetInfluences:Array<Float>;

    #end

    private var morphTargetsTexture:haxe.io.Bytes;
    private var morphTargetsTextureSize:haxe.ds.Vector<Int>;

    public function getMorph(vertexIndex:Int, morphTargetIndex:Int, offset:Int):haxe.io.Float32Array {
        var texelIndex:Int = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
        var y:Int = Std.int(texelIndex / morphTargetsTextureSize.get(0));
        var x:Int = texelIndex - y * morphTargetsTextureSize.get(0);

        var morphUV:haxe.ds.Vector<Int> = new haxe.ds.Vector<Int>(3);
        morphUV.set(0, x);
        morphUV.set(1, y);
        morphUV.set(2, morphTargetIndex);

        var texel:haxe.io.Float32Array = texelFetch(morphTargetsTexture, morphUV, 0);
        return texel;
    }

    #end
}