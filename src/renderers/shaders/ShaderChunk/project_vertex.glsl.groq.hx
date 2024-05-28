package three.js.src.renderers.shaders.ShaderChunk;

class ProjectVertex {
    public function new() {}

    public static var shaderCode:String = '
        vec4 mvPosition = vec4( transformed, 1.0 );

        #ifdef USE_BATCHING

            mvPosition = batchingMatrix * mvPosition;

        #endif

        #ifdef USE_INSTANCING

            mvPosition = instanceMatrix * mvPosition;

        #endif

        mvPosition = modelViewMatrix * mvPosition;

        gl_Position = projectionMatrix * mvPosition;
    ';
}