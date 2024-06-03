class ShaderLib {
    public static var vertex:String = """
    #define STANDARD

    varying vec3 vViewPosition;

    // ... rest of the shader code ...
    """;

    public static var fragment:String = """
    #define STANDARD

    #ifdef PHYSICAL
        #define IOR
        #define USE_SPECULAR
    #endif

    uniform vec3 diffuse;
    uniform vec3 emissive;
    // ... rest of the shader code ...
    """;
}


Then, in your WebGL context, you would load these shaders:


// Assuming you have a WebGL context and utility functions to compile and link shaders
var vertexShader:WebGLShader = compileShader(context.VERTEX_SHADER, ShaderLib.vertex);
var fragmentShader:WebGLShader = compileShader(context.FRAGMENT_SHADER, ShaderLib.fragment);
var program:WebGLProgram = linkProgram(vertexShader, fragmentShader);