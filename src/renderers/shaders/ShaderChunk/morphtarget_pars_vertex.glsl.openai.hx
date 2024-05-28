package three.js.src.renderers.shaders.ShaderChunk;

// glsl
extern class MorphTargetVertexShader {

    @:uniform var morphTargetBaseInfluence:Float;
    @:uniform var morphTargetInfluences:Array<Float>;

    @:uniform var morphTargetsTexture:Texture2DArray;
    @:uniform var morphTargetsTextureSize:IVec2;

    function getMorph(vertexIndex:Int, morphTargetIndex:Int, offset:Int):Vec4 {
        var texelIndex:Int = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
        var y:Int = Math.floor(texelIndex / morphTargetsTextureSize.x);
        var x:Int = texelIndex - y * morphTargetsTextureSize.x;

        var morphUV:IVec3 = new IVec3(x, y, morphTargetIndex);
        return texelFetch(morphTargetsTexture, morphUV, 0);
    }
}