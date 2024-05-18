package three.shader;

import haxecreateView;

class MorphTargetParsVertex {
    #if USE_MORPHTARGETS

        #ifndef USE_INSTANCING_MORPH
        @:uniform var morphTargetBaseInfluence:Float;
        @:uniform var morphTargetInfluences:Array<Float>;
        #end

        @:uniform var morphTargetsTexture:Texture;
        @:uniform var morphTargetsTextureSize:Vector<Int>;

        function getMorph(vertexIndex:Int, morphTargetIndex:Int, offset:Int):Vec4 {
            var texelIndex:Int = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
            var y:Int = Math.floor(texelIndex / morphTargetsTextureSize.x);
            var x:Int = texelIndex - y * morphTargetsTextureSize.x;

            var morphUV:ivec3 = new ivec3(x, y, morphTargetIndex);
            return texelFetch(morphTargetsTexture, morphUV, 0);
        }

    #end
}