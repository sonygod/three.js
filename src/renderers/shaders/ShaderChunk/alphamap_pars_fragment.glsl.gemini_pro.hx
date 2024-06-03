class Shader {
  public static var source: String = /* glsl */
    """
    #ifdef USE_ALPHAMAP

      uniform sampler2D alphaMap;

    #endif
    """;
}


Here's why this works and how it compares to the JavaScript version:

- **No Default Exports:** Haxe doesn't have a direct equivalent of JavaScript's `export default`. Instead, you define a class (`Shader` in this case) and make its members (like the `source` variable) public to expose them for use in other parts of your Haxe project.

- **String Literals:** The triple-quoted string (`"""..."""`) is a multiline string literal in Haxe, similar to JavaScript's backticks (...) for template literals. This preserves the formatting of your GLSL code.

- **Direct GLSL Embedding:** Just like in JavaScript, you can embed your GLSL code directly within the Haxe string. The `/* glsl */` comment is optional but helps with code clarity, indicating that the content is GLSL.

**How to use it:**

You can access the GLSL code from other parts of your Haxe project like this:


var myShaderSource = Shader.source;
// Now use myShaderSource (which contains your GLSL code) 
// to create shaders within your Haxe graphics framework.