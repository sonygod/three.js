class Shader {
  public static function main(): String {
    return
      "#if macro(NUM_CLIPPING_PLANES) > 0 \n" +
      "  vClipPosition = - mvPosition.xyz;\n" +
      "#end\n";
  }
}


Here's a breakdown of the changes and what to keep in mind:

* **Preprocessor Directives:** Haxe uses `#if`, `#else`, and `#end` for preprocessor directives just like GLSL and JavaScript. However, the condition inside needs to be a Haxe macro.
* **Macros:**  We replace `NUM_CLIPPING_PLANES > 0` with `macro(NUM_CLIPPING_PLANES) > 0`. This tells the Haxe compiler to evaluate `NUM_CLIPPING_PLANES` at compile time. 
* **String Concatenation:** Haxe uses the `+` operator for string concatenation. We've split the GLSL code into multiple strings for readability and used `+` to join them.

**Key Considerations:**

* **Macro Definition:** The code assumes that `NUM_CLIPPING_PLANES` is defined as a Haxe macro elsewhere in your project. You'll need to define this macro with the desired value before compiling your Haxe code. 
* **Context:** This Haxe code snippet provides a function that returns the GLSL code as a string. You'll need to call this function and use the returned string within your Haxe rendering framework (e.g., Heaps, OpenFL, Kha) to actually incorporate it into your shaders.

**Example Macro Definition (in a build file or Haxe define):**


// Using a build file (e.g., hxml)
--macro NUM_CLIPPING_PLANES=4

// Directly in your Haxe code
#if !defined(NUM_CLIPPING_PLANES)
#define NUM_CLIPPING_PLANES 4 
#end