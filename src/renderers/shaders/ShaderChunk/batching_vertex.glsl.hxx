class Main {
    static function main() {
        var batchingVertexShader = """
#ifdef USE_BATCHING
    mat4 batchingMatrix = getBatchingMatrix( batchId );
#endif
""";

        // 使用GLSL代码
        // ...
    }
}