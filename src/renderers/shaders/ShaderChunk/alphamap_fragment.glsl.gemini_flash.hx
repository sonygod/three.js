class ShaderUtils {
  public static function getFragmentShader():String {
    var shaderCode:String = "";

    #if macro
    shaderCode += "#ifdef USE_ALPHAMAP\n";
    shaderCode += "\tdiffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;\n";
    shaderCode += "#endif\n";
    #end 

    return shaderCode;
  }
}


**Explanation:**

* **Class Structure:** Haxe code is typically organized within classes. We create a `ShaderUtils` class to hold our shader code.
* **String Interpolation:** Instead of using template literals (backticks) like in JavaScript, we use string concatenation (`+`) to build the shader string.
* **Preprocessor Directives:** Haxe uses `#if`, `#ifdef`, `#else`, and `#end` for preprocessor directives, similar to C++.  We use `#ifdef macro` to conditionally include the alpha map code if a `macro` flag is defined during compilation.
* **Return Value:** The code now returns the constructed `shaderCode` string from the `getFragmentShader` function. 

**How to use:**

1. **Compilation Flags:** When compiling your Haxe code, you can define the `macro` flag to include the alpha map functionality.  The exact way to define compilation flags depends on your build tool (e.g., Haxe compiler arguments, OpenFL settings, etc.). 

2. **Accessing the Shader Code:**  You can then get the shader code like this:

   
   var fragmentShaderSource:String = ShaderUtils.getFragmentShader();