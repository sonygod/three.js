package three.js.src.renderers.shaders.ShaderChunk;

@:glsl("default_vertex")
class DefaultVertexShader {
    public function new() {}

    public function main():Void {
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }
}