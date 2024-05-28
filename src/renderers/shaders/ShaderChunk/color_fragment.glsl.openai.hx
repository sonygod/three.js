package three.renderers.shaders.ShaderChunk;

class ColorFragmentGlsl {
  public static var code:String = "
#if defined( USE_COLOR_ALPHA )
  diffuseColor *= vColor;
#elif defined( USE_COLOR )
  diffuseColor.rgb *= vColor;
#endif
";
}

Note that:

* In Haxe, we need to wrap the code in a class, so I created a `ColorFragmentGlsl` class.
* The `export default` syntax is not needed in Haxe, as we can directly assign the GLSL code to a `String` variable.
* The `/* glsl */` comment is not needed in Haxe, as we're already defining a `String` variable.
* The backticks (`