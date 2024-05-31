class Shader {
  public static var fragmentSource:String = /* glsl */"
    gl_FragColor = linearToOutputTexel( gl_FragColor );
  ";
}


**Explanation:**

* **Class Definition:** Haxe code is typically organized within classes. We define a class named `Shader` to encapsulate the shader code.
* **Static Variable:**  The shader code is stored in a `public static var` named `fragmentSource`. This makes it accessible from anywhere in your project.
* **String Literal:** The actual GLSL code remains unchanged within a multiline string literal denoted by `"`.

**How to use:**

You can access the shader code from other parts of your Haxe project using:


var myShaderCode:String = Shader.fragmentSource;