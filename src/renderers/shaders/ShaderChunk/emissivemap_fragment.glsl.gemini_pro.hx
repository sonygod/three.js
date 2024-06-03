class ShaderUtils {
  public static function getEmissiveFragment():String {
    return /* glsl */  """
#ifdef USE_EMISSIVEMAP
	vec4 emissiveColor = texture2D(emissiveMap, vEmissiveMapUv);
	totalEmissiveRadiance *= emissiveColor.rgb;
#endif
""";
  }
}


Here's a breakdown of the changes and considerations:

- **Haxe doesn't have tagged template literals like JavaScript's "glsl".**  We'll use standard Haxe multiline strings (`""" ... """) for the GLSL code.

- **No Direct `export default` Equivalent:** Haxe uses a class-based structure. We'll create a `ShaderUtils` class and put the GLSL code within a static function (`getEmissiveFragment`) for easy access. 

**How to Use in Your Haxe Project:**

1. **Include the `ShaderUtils` Class:** Make sure this code is in a Haxe file (e.g., `ShaderUtils.hx`) and that you import the class where you need it.

2. **Access the GLSL Code:**
   
   var myEmissiveFragmentShaderCode:String = ShaderUtils.getEmissiveFragment(); 
   trace(myEmissiveFragmentShaderCode); // Output the GLSL code