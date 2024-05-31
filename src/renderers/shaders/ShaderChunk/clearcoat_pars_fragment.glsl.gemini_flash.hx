class Shader {

  public static var source: String = /* glsl */
  """
  #ifdef USE_CLEARCOATMAP
    uniform sampler2D clearcoatMap;
  #end

  #ifdef USE_CLEARCOAT_NORMALMAP
    uniform sampler2D clearcoatNormalMap;
    uniform vec2 clearcoatNormalScale;
  #end

  #ifdef USE_CLEARCOAT_ROUGHNESSMAP
    uniform sampler2D clearcoatRoughnessMap;
  #end
  """;
}


**Explanation:**

- **Haxe doesn't directly support preprocessor directives like `#ifdef`:** In Haxe, these are typically handled through conditional compilation flags set during the build process. 
- **We've moved the GLSL code into a String variable:**  Haxe shaders are typically embedded as strings within the code. 
- **We created a class to encapsulate the shader code:** This makes it more organized, especially if you have multiple shaders.

**To use this Haxe shader:**

1. **Set conditional compilation flags (if needed):**  Depending on your build system, you'll use flags like `-D USE_CLEARCOATMAP` to activate the respective code blocks when compiling your Haxe code.  
2. **Access the shader code:** You can then access the GLSL code using `Shader.source`.

**Example (assuming you're using a Haxe library for OpenGL/WebGL):**


// Assuming you've set conditional compilation flags appropriately

// ... Other code ...

var shaderProgram = new ShaderProgram(); 
shaderProgram.addShader(Shader.source); 

// ... Continue setting up and using your shader ...