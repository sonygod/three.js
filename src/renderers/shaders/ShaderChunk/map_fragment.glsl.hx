package three.renderers.shaders.ShaderChunk;

class MapFragment {

    public function new() {}

    public static function Fragment() {
        #if USE_MAP
        var sampledDiffuseColor:Vec4 = texture2D(map, vMapUv);

        #if DECODE_VIDEO_TEXTURE
        // use inline sRGB decode until browsers properly support SRGB8_ALPHA8 with video textures (#26516)
        sampledDiffuseColor = new Vec4(
            mix(
                pow(sampledDiffuseColor.rgb * 0.9478672986 + new Vec3(0.0521327014), new Vec3(2.4)),
                sampledDiffuseColor.rgb * 0.0773993808,
                lessThanEqual(sampledDiffuseColor.rgb, new Vec3(0.04045))
            ),
            sampledDiffuseColor.w
        );
        #end

        diffuseColor *= sampledDiffuseColor;
        #end
    }
}