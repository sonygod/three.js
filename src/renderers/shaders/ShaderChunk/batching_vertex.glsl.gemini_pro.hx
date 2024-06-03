class ShaderUtils {
  public static function generateShaderCode(useBatching:Bool):String {
    var shaderCode = "#ifdef USE_BATCHING\n";
    if (useBatching) {
      shaderCode += "\tmat4 batchingMatrix = getBatchingMatrix( batchId );\n";
    }
    shaderCode += "#endif\n";
    return shaderCode;
  }
}


**Explanation:**

* **Haxe does not have a direct equivalent of JavaScript template literals with embedded expressions.** Instead, we use string concatenation to achieve the same result.
* **We create a class `ShaderUtils` with a static function `generateShaderCode`.** This function takes a boolean parameter `useBatching` to determine whether to include the batching code.
* **Inside the `generateShaderCode` function, we build the shader code string conditionally based on the `useBatching` parameter.**
* **The function returns the complete shader code string.**

**Usage:**


var shaderCode:String = ShaderUtils.generateShaderCode(true); // Include batching code
// or
var shaderCode:String = ShaderUtils.generateShaderCode(false); // Exclude batching code