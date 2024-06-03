class Shader {
  public static var fragmentShaderSource:String = /* glsl */"
    gl_FragColor = linearToOutputTexel( gl_FragColor );
  ";
}


**Explanation:**

* **Class Declaration:** Haxe code is typically organized within classes. We create a class named `Shader` to hold the shader code.
* **Static Variable:** We declare a `public static` variable named `fragmentShaderSource` to store the GLSL code. This makes the code accessible from other parts of your Haxe project.
* **String Type:** The shader code is stored as a `String`.
* **Multi-line String:** Haxe supports multi-line strings using the same syntax as JavaScript.

**How to Use:**

You can access the shader code from anywhere in your project using the following:


var shaderCode = Shader.fragmentShaderSource;