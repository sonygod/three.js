package three.shader;

import haxe.macro.Expr;

class MetalnessMapParsFragment {
  public static var shader: String = "
#ifdef USE_METALNESSMAP

  uniform sampler2D metalnessMap;

#endif
";
}