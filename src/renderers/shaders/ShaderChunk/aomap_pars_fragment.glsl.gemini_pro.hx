class Shader {

  public static function main(): String {
    return /* glsl */  "
#ifdef USE_AOMAP

	uniform sampler2D aoMap;
	uniform float aoMapIntensity;

#endif
";
  }
}