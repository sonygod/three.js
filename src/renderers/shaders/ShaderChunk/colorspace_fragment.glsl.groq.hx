package three.renderers.shaders.ShaderChunk;

class ColorSpaceFragmentShader {
    public function new() {}

    public static function main():String {
        return "gl_FragColor = linearToOutputTexel( gl_FragColor );";
    }
}