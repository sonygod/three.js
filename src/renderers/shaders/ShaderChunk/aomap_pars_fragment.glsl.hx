package three.shaderlib;

import haxe.macro.Expr;

class AOMAP_pars_fragment {
  public static var shader:String = '
#ifdef USE_AOMAP

	@uniform sampler2D aoMap;
	@uniform float aoMapIntensity;

#endif
';
}