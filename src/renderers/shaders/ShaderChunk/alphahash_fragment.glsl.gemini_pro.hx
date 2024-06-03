class ShaderUtil {
  public static function main(): String {
    return 
"""
#ifdef USE_ALPHAHASH

	if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;

#endif
""";
  }
}


**Explanation:**

* **Class structure:** Haxe code is organized into classes. We create a class named `ShaderUtil` to hold the GLSL code.
* **String literal:** The GLSL code is enclosed in triple quotes (`"""..."""`) to create a multi-line string literal.
* **Static function:**  A static function `main` is used to return the GLSL code string. This is a common approach to make the code accessible from other parts of the Haxe project.

**How to use:**

You can access the GLSL code by calling the `main` function of the `ShaderUtil` class:


var glslCode: String = ShaderUtil.main();