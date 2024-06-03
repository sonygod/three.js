class Glsl {
  static function glsl(code:String):String {
    return code;
  }
}

var glslCode = Glsl.glsl(`
#ifdef USE_FOG

	uniform vec3 fogColor;
	varying float vFogDepth;

	#ifdef FOG_EXP2

		uniform float fogDensity;

	#else

		uniform float fogNear;
		uniform float fogFar;

	#endif

#endif
`);

// Export the glsl code as a string
export default glslCode;