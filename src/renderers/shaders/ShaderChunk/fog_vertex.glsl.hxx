class Main {
    static public function main() {
        var shaderChunk = haxe.macro.Context.defineString("three.js/src/renderers/shaders/ShaderChunk/fog_vertex.glsl.js", "
#ifdef USE_FOG

    vFogDepth = - mvPosition.z;

#endif
");
        // 使用shaderChunk
    }
}