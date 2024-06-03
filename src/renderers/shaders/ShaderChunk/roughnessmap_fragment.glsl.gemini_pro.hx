class Glsl {
  static function generate(roughness:Float):String {
    var code = "float roughnessFactor = roughness;\n";

    code += "#ifdef USE_ROUGHNESSMAP\n";
    code += "  vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );\n";
    code += "  // reads channel G, compatible with a combined OcclusionRoughnessMetallic (RGB) texture\n";
    code += "  roughnessFactor *= texelRoughness.g;\n";
    code += "#endif\n";

    return code;
  }
}


**Explanation:**

1. **Class Structure:** We define a class `Glsl` to encapsulate the GLSL code generation.
2. **`generate` Function:** This function takes the `roughness` value as input and constructs the GLSL code string.
3. **Code Structure:** The code is identical to the JavaScript version, but we use string concatenation in Haxe to build the GLSL string.
4. **`#ifdef` Preprocessor Directive:** The `#ifdef` directive remains the same for conditional compilation, allowing the code to adapt based on the presence of the `USE_ROUGHNESSMAP` flag.

**Usage:**

To use this code, simply call the `generate` function with the desired `roughness` value:


var glslCode = Glsl.generate(0.5);


This will return a string containing the generated GLSL code:


float roughnessFactor = 0.5;

#ifdef USE_ROUGHNESSMAP
  vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );
  // reads channel G, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
  roughnessFactor *= texelRoughness.g;
#endif