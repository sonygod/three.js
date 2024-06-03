class ProjectVertexShader {
    static function getCode():String {
        return "vec4 mvPosition = vec4( transformed, 1.0 );\n" +

        "#ifdef USE_BATCHING\n" +
        "mvPosition = batchingMatrix * mvPosition;\n" +
        "#endif\n" +

        "#ifdef USE_INSTANCING\n" +
        "mvPosition = instanceMatrix * mvPosition;\n" +
        "#endif\n" +

        "mvPosition = modelViewMatrix * mvPosition;\n" +

        "gl_Position = projectionMatrix * mvPosition;\n";
    }
}