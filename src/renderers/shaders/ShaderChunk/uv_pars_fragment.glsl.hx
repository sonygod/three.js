package three.shaders;

class UVParsFragment {
  #if (defined(USE_UV) || defined(USE_ANISOTROPY))
  @:varying public var vUv:Vec2;
  #end

  #ifdef USE_MAP
  @:varying public var vMapUv:Vec2;
  #end

  #ifdef USE_ALPHAMAP
  @:varying public var vAlphaMapUv:Vec2;
  #end

  #ifdef USE_LIGHTMAP
  @:varying public var vLightMapUv:Vec2;
  #end

  #ifdef USE_AOMAP
  @:varying public var vAoMapUv:Vec2;
  #end

  #ifdef USE_BUMPMAP
  @:varying public var vBumpMapUv:Vec2;
  #end

  #ifdef USE_NORMALMAP
  @:varying public var vNormalMapUv:Vec2;
  #end

  #ifdef USE_EMISSIVEMAP
  @:varying public var vEmissiveMapUv:Vec2;
  #end

  #ifdef USE_METALNESSMAP
  @:varying public var vMetalnessMapUv:Vec2;
  #end

  #ifdef USE_ROUGHNESSMAP
  @:varying public var vRoughnessMapUv:Vec2;
  #end

  #ifdef USE_ANISOTROPYMAP
  @:varying public var vAnisotropyMapUv:Vec2;
  #end

  #ifdef USE_CLEARCOATMAP
  @:varying public var vClearcoatMapUv:Vec2;
  #end

  #ifdef USE_CLEARCOAT_NORMALMAP
  @:varying public var vClearcoatNormalMapUv:Vec2;
  #end

  #ifdef USE_CLEARCOAT_ROUGHNESSMAP
  @:varying public var vClearcoatRoughnessMapUv:Vec2;
  #end

  #ifdef USE_IRIDESCENCEMAP
  @:varying public var vIridescenceMapUv:Vec2;
  #end

  #ifdef USE_IRIDESCENCE_THICKNESSMAP
  @:varying public var vIridescenceThicknessMapUv:Vec2;
  #end

  #ifdef USE_SHEEN_COLORMAP
  @:varying public var vSheenColorMapUv:Vec2;
  #end

  #ifdef USE_SHEEN_ROUGHNESSMAP
  @:varying public var vSheenRoughnessMapUv:Vec2;
  #end

  #ifdef USE_SPECULARMAP
  @:varying public var vSpecularMapUv:Vec2;
  #end

  #ifdef USE_SPECULAR_COLORMAP
  @:varying public var vSpecularColorMapUv:Vec2;
  #end

  #ifdef USE_SPECULAR_INTENSITYMAP
  @:varying public var vSpecularIntensityMapUv:Vec2;
  #end

  #ifdef USE_TRANSMISSIONMAP
  @:uniform public var transmissionMapTransform:Mat3;
  @:varying public var vTransmissionMapUv:Vec2;
  #end

  #ifdef USE_THICKNESSMAP
  @:uniform public var thicknessMapTransform:Mat3;
  @:varying public var vThicknessMapUv:Vec2;
  #end
}