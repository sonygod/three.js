package;

class ShaderCode {
    public static var code:String = "#if defined( RE_IndirectDiffuse ) \n\tRE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight ); \n#endif \n\n#if defined( RE_IndirectSpecular ) \n\tRE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight ); \n#endif";
}