class ShaderUtil {
  public static function getPointShader(): String {
    var shaderCode: String = "";

    shaderCode += "#if defined(USE_POINTS_UV)\n";
    shaderCode += "\tvarying vec2 vUv;\n";
    shaderCode += "#else\n";
    shaderCode += "\t#if defined(USE_MAP) || defined(USE_ALPHAMAP)\n";
    shaderCode += "\t\tuniform mat3 uvTransform;\n";
    shaderCode += "\t#end\n";
    shaderCode += "#end\n";
    shaderCode += "#ifdef USE_MAP\n";
    shaderCode += "\tuniform sampler2D map;\n";
    shaderCode += "#end\n";
    shaderCode += "#ifdef USE_ALPHAMAP\n";
    shaderCode += "\tuniform sampler2D alphaMap;\n";
    shaderCode += "#end\n";

    return shaderCode;
  }
}


**Explanation:**

1. **Class Structure:** We encapsulate the code within a class `ShaderUtil` for better organization.
2. **Function:** We define a static function `getPointShader()` that returns the generated GLSL code as a string.
3. **String Concatenation:** Instead of backticks for template literals, we use string concatenation to build the shader code.
4. **Preprocessor Directives:** The preprocessor directives (`#if`, `#ifdef`, `#else`, `#end`) are kept as is.
5. **Indentation:** We use tabs for indentation to maintain the structure of the original code.

**Usage:**

You can access the generated GLSL code by calling the `getPointShader()` function:


var shaderCode = ShaderUtil.getPointShader();
trace(shaderCode);