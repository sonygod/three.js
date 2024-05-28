package three.renderers.shaders;

class DefaultFragmentShader {
    public function new() {}

    public static function main() {
        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
}