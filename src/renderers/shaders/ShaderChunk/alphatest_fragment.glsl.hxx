class AlphaTestFragment {
    static var code = #if USE_ALPHATEST
        #if ALPHA_TO_COVERAGE
            diffuseColor.a = smoothstep(alphaTest, alphaTest + fwidth(diffuseColor.a), diffuseColor.a);
            if (diffuseColor.a == 0.0) discard;
        #else
            if (diffuseColor.a < alphaTest) discard;
        #end
    #end;
}