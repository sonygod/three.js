package three.renderers.shaders.ShaderChunk;

class MapFragment {
    static function main() {
        #if use_map {
            var sampledDiffuseColor = texture2D(map, vMapUv);
            #if decode_video_texture {
                // use inline sRGB decode until browsers properly support SRGB8_ALPHA8 with video textures (#26516)
                sampledDiffuseColor = Vec4(
                    mix(
                        pow(sampledDiffuseColor.rgb * 0.9478672986 + Vec3(0.0521327014), Vec3(2.4)),
                        sampledDiffuseColor.rgb * 0.0773993808,
                        Vec3(lessThanEqual(sampledDiffuseColor.rgb, Vec3(0.04045)))
                    ),
                    sampledDiffuseColor.w
                );
            }
            diffuseColor *= sampledDiffuseColor;
        }
    }
}