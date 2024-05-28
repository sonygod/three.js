package three.js.src.renderers.shaders.ShaderChunk;

class MapFragmentGlsl {
    public static inline function getShaderCode():String {
        return [
#ifdef USE_MAP
            'vec4 sampledDiffuseColor = texture2D( map, vMapUv );',
            #ifdef DECODE_VIDEO_TEXTURE
                'sampledDiffuseColor = vec4( mix( pow( sampledDiffuseColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), sampledDiffuseColor.rgb * 0.0773993808, vec3( lessThanEqual( sampledDiffuseColor.rgb, vec3( 0.04045 ) ) ) );',
            #end
            'diffuseColor *= sampledDiffuseColor;'
        #end
        ].join('\n');
    }
}