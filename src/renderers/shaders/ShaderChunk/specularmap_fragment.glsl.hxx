class ShaderChunk {
    static var specularmap_fragment:String =
        "float specularStrength;" +
        "#ifdef USE_SPECULARMAP" +
        "vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );" +
        "specularStrength = texelSpecular.r;" +
        "#else" +
        "specularStrength = 1.0;" +
        "#endif";
}