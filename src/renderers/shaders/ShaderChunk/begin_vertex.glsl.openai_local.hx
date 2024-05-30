// File path: three.js/src/renderers/shaders/ShaderChunk/begin_vertex.glsl.hx
package three.js.src.renderers.shaders.ShaderChunk;

class BeginVertexGlsl {
    public static inline var code: String = '
        vec3 transformed = vec3( position );

        #ifdef USE_ALPHAHASH

            vPosition = vec3( position );

        #endif
    ';
}