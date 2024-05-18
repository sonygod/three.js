package renderers.shaders.ShaderChunk;

class DefaultVertex {
    public function new() {}

    public static function main() {
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
}