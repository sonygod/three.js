class Shader {
  public static var code: String = /* glsl */
  """
  #ifdef USE_ROUGHNESSMAP

    uniform sampler2D roughnessMap;

  #endif
  """;
}


Here's a breakdown of the changes and considerations:

* **No Direct Equivalent to `export default`:** Haxe doesn't have a direct equivalent to JavaScript's `export default`. Instead, you typically:
    * Define a class (like `Shader` in the example) to hold your GLSL code.
    * Make the GLSL code a `public static` member variable within the class. This allows access from other parts of your Haxe project.

* **String Literals:** Haxe uses similar string literal syntax to JavaScript. The triple-quote (`"""..."""`) syntax allows for multiline strings, which is convenient for storing GLSL code.

* **GLSL Embedding:** The `/* glsl */` comment remains the same. This signals to Haxe (or any Haxe-to-GLSL transpiler you might be using) that the content within should be treated as GLSL shader code.

**How to Use:**

1.  **Include in Your Project:** Make sure the Haxe file containing this code is part of your Haxe project's compilation.
2.  **Access from Other Code:** You can now access the GLSL code using:
    
    var myGLSLCode = Shader.code;