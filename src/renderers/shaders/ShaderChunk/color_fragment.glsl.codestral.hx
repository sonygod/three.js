class ColorFragmentShader {
    static function getShaderChunk(): String {
        return """
        #if defined( USE_COLOR_ALPHA )

            diffuseColor *= vColor;

        #elif defined( USE_COLOR )

            diffuseColor.rgb *= vColor;

        #endif
        """;
    }
}


In Haxe, there is no direct equivalent to JavaScript's `export default`, so I've defined a class `ColorFragmentShader` with a static method `getShaderChunk` that returns the shader chunk as a string.

You can use it like this:


var shaderChunk = ColorFragmentShader.getShaderChunk();