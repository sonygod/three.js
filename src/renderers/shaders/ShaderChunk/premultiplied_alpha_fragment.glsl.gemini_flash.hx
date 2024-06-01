class ShaderUtils {
  public static function getFragmentShader():String {
    #if PREMULTIPLIED_ALPHA
      return "gl_FragColor.rgb *= gl_FragColor.a;";
    #else
      return "";
    #end
  }
}


**Explanation:**

* **Conditional Compilation:** Haxe uses preprocessor directives (`#if`, `#else`, `#end`) for conditional compilation, similar to JavaScript's `#ifdef`. We check for the `PREMULTIPLIED_ALPHA` define to include the code block only when it's defined.
* **String Manipulation:** Instead of using template literals directly, we construct the shader code within a function and return it as a string.
* **Class Structure (Optional):**  The code is wrapped in a `ShaderUtils` class for better organization, but you can adapt this based on your project structure.

**Usage:**

To use the generated shader code, you would call the `ShaderUtils.getFragmentShader()` function wherever you need to access it.

**Example:**


// ... other code

// Get the fragment shader code
var fragmentShaderSource:String = ShaderUtils.getFragmentShader();

// ... use the fragmentShaderSource in your rendering pipeline