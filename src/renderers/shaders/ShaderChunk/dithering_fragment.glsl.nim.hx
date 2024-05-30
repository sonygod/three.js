package three.src.renderers.shaders.ShaderChunk;

class DitheringFragment {
    public static function main() {
        #if dithering
            gl_FragColor.rgb = dithering(gl_FragColor.rgb);
        #end
        return '';
    }
}