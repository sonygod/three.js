package renderers.shaders.ShaderChunk;

class PremultipliedAlphaFragment {
    public static var glsl(get, never):String;

    private static function get_glsl():String {
        return '
#ifdef PREMULTIPLIED_ALPHA

	gl_FragColor.rgb *= gl_FragColor.a;

#endif
';
    }
}