class ShaderUtils {
  public static function getEmissiveFragment():String {
    return /* glsl */  """
    #ifdef USE_EMISSIVEMAP
      vec4 emissiveColor = texture2D(emissiveMap, vEmissiveMapUv);
      totalEmissiveRadiance *= emissiveColor.rgb;
    #endif
    """;
  }
}


**Explanation:**

* **Class structure:** In Haxe, it's common to organize code within classes. Here, I've created a `ShaderUtils` class to hold the shader code.
* **Static function:**  The `getEmissiveFragment()` function is made static, so you can access it directly from the class without creating an instance.
* **String return type:** The function is defined to return a `String`, which is appropriate for holding the GLSL code.
* **Triple quotes:**  Haxe allows multiline strings using triple quotes (`"""..."""`), making it easier to embed the GLSL code directly.

**How to use it:**


// Access the GLSL code:
var emissiveFragmentShader:String = ShaderUtils.getEmissiveFragment();

// ... use the 'emissiveFragmentShader' variable in your shader setup ...