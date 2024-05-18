package three.shader;

class DitheringFragment {
    public static function main() {
        #if DITHERING
        gl_FragColor.rgb = dithering(gl_FragColor.rgb);
        #end
    }
}