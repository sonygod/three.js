package three.shader;

class MetalnessMapFragment {
    public function new() {}

    public static var metalnessFactor:Float = metalness;

    #if USE_METALNESSMAP
    public static function textureSample(metalnessMap:Texture, vMetalnessMapUv:Vector2):Void {
        var texelMetalness:Vector4 = metalnessMap.getPixel(vMetalnessMapUv);
        metalnessFactor *= texelMetalness.b;
    }
    #end
}