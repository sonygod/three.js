@:glsl(fragment)
class MorphTargetParsVertex {
    #if useMorphtargets

        #if !useInstancingMorph

            @:glsl(uniform)
            var morphTargetBaseInfluence:Float;
            @:glsl(uniform)
            var morphTargetInfluences:Array<Float>;

        #end

        @:glsl(uniform)
        var morphTargetsTexture:Sampler2DArray;
        @:glsl(uniform)
        var morphTargetsTextureSize:IVec2;

        @:glsl(inline)
        function getMorph(vertexIndex:Int, morphTargetIndex:Int, offset:Int):Vec4 {

            var texelIndex:Int = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
            var y:Int = texelIndex / morphTargetsTextureSize.x;
            var x:Int = texelIndex - y * morphTargetsTextureSize.x;

            var morphUV:IVec3 = IVec3(x, y, morphTargetIndex);
            return texelFetch(morphTargetsTexture, morphUV, 0);

        }

    #end
}