class Output {
  public static function main(): Void {
    #if USE_UV || USE_ANISOTROPY
    var vUv: Vec2;
    #end
    #if USE_MAP
    var mapTransform: Mat3;
    var vMapUv: Vec2;
    #end
    #if USE_ALPHAMAP
    var alphaMapTransform: Mat3;
    var vAlphaMapUv: Vec2;
    #end
    #if USE_LIGHTMAP
    var lightMapTransform: Mat3;
    var vLightMapUv: Vec2;
    #end
    #if USE_AOMAP
    var aoMapTransform: Mat3;
    var vAoMapUv: Vec2;
    #end
    #if USE_BUMPMAP
    var bumpMapTransform: Mat3;
    var vBumpMapUv: Vec2;
    #end
    #if USE_NORMALMAP
    var normalMapTransform: Mat3;
    var vNormalMapUv: Vec2;
    #end
    #if USE_DISPLACEMENTMAP
    var displacementMapTransform: Mat3;
    var vDisplacementMapUv: Vec2;
    #end
    #if USE_EMISSIVEMAP
    var emissiveMapTransform: Mat3;
    var vEmissiveMapUv: Vec2;
    #end
    #if USE_METALNESSMAP
    var metalnessMapTransform: Mat3;
    var vMetalnessMapUv: Vec2;
    #end
    #if USE_ROUGHNESSMAP
    var roughnessMapTransform: Mat3;
    var vRoughnessMapUv: Vec2;
    #end
    #if USE_ANISOTROPYMAP
    var anisotropyMapTransform: Mat3;
    var vAnisotropyMapUv: Vec2;
    #end
    #if USE_CLEARCOATMAP
    var clearcoatMapTransform: Mat3;
    var vClearcoatMapUv: Vec2;
    #end
    #if USE_CLEARCOAT_NORMALMAP
    var clearcoatNormalMapTransform: Mat3;
    var vClearcoatNormalMapUv: Vec2;
    #end
    #if USE_CLEARCOAT_ROUGHNESSMAP
    var clearcoatRoughnessMapTransform: Mat3;
    var vClearcoatRoughnessMapUv: Vec2;
    #end
    #if USE_SHEEN_COLORMAP
    var sheenColorMapTransform: Mat3;
    var vSheenColorMapUv: Vec2;
    #end
    #if USE_SHEEN_ROUGHNESSMAP
    var sheenRoughnessMapTransform: Mat3;
    var vSheenRoughnessMapUv: Vec2;
    #end
    #if USE_IRIDESCENCEMAP
    var iridescenceMapTransform: Mat3;
    var vIridescenceMapUv: Vec2;
    #end
    #if USE_IRIDESCENCE_THICKNESSMAP
    var iridescenceThicknessMapTransform: Mat3;
    var vIridescenceThicknessMapUv: Vec2;
    #end
    #if USE_SPECULARMAP
    var specularMapTransform: Mat3;
    var vSpecularMapUv: Vec2;
    #end
    #if USE_SPECULAR_COLORMAP
    var specularColorMapTransform: Mat3;
    var vSpecularColorMapUv: Vec2;
    #end
    #if USE_SPECULAR_INTENSITYMAP
    var specularIntensityMapTransform: Mat3;
    var vSpecularIntensityMapUv: Vec2;
    #end
    #if USE_TRANSMISSIONMAP
    var transmissionMapTransform: Mat3;
    var vTransmissionMapUv: Vec2;
    #end
    #if USE_THICKNESSMAP
    var thicknessMapTransform: Mat3;
    var vThicknessMapUv: Vec2;
    #end
  }
}

// You need to define Vec2 and Mat3 types yourself, 
// or use an existing library like h3d.Vector2 and h3d.Matrix.
@:struct class Vec2 {
  public var x: Float;
  public var y: Float;
  public function new(x: Float = 0, y: Float = 0) {
    this.x = x;
    this.y = y;
  }
}

@:struct class Mat3 {
  // Define Mat3 structure here, if needed.
}