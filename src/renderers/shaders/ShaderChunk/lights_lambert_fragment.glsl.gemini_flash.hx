class MyShader {
  public static function getShader(): String {
    return /* glsl */  "
      LambertMaterial material;
      material.diffuseColor = diffuseColor.rgb;
      material.specularStrength = specularStrength;
    ";
  }
}


**Explanation:**

1. **Class Definition:** Haxe is a strictly typed language, so we define a class called `MyShader` to encapsulate the shader code.
2. **Static Function:** We define a static function `getShader()` within the class to return the shader string. This makes the shader code accessible from other parts of your Haxe code.
3. **String Return Type:** The `getShader()` function is explicitly typed to return a `String`.
4. **Shader String:** The actual GLSL shader code is embedded within the function as a multiline string literal.

**How to Use:**

You can access the shader string from other parts of your Haxe code like this:


var shaderCode:String = MyShader.getShader();