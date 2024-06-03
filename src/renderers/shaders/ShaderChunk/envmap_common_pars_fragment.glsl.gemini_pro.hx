class Glsl extends haxe.macro.Macro {
  static function get(ctx:haxe.macro.Context, args:Array<haxe.macro.Expr>):haxe.macro.Expr {
    var code = args[0].toString();
    return macro StringTools.trim(code);
  }
}

var glsl = Glsl.get;

class Main {
  static function main() {
    var code = glsl(/* glsl */`
#ifdef USE_ENVMAP

	uniform float envMapIntensity;
	uniform float flipEnvMap;
	uniform mat3 envMapRotation;

	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	
#endif
`);
    trace(code);
  }
}