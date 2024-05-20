class ShaderChunk {
    public static var beginnormal_vertex:String =
        "vec3 objectNormal = vec3( normal );" +
        "#ifdef USE_TANGENT" +
        "vec3 objectTangent = vec3( tangent.xyz );" +
        "#endif";
}