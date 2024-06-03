class Glsl {
  static function convert(code:String):String {
    var lines = code.split("\n");
    var result = "";
    for (line in lines) {
      line = line.trim();
      if (line.startsWith("//")) {
        result += line + "\n";
      } else if (line.startsWith("#if")) {
        result += "//" + line + "\n";
      } else if (line.startsWith("#ifdef")) {
        result += "//" + line + "\n";
      } else if (line.startsWith("#endif")) {
        result += "//" + line + "\n";
      } else {
        result += line + "\n";
      }
    }
    return result;
  }
}

class Main {
  static function main() {
    var glslCode =
      """
#if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0

	vec4 worldPosition = vec4( transformed, 1.0 );

	#ifdef USE_BATCHING

		worldPosition = batchingMatrix * worldPosition;

	#endif

	#ifdef USE_INSTANCING

		worldPosition = instanceMatrix * worldPosition;

	#endif

	worldPosition = modelMatrix * worldPosition;

#endif
""";
    var convertedCode = Glsl.convert(glslCode);
    trace(convertedCode);
  }
}