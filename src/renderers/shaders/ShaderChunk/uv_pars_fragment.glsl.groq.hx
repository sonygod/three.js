Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.js.src.renderers.shaders.ShaderChunk;

class UVParsFragment {
  #if (defined(USE_UV) || defined(USE_ANISOTROPY))
  public var vUv:Vec2;
  #end

  #ifdef USE_MAP
  public var vMapUv:Vec2;
  #end

  #ifdef USE_ALPHAMAP
  public var vAlphaMapUv:Vec2;
  #end

  #ifdef USE_LIGHTMAP
  public var vLightMapUv:Vec2;
  #end

  #ifdef USE_AOMAP
  public var vAoMapUv:Vec2;
  #end

  #ifdef USE_BUMPMAP
  public var vBumpMapUv:Vec2;
  #end

  #ifdef USE_NORMALMAP
  public var vNormalMapUv:Vec2;
  #end

  #ifdef USE_EMISSIVEMAP
  public var vEmissiveMapUv:Vec2;
  #end

  #ifdef USE_METALNESSMAP
  public var vMetalnessMapUv:Vec2;
  #end

  #ifdef USE_ROUGHNESSMAP
  public var vRoughnessMapUv:Vec2;
  #end

  #ifdef USE_ANISOTROPYMAP
  public var vAnisotropyMapUv:Vec2;
  #end

  #ifdef USE_CLEARCOATMAP
  public var vClearcoatMapUv:Vec2;
  #end

  #ifdef USE_CLEARCOAT_NORMALMAP
  public var vClearcoatNormalMapUv:Vec2;
  #end

  #ifdef USE_CLEARCOAT_ROUGHNESSMAP
  public var vClearcoatRoughnessMapUv:Vec2;
  #end

  #ifdef USE_IRIDESCENCEMAP
  public var vIridescenceMapUv:Vec2;
  #end

  #ifdef USE_IRIDESCENCE_THICKNESSMAP
  public var vIridescenceThicknessMapUv:Vec2;
  #end

  #ifdef USE_SHEEN_COLORMAP
  public var vSheenColorMapUv:Vec2;
  #end

  #ifdef USE_SHEEN_ROUGHNESSMAP
  public var vSheenRoughnessMapUv:Vec2;
  #end

  #ifdef USE_SPECULARMAP
  public var vSpecularMapUv:Vec2;
  #end

  #ifdef USE_SPECULAR_COLORMAP
  public var vSpecularColorMapUv:Vec2;
  #end

  #ifdef USE_SPECULAR_INTENSITYMAP
  public var vSpecularIntensityMapUv:Vec2;
  #end

  #ifdef USE_TRANSMISSIONMAP
  public var transmissionMapTransform:Mat3;
  public var vTransmissionMapUv:Vec2;
  #end

  #ifdef USE_THICKNESSMAP
  public var thicknessMapTransform:Mat3;
  public var vThicknessMapUv:Vec2;
  #end
}
```
Note that I've used Haxe's syntax for conditional compilation directives (`#if`, `#ifdef`, etc.) and variable declarations. I've also assumed that `Vec2` and `Mat3` are Haxe types that correspond to 2-component vectors and 3x3 matrices, respectively.