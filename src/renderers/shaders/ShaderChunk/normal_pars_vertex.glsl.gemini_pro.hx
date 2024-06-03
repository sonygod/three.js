class Glsl {
  static function flatShaded(code:String):String {
    return code.replace("#ifndef FLAT_SHADED", "#ifndef FLAT_SHADED\n\n\tvarying vec3 vNormal;");
  }

  static function useTangent(code:String):String {
    return code.replace("#ifdef USE_TANGENT", "#ifdef USE_TANGENT\n\n\t\tvarying vec3 vTangent;\n\t\tvarying vec3 vBitangent;");
  }
}

var code = `
#ifndef FLAT_SHADED

	varying vec3 vNormal;

	#ifdef USE_TANGENT

		varying vec3 vTangent;
		varying vec3 vBitangent;

	#endif

#endif
`;

code = Glsl.flatShaded(code);
code = Glsl.useTangent(code);

trace(code);