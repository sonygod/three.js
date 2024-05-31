class ShaderUtil {
  public static function getVertexShader():String {
    var result:String = "";
  
    #if macro
      if (Globals.USE_COLOR_ALPHA) {
        result += "varying vec4 vColor;";
      } else if (Globals.USE_COLOR) {
        result += "varying vec3 vColor;";
      }
    #end
  
    return result;
  }
}


**Explanation:**

* **Haxe Macros:** We use Haxe macros (`#if macro`) to perform conditional compilation based on the defined flags.
* **Globals:** We assume the `USE_COLOR_ALPHA` and `USE_COLOR` flags are defined as global variables in your Haxe project.
* **String Concatenation:** We build the GLSL code string dynamically based on the defined flags.
* **Class and Function:** We encapsulate the logic in a class and function for better organization.

**Usage:**

To use the generated GLSL code, you would call the `getVertexShader()` function:


var vertexShaderSource:String = ShaderUtil.getVertexShader();