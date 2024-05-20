class MorphTargetParsVertex {
    static var USE_MORPHTARGETS:Bool;
    static var USE_INSTANCING_MORPH:Bool;
    static var morphTargetBaseInfluence:Float;
    static var morphTargetInfluences:Array<Float>;
    static var MORPHTARGETS_COUNT:Int;
    static var morphTargetsTexture:Texture;
    static var morphTargetsTextureSize:Vector2;

    static function getMorph(vertexIndex:Int, morphTargetIndex:Int, offset:Int):Vector4 {
        var texelIndex = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
        var y = texelIndex / morphTargetsTextureSize.x;
        var x = texelIndex - y * morphTargetsTextureSize.x;

        var morphUV = new Vector3Int(x, y, morphTargetIndex);
        return Texture.texelFetch(morphTargetsTexture, morphUV, 0);
    }
}