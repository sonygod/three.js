package three.shader;

class ToneMappingFragment {
    public function new() {}

    public static functionmain():Void {
        #if ( tone_mapping )
        gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
        #end
    }
}