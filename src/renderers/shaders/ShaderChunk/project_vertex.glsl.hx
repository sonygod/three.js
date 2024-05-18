package three.renderers.shaders.ShaderChunk;

import haxe.macro.Expr;

class ProjectVertexShader
{
    public function new()
    {
        var vertexShader = '
            vec4 mvPosition = vec4(transformed, 1.0);

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
}