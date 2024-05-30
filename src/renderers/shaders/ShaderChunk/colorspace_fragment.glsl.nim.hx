package three.renderers.shaders.ShaderChunk;

class colorspace_fragment {
    public static function main() {
        return "gl_FragColor = linearToOutputTexel( gl_FragColor );\n";
    }
}