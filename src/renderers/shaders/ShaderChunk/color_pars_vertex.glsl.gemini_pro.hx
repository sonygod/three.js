class Glsl {
  static function glsl(code:String) {
    return code;
  }
}

class Main {
  static function main() {
    var code = Glsl.glsl(`
#if defined( USE_COLOR_ALPHA )

	varying vec4 vColor;

#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )

	varying vec3 vColor;

#endif
`);
    trace(code);
  }
}