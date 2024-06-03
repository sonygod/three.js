class ShaderChunk_alphatest_fragment {
    static var USE_ALPHATEST:Bool;
    static var ALPHA_TO_COVERAGE:Bool;
    static var alphaTest:Float;
    static var diffuseColor:Float;

    static function getCode():String {
        return """
#if ${USE_ALPHATEST}
    #if ${ALPHA_TO_COVERAGE}
        diffuseColor.a = smoothstep(alphaTest, alphaTest + fwidth(diffuseColor.a), diffuseColor.a);
        if (diffuseColor.a == 0.0) discard;
    #else
        if (diffuseColor.a < alphaTest) discard;
    #endif
#endif
""";
    }
}