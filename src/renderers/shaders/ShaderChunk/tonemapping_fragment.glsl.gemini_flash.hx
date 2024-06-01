class ShaderUtils {
  public static function getFragmentShader():String {
    var result:String = "";

    #if (TONE_MAPPING)
      result += "gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );";
    #end

    return result;
  }
}


**Explanation:**

* Haxe doesn't have template literals like JavaScript's backticks, so we use regular strings.
* We use the `#if` preprocessor directive to conditionally include code based on the `TONE_MAPPING` define. This is similar to how you use `#if defined()` in GLSL.
* Instead of directly exporting the string, we create a class `ShaderUtils` with a static function `getFragmentShader` that returns the assembled fragment shader code. 

**Usage:**

To use this code, you would first need to define the `TONE_MAPPING` flag during compilation (e.g., in your build script). Then, you can access the fragment shader code like this:


var fragmentShaderSource:String = ShaderUtils.getFragmentShader();