class ShaderMacros {
  public static function getLightmap():String {
    return /* glsl */  """
#ifdef USE_LIGHTMAP

	uniform sampler2D lightMap;
	uniform float lightMapIntensity;

#endif
""";
  }
}


Here's how the Haxe code addresses the conversion:

- **Class Structure:**  Instead of a direct export, we encapsulate the GLSL code within a Haxe class called `ShaderMacros`. This promotes organization and reusability.
- **Static Method:** The code snippet is placed within a static method named `getLightmap()`.  This makes the GLSL code accessible from other parts of your Haxe project.
- **String Literals:**  Haxe uses triple quotes (`""" ... """) for multiline string literals. This preserves the formatting of your GLSL code.

**How to Use:**

1. **Include:** Import the `ShaderMacros` class into your Haxe file where you need to use this GLSL code.

2. **Access:**  Retrieve the GLSL code using `ShaderMacros.getLightmap()`.

**Example:**


class MyShader {
  public function new() {
    var lightmapCode:String = ShaderMacros.getLightmap();
    // ... use lightmapCode in your shader setup ...
  }
}