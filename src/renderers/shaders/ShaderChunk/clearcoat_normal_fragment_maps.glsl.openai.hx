package three.shaderlib;

class ClearcoatNormalFragmentMaps {
  @:glsl("
#ifdef USE_CLEARCOAT_NORMALMAP

  vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vClearcoatNormalMapUv ).xyz * 2.0 - 1.0;
  clearcoatMapN.xy *= clearcoatNormalScale;

  clearcoatNormal = normalize( tbn2 * clearcoatMapN );

#endif
  ");
  public function new() {}
}