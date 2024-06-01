class Main {
  public static function main(): Void {
    var glsl = /* glsl */
      "#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )\n" +
      "\n" +
      "	// Offsetting the position used for querying occlusion along the world normal can be used to reduce shadow acne.\n" +
      "	vec3 shadowWorldNormal = inverseTransformDirection( transformedNormal, viewMatrix );\n" +
      "	vec4 shadowWorldPosition;\n" +
      "\n" +
      "#endif\n" +
      "\n" +
      "#if defined( USE_SHADOWMAP )\n" +
      "\n" +
      "	#if NUM_DIR_LIGHT_SHADOWS > 0\n" +
      "\n" +
      "		#pragma unroll_loop_start\n" +
      "		for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {\n" +
      "\n" +
      "			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * directionalLightShadows[ i ].shadowNormalBias, 0.0 );\n" +
      "			vDirectionalShadowCoord[ i ] = directionalShadowMatrix[ i ] * shadowWorldPosition;\n" +
      "\n" +
      "		}\n" +
      "		#pragma unroll_loop_end\n" +
      "\n" +
      "	#endif\n" +
      "\n" +
      "	#if NUM_POINT_LIGHT_SHADOWS > 0\n" +
      "\n" +
      "		#pragma unroll_loop_start\n" +
      "		for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {\n" +
      "\n" +
      "			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * pointLightShadows[ i ].shadowNormalBias, 0.0 );\n" +
      "			vPointShadowCoord[ i ] = pointShadowMatrix[ i ] * shadowWorldPosition;\n" +
      "\n" +
      "		}\n" +
      "		#pragma unroll_loop_end\n" +
      "\n" +
      "	#endif\n" +
      "\n" +
      "	/*\n" +
      "	#if NUM_RECT_AREA_LIGHTS > 0\n" +
      "\n" +
      "		// TODO (abelnation): update vAreaShadowCoord with area light info\n" +
      "\n" +
      "	#endif\n" +
      "	*/\n" +
      "\n" +
      "#endif\n" +
      "\n" +
      "// spot lights can be evaluated without active shadow mapping (when SpotLight.map is used)\n" +
      "\n" +
      "#if NUM_SPOT_LIGHT_COORDS > 0\n" +
      "\n" +
      "	#pragma unroll_loop_start\n" +
      "	for ( int i = 0; i < NUM_SPOT_LIGHT_COORDS; i ++ ) {\n" +
      "\n" +
      "		shadowWorldPosition = worldPosition;\n" +
      "		#if ( defined( USE_SHADOWMAP ) && UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )\n" +
      "			shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[ i ].shadowNormalBias;\n" +
      "		#endif\n" +
      "		vSpotLightCoord[ i ] = spotLightMatrix[ i ] * shadowWorldPosition;\n" +
      "\n" +
      "	}\n" +
      "	#pragma unroll_loop_end\n" +
      "\n" +
      "#endif\n" +
      "\n";
  }
}


Haxe doesn't have a direct equivalent for GLSL preprocessor directives like `#if`, `#pragma`, etc. 

Here's what I did:

* **Removed the `export default`:** This is specific to JavaScript modules and doesn't have a direct equivalent in Haxe.
* **Enclosed the GLSL code in a Haxe string:** This preserves the GLSL code as-is, allowing you to use it later when interacting with a graphics API.

**To use this GLSL code in your Haxe project:**

1. **Include the necessary graphics library:** Choose a Haxe graphics library like Luxe, OpenFL, or Kha.
2. **Compile the GLSL code:**  Most graphics libraries provide ways to compile GLSL shaders from strings. 
3. **Use the compiled shader:** Apply the compiled shader to your 3D objects.

**Example with Luxe:**


import luxe.Core;
import luxe.graphics.Shader;

class MyGame extends luxe.Game {
  var shader:Shader;

  override function onready():Void {
    shader = Shader.create(glsl); // 'glsl' is the string containing your code
    // ... rest of your setup
  }

  // ... other game logic 
}