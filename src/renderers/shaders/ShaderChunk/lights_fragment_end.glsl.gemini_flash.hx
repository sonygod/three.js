class Example {
  public static function main(): Void {
    var glsl:String = /* glsl */
      "#if defined( RE_IndirectDiffuse )\n" +
      "\n" +
      "	RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );\n" +
      "\n" +
      "#endif\n" +
      "\n" +
      "#if defined( RE_IndirectSpecular )\n" +
      "\n" +
      "	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );\n" +
      "\n" +
      "#endif\n";
  }
}