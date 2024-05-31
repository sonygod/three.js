class ShaderUtil {
  public static function generateShader():String {
    var shaderCode:String = "";

    #if USE_COLOR_ALPHA
      shaderCode += "diffuseColor *= vColor;";
    #elseif USE_COLOR
      shaderCode += "diffuseColor.rgb *= vColor;";
    #end

    return shaderCode;
  }
}


**Explanation:**

* **Conditional Compilation:** Haxe uses preprocessor directives similar to C++ for conditional compilation. We replace `#if defined(...)` with `#if` and `#elif defined(...)` with `#elseif`.
* **String Manipulation:** Haxe uses the `+=` operator for string concatenation.
* **Class Structure (Optional):** To organize the code, a simple class `ShaderUtil` is created with a static method `generateShader`. This is optional and depends on how you want to structure your Haxe code.

**Usage:**

To use the generated shader code, call the `generateShader` method:


var shaderCode = ShaderUtil.generateShader();
trace(shaderCode); // Output depends on the defined flags


**Defining Flags:**

You can define the flags `USE_COLOR_ALPHA` and `USE_COLOR` in your Haxe compilation command or in your HXML build file. For example, to compile with `USE_COLOR_ALPHA` defined:

bash
haxe -D USE_COLOR_ALPHA ...