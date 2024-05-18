Here is the equivalent Haxe code:
```
package renderers.shaders.ShaderChunk;

class NormalParsFragmentGlsl {
  public static var shaderCode:String = "
#ifndef FLAT_SHADED

  varying vec3 vNormal;

  #ifdef USE_TANGENT

  varying vec3 vTangent;
  varying vec3 vBitangent;

  #endif

#endif
";
}
```
Note that in Haxe, we don't have a direct equivalent to JavaScript's `export default`, so I've created a `NormalParsFragmentGlsl` class with a `shaderCode` static variable to hold the GLSL shader code.

Also, I've kept the same file path as the original JavaScript file, but in Haxe, we use packages and classes instead of files and exports.