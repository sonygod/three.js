class Example {
  public static function getGLSL(): String {
    var result = "";

    #if macro
      result += "#ifdef USE_ALPHAMAP\n";
      result += "\tdiffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;\n";
      result += "#endif\n";
    #end

    return result;
  }
}


**Explanation:**

* **Class Structure:** Haxe encourages object-oriented programming, so we create a class (e.g., `Example`) to encapsulate the code.
* **Static Function:** The `getGLSL()` function is made static so you can call it directly on the class without creating an instance.
* **String Building:**  We build the GLSL code string piece by piece using the `+=` operator for better readability.
* **Haxe Macros:** We use a Haxe macro (#if macro) to conditionally include code blocks. This allows you to control code generation based on compile-time conditions (in this case, whether `USE_ALPHAMAP` is defined).

**How to Use:**


// Get the generated GLSL code
var glslCode:String = Example.getGLSL();

// ... Use glslCode in your Haxe rendering pipeline