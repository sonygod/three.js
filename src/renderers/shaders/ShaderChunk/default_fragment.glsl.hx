package renderers.shaders.ShaderChunk;

class DefaultFragmentGlsl {
    public function new() {}

    public static function main() {
        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
}