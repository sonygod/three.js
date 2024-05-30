package three.renderers.shaders.ShaderChunk;

class default_vertex {
    static function main() {
        #if glsl
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        #end
    }
}