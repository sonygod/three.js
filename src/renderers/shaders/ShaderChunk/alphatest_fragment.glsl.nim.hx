package three.renderers.shaders.ShaderChunk;

class AlphatestFragment {
    static public var fragmentShader:String = "#ifdef USE_ALPHATEST\n" +
        "\n" +
        "	#ifdef ALPHA_TO_COVERAGE\n" +
        "\n" +
        "	diffuseColor.a = smoothstep( alphaTest, alphaTest + fwidth( diffuseColor.a ), diffuseColor.a );\n" +
        "	if ( diffuseColor.a == 0.0 ) discard;\n" +
        "\n" +
        "	#else\n" +
        "\n" +
        "	if ( diffuseColor.a < alphaTest ) discard;\n" +
        "\n" +
        "	#endif\n" +
        "\n" +
        "#endif";
}