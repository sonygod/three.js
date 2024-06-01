class ShaderChunk {
  public static function main():String {
    return /* glsl */  """
#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#end
#end
""";
  }
}

**Explanation:**

* **Class Structure:** Haxe uses classes to organize code. We encapsulate the GLSL code within a class named `ShaderChunk` for better structure.
* **Static Function:**  The `main` function is made `static` so it can be called without needing to create an instance of the `ShaderChunk` class. 
* **String Return Type:** The `main` function is explicitly declared to return a `String`, which is the Haxe equivalent of JavaScript's string type.
* **Triple-Quoted String:** Haxe supports multiline strings using triple quotes (`"""..."""`), which helps preserve the formatting of the GLSL code.

**How to Use:**

1. **Save:** Save the Haxe code as a `.hx` file (e.g., `ShaderChunk.hx`).
2. **Compile:** Compile the Haxe code. The compilation process will vary depending on your target platform and build setup.
3. **Access the String:**  In your main Haxe code, you can access the GLSL string like this:

   
   var glslCode:String = ShaderChunk.main(); 
   trace(glslCode); // Print the GLSL code