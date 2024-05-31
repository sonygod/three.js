class ShaderUtils {
  public static function objectNormal():String {
    return /* glsl */
    """
    vec3 objectNormal = vec3( normal );

    #ifdef USE_TANGENT
      vec3 objectTangent = vec3( tangent.xyz );
    #endif
    """;
  }
}


**Explanation:**

1. **Class Structure:** Haxe code needs to be organized within classes. We create a class `ShaderUtils` to hold the GLSL code.
2. **Static Function:** We define a static function `objectNormal` to return the GLSL code snippet. This makes it easy to access and use the code from other parts of your Haxe project.
3. **String Literal:** The GLSL code is enclosed in triple quotes (`"""..."""`) to create a multiline string literal in Haxe.

**How to use it:**

In your Haxe code where you need this GLSL snippet, you can call the `objectNormal` function:


var myGLSLCode = ShaderUtils.objectNormal();