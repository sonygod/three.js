package three.renderers.shaders.ShaderChunk;

import haxe.macro.Expr;

class LightsFragmentEnd {
  public static var shader: String = "
    #if defined( RE_IndirectDiffuse )
      RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
    #end

    #if defined( RE_IndirectSpecular )
      RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
    #end
  ";
}