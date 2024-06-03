class Main {
  public static function main(): Void {
    // No need for export default in Haxe.
    var glsl: String = /* glsl */
    "#if defined( USE_LOGDEPTHBUF )\n\
	// Doing a strict comparison with == 1.0 can cause noise artifacts\n\
	// on some platforms. See issue #17623.\n\
	gl_FragDepth = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;\n\
#endif\n";
  }
}


**Explanation:**

* **No `export default`:** Haxe doesn't use `export default`. You can directly assign the GLSL code to a variable.
* **String Literal:** The GLSL code is enclosed in triple quotes (`"""`) to create a multiline string literal.
* **No Changes to GLSL:** The actual GLSL code remains the same as it is platform-agnostic.

**How to use it:**

You can access the `glsl` variable in your Haxe code where you need to use the GLSL shader code. For example:


// ... other code ...

var shader:Shader = new Shader(glsl);

// ... use the shader ...