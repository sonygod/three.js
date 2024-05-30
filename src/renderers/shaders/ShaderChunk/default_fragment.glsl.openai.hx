package three.renderers.shaders.shaderChunks;

class DefaultFragment {
    public function new() {}

    public static inline function main() {
        gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
}