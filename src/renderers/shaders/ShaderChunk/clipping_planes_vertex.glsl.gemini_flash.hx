class ShaderUtils {
  public static function getShaderCode():String {
    var result = "";
  
    #if (NUM_CLIPPING_PLANES > 0)
      result += "vClipPosition = - mvPosition.xyz;";
    #end
  
    return result;
  }
}


**Explanation:**

* Haxe doesn't have a direct equivalent of JavaScript's template literals with embedded expressions like `${}`. 
* We use conditional compilation (`#if`, `#end`) to achieve similar behavior.
* The `NUM_CLIPPING_PLANES` macro should be defined either in your Haxe code or as a compiler argument.
* We create a class `ShaderUtils` and a static function `getShaderCode` to encapsulate the logic and return the generated shader code string.

**Usage:**

To use the generated shader code, you'd call the `getShaderCode` function:


var shaderCode:String = ShaderUtils.getShaderCode();