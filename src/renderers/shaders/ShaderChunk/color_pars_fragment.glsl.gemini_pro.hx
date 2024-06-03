class Glsl {

  static function convert(code:String):String {
    return code;
  }
}

var glsl = Glsl.convert(`
#if defined( USE_COLOR_ALPHA )

	varying vec4 vColor;

#elif defined( USE_COLOR )

	varying vec3 vColor;

#endif
`);