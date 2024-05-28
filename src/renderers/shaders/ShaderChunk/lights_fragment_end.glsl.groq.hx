package three.js.src.renderers.shaders.ShaderChunk;

class LightsFragmentEndGlsl {
  public static function shader():String {
    var shaderCode:String = "";
    
    #if (RE_IndirectDiffuse)
    shaderCode += "RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );";
    #end
    
    #if (RE_IndirectSpecular)
    shaderCode += "RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );";
    #end
    
    return shaderCode;
  }
}