class UVVertex {
    public static function main(uv:Float, mapTransform:Float, alphaMapTransform:Float, lightMapTransform:Float, aoMapTransform:Float, bumpMapTransform:Float, normalMapTransform:Float, displacementMapTransform:Float, emissiveMapTransform:Float, metalnessMapTransform:Float, roughnessMapTransform:Float, anisotropyMapTransform:Float, clearcoatMapTransform:Float, clearcoatNormalMapTransform:Float, clearcoatRoughnessMapTransform:Float, iridescenceMapTransform:Float, iridescenceThicknessMapTransform:Float, sheenColorMapTransform:Float, sheenRoughnessMapTransform:Float, specularMapTransform:Float, specularColorMapTransform:Float, specularIntensityMapTransform:Float, transmissionMapTransform:Float, thicknessMapTransform:Float):Void {
        #if defined(USE_UV) || defined(USE_ANISOTROPY)
            var vUv = new haxe.math.Vec3(uv, 1, 1).xy;
        #endif
        #ifdef USE_MAP
            var vMapUv = (mapTransform * new haxe.math.Vec3(MAP_UV, 1, 1)).xy;
        #endif
        // ... 其他的变量定义 ...
    }
}