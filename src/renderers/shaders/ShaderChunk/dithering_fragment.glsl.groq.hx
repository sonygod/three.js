package three.shader;

class DitheringFragment {
    public function new() {}

    public static function main() : String {
        return '
#ifdef DITHERING

	gl_FragColor.rgb = dithering( gl_FragColor.rgb );

#endif
';
    }
}