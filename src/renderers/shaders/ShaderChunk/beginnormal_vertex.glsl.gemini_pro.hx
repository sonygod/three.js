class ShaderUtils {
  public static function objectNormal():String {
    return /* glsl */  "
      vec3 objectNormal = vec3( normal );

      #ifdef USE_TANGENT

        vec3 objectTangent = vec3( tangent.xyz );

      #endif
    ";
  }
}


This code does the following:

- **Creates a class:** Instead of using a default export, we create a class called `ShaderUtils` to hold our GLSL code. This is a common practice in Haxe to organize code.
- **Creates a static function:** The `objectNormal()` function is static, meaning it can be called directly from the class without creating an instance. This makes it easy to access the GLSL code.
- **Returns the GLSL code:** The function returns the GLSL code as a string. You can then use this string to inject the code into your shaders.

Here's how you would use the code:


// Assuming you have a shader object
var shader = ...;

// Inject the GLSL code
shader.setVertexShader(shader.getVertexShader() + ShaderUtils.objectNormal());