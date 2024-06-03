import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Macro;

class GlslMacro extends Macro {
  public function onMacro(context:Context, expr:Expr):Expr {
    var code = expr.toString().split('\n').map(line => line.trim()).join('\n');
    return Context.makeExpr(code);
  }
}

@:build(GlslMacro)
class Glsl {
  public static inline function main(code:String):String {
    return code;
  }
}

class Main {
  static function main() {
    var glsl = Glsl.main(`
#if defined( RE_IndirectDiffuse )

	#ifdef USE_LIGHTMAP

		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;

		irradiance += lightMapIrradiance;

	#endif

	#if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )

		iblIrradiance += getIBLIrradiance( geometryNormal );

	#endif

#endif

#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )

	#ifdef USE_ANISOTROPY

		radiance += getIBLAnisotropyRadiance( geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy );

	#else

		radiance += getIBLRadiance( geometryViewDir, geometryNormal, material.roughness );

	#endif

	#ifdef USE_CLEARCOAT

		clearcoatRadiance += getIBLRadiance( geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness );

	#endif

#endif
`);
    trace(glsl);
  }
}