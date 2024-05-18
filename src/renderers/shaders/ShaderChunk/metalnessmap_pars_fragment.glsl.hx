package three.shader;

import haxe.macro.Expr;

class MetalnessMapParsFragmentGlsl {
    public static var shaderSrc:String = "
#ifdef USE_METALNESSMAP

	uniform sampler2D metalnessMap;

#endif
";
}