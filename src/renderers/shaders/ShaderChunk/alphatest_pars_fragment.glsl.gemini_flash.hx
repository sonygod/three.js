class Shader {
  public static var code:String = /* glsl */
    "#ifdef USE_ALPHATEST" +
    "  uniform float alphaTest;" +
    "#endif" +
    "";
}


**Explanation:**

* Haxe doesn't have a direct equivalent of JavaScript's `export default`. We define a class `Shader` and store the GLSL code in a static variable `code`.
* We use string concatenation to build the multiline string containing the GLSL code.
* The rest of the GLSL code remains the same.

**Usage:**

To access the GLSL code from other parts of your Haxe project, you can simply use `Shader.code`. 

For example:


trace(Shader.code);