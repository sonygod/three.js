class Main {
  public static function main():Void {
    var glsl = /* glsl */"
      float specularStrength;

      #ifdef USE_SPECULARMAP

        vec4 texelSpecular = texture2D(specularMap, vSpecularMapUv);
        specularStrength = texelSpecular.r;

      #else

        specularStrength = 1.0;

      #endif
    ";

    // Use the 'glsl' variable in your Haxe code
    trace(glsl); 
  }
}


**Explanation:**

* Haxe doesn't have a direct equivalent to JavaScript's template literals with backticks (``). 
* Instead, we use standard double quotes (") for strings. 
* The  `/* glsl */`  part remains the same, acting as a comment within Haxe while preserving the GLSL code.

**How to Use:**

1. **Embed in a String:** The provided Haxe code embeds the GLSL code directly into a string variable named `glsl`. You can then use this variable to pass your GLSL code to wherever it's needed (e.g., shader compilation). 

2. **External File:** For larger GLSL code blocks, it's often better to keep your shaders in separate files. You can then load them into your Haxe code using file I/O.

**Example with External File (using `sys.io.File`):**


class Main {
  public static function main():Void {
    var glsl = sys.io.File.getContent("path/to/your/shader.glsl"); 
    trace(glsl);
  }
}