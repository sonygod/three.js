package three.src.renderers.shaders.ShaderChunk;

class MapFragment {
    public function new() {}

    public static function shader() {
        #ifdef USE_MAP
        var sampledDiffuseColor:Vec4 = texture2D(map, vMapUv);

        #ifdef DECODE_VIDEO_TEXTURE
        // use inline sRGB decode until browsers properly support SRGB8_ALPHA8 with video textures (#26516)
        sampledDiffuseColor = vec4(
            mix(
                pow(sampledDiffuseColor.rgb * 0.9478672986 + vec3(0.0521327014), vec3(2.4)),
                sampledDiffuseColor.rgb * 0.0773993808,
                vec3(lessThanEqual(sampledDiffuseColor.rgb, vec3(0.04045)))
            ),
            sampledDiffuseColor.w
        );
        #end

        diffuseColor *= sampledDiffuseColor;
        #end
    }
}