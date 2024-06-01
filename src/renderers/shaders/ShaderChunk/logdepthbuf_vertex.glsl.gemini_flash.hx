class Main {
  public static function main(): Void {
    // Haxe doesn't have a direct equivalent of JavaScript tagged template literals with /* glsl */.
    // You'll typically handle GLSL code separately in Haxe, often loading it from external files.

    // Here's a basic example of how you might structure your shader code in Haxe:

    class Shader {
      public static var vertexShader: String = "#version 300 es\n" +
        "in vec3 position;\n" +
        // ... rest of your vertex shader code
        "";

      public static var fragmentShader: String = "#version 300 es\n" +
        "precision mediump float;\n" +
        "#ifdef USE_LOGDEPTHBUF\n" +
        "  vFragDepth = 1.0 + gl_Position.w;\n" +
        "  vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );\n" +
        "#endif\n" +
        // ... rest of your fragment shader code
        "";
    }

    // ... later when setting up your shaders
    var gl = ...; // get WebGL context
    var vertexShader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertexShader, Shader.vertexShader);
    gl.compileShader(vertexShader);

    var fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, Shader.fragmentShader);
    gl.compileShader(fragmentShader);

    // ... rest of your shader setup
  }
}