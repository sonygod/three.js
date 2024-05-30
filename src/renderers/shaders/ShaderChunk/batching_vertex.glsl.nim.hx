package three.renderers.shaders.ShaderChunk;

@:build(macro.ShaderMacro.i({
    shaderType: ShaderType.Vertex,
    shader: function() {
        var shader = "#ifdef USE_BATCHING\n";
        shader += "	mat4 batchingMatrix = getBatchingMatrix( batchId );\n";
        shader += "#endif\n";
        return shader;
    }
}))
class BatchingVertex {}