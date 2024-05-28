package three.js.src.renderers.shaders.ShaderChunk;

class TonemappingFragment
{
    public static function main() {
#if defined( TONE_MAPPING )
        gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
#end
    }
}