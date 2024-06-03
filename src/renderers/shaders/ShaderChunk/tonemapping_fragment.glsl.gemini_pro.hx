class ShaderUtils {
  public static function getFragmentShader():String {
    var result:String = "";
    #if (tone_mapping)
      result += "gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );";
    #end
    return result;
  }
}


**Explanation:**

- Haxe doesn't have a direct equivalent of JavaScript's template literals with embedded expressions.
- We define a class `ShaderUtils` to hold the shader code.
- The `getFragmentShader()` function builds the shader string.
- We use Haxe's conditional compilation feature (`#if`) to include the tone mapping code only if the `tone_mapping` define is set. You can define this in your Haxe build file or pass it as a command-line argument to the compiler.

**Example Usage:**


// Assuming you have a shader object that can accept a string as its fragment shader code
var shader = new Shader();
shader.fragmentShader = ShaderUtils.getFragmentShader();