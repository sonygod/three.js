class Shader {
  public static function main(): String {
    return /* glsl */
      "#ifdef USE_AOMAP\n" +
      "\tuniform sampler2D aoMap;\n" +
      "\tuniform float aoMapIntensity;\n" +
      "#endif\n";
  }
}


**Explanation:**

* Haxe doesn't have a direct equivalent of JavaScript's `export default`. Instead, we define a class `Shader` with a static function `main` that returns the desired GLSL code as a string.
* The rest of the code remains the same, including the multiline string using backticks (`) and string interpolation.

**Usage:**

You can access the GLSL code by calling the `Shader.main()` function. For example:


var glslCode:String = Shader.main();
trace(glslCode); // Output the GLSL code