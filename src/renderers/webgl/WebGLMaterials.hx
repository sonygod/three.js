import Euler from "../../math/Euler";
import Matrix4 from "../../math/Matrix4";

class WebGLMaterials {

private static _e1:Euler = new Euler();
private static _m1:Matrix4 = new Matrix4();

public static function refreshTransformUniform(map:Map, uniform:Uniform):Void {
if (map.matrixAutoUpdate === true) {
map.updateMatrix();
}
uniform.value.copy(map.matrix);
}

public static function refreshFogUniforms(uniforms:Uniforms, fog:Fog):Void {
fog.color.getRGB(uniforms.fogColor.value, getUnlitUniformColorSpace(renderer));
if (fog.isFog) {
uniforms.fogNear.value = fog.near;
uniforms.fogFar.value = fog.far;
} else if (fog.isFogExp2) {
uniforms.fogDensity.value = fog.density;
}
}

public static function refreshMaterialUniforms(uniforms:Uniforms, material:Material, pixelRatio:Float, height:Int, transmissionRenderTarget:RenderTarget):Void {
if (material.isMeshBasicMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
} else if (material.isMeshLambertMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
} else if (material.isMeshToonMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
WebGLMaterials.refreshUniformsToon(uniforms, material);
} else if (material.isMeshPhongMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
WebGLMaterials.refreshUniformsPhong(uniforms, material);
} else if (material.isMeshStandardMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
WebGLMaterials.refreshUniformsStandard(uniforms, material);
if (material.isMeshPhysicalMaterial) {
WebGLMaterials.refreshUniformsPhysical(uniforms, material, transmissionRenderTarget);
}
} else if (material.isMeshMatcapMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
WebGLMaterials.refreshUniformsMatcap(uniforms, material);
} else if (material.isMeshDepthMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
} else if (material.isMeshDistanceMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
WebGLMaterials.refreshUniformsDistance(uniforms, material);
} else if (material.isMeshNormalMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
} else if (material.isLineBasicMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
if (material.isLineDashedMaterial) {
WebGLMaterials.refreshUniformsDash(uniforms, material);
}
} else if (material.isPointsMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
WebGLMaterials.refreshUniformsPoints(uniforms, material, pixelRatio, height);
} else if (material.isSpriteMaterial) {
WebGLMaterials.refreshUniformsCommon(uniforms, material);
WebGLMaterials.refreshUniformsSprites(uniforms, material);
} else if (material.isShadowMaterial) {
uniforms.color.value.copy(material.color);
uniforms.opacity.value = material.opacity;
} else if (material.isShaderMaterial) {
material.uniformsNeedUpdate = false; // #15581
}
}

public static function refreshUniformsCommon(uniforms:Uniforms, material:Material):Void {
uniforms.opacity.value = material.opacity;
if (material.color) {
uniforms.diffuse.value.copy(material.color);
}
if (material.emissive) {
uniforms.emissive.value.copy(material.emissive).multiplyScalar(material.emissiveIntensity);
}
if (material.map) {
uniforms.map.value = material.map;
WebGLMaterials.refreshTransformUniform(material.map, uniforms.mapTransform);
}
if (material.alphaMap) {
uniforms.alphaMap.value = material.alphaMap;
WebGLMaterials.refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
}
if (material.bumpMap) {
uniforms.bumpMap.value = material.bumpMap;
WebGLMaterials.refreshTransformUniform(material.bumpMap, uniforms.bumpMapTransform);
uniforms.bumpScale.value = material.bumpScale;
if (material.side === BackSide) {
uniforms.bumpScale.value *= -1;
}
}
if (material.normalMap) {
uniforms.normalMap.value = material.normalMap;
WebGLMaterials.refreshTransformUniform(material.normalMap, uniforms.normalMapTransform);
uniforms.normalScale.value.copy(material.normalScale);
if (material.side === BackSide) {
uniforms.normalScale.value.negate();
}
}
if (material.displacementMap) {
uniforms.displacementMap.value = material.displacementMap;
WebGLMaterials.refreshTransformUniform(material.displacementMap, uniforms.displacementMapTransform);
uniforms.displacementScale.value = material.displacementScale;
uniforms.displacementBias.value = material.displacementBias;
}
if (material.emissiveMap) {
uniforms.emissiveMap.value = material.emissiveMap;
WebGLMaterials.refreshTransformUniform(material.emissiveMap, uniforms.emissiveMapTransform);
}
if (material.specularMap) {
uniforms.specularMap.value = material.specularMap;
WebGLMaterials.refreshTransformUniform(material.specularMap, uniforms.specularMapTransform);
}
if (material.alphaTest > 0) {
uniforms.alphaTest.value = material.alphaTest;
}
const materialProperties = properties.get(material);
const envMap = materialProperties.envMap;
const envMapRotation = materialProperties.envMapRotation;
if (envMap) {
uniforms.envMap.value = envMap;
WebGLMaterials._e1.copy(envMapRotation);
// accommodate left-handed frame
WebGLMaterials._e1.x *= -1; WebGLMaterials._e1.y *= -1; WebGLMaterials._e1.z *= -1;
if (envMap.isCubeTexture && envMap.isRenderTargetTexture === false) {
// environment maps which are not cube render targets or PMREMs follow a different convention
WebGLMaterials._e1.y *= -1;
WebGLMaterials._e1.z *= -1;
}
uniforms.envMapRotation.value.setFromMatrix4(WebGLMaterials._m1.makeRotationFromEuler(WebGLMaterials._e1));
uniforms.flipEnvMap.value = (envMap.isCubeTexture && envMap.isRenderTargetTexture === false) ? -1 : 1;
uniforms.reflectivity.value = material.reflectivity;
uniforms.ior.value = material.ior;
uniforms.refractionRatio.value = material.refractionRatio;
}
if (material.lightMap) {
uniforms.lightMap.value = material.lightMap;
// artist-friendly light intensity scaling factor
const scaleFactor = (renderer._useLegacyLights === true) ? Math.PI : 1;
uniforms.lightMapIntensity.value = material.lightMapIntensity * scaleFactor;
WebGLMaterials.refreshTransformUniform(material.lightMap, uniforms.lightMapTransform);
}
if (material.aoMap) {
uniforms.aoMap.value = material.aoMap;
uniforms.aoMapIntensity.value = material.aoMapIntensity;
WebGLMaterials.refreshTransformUniform(material.aoMap, uniforms.aoMapTransform);
}
}

public static function refreshUniformsLine(uniforms:Uniforms, material:Material):Void {
uniforms.diffuse.value.copy(material.color);
uniforms.opacity.value = material.opacity;
if (material.map) {
uniforms.map.value = material.map;
WebGLMaterials.refreshTransformUniform(material.map, uniforms.mapTransform);
}
}

public static function refreshUniformsDash(uniforms:Uniforms, material:Material):Void {
uniforms.dashSize.value = material.dashSize;
uniforms.totalSize.value = material.dashSize + material.gapSize;
uniforms.scale.value = material.scale;
}

public static function refreshUniformsPoints(uniforms:Uniforms, material:Material, pixelRatio:Float, height:Int):Void {
uniforms.diffuse.value.copy(material.color);
uniforms.opacity.value = material.opacity;
uniforms.size.value = material.size * pixelRatio;
uniforms.scale.value = height * 0.5;
if (material.map) {
uniforms.map.value = material.map;
WebGLMaterials.refreshTransformUniform(material.map, uniforms.uvTransform);
}
if (material.alphaMap) {
uniforms.alphaMap.value = material.alphaMap;
WebGLMaterials.refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
}
if (material.alphaTest > 0) {
uniforms.alphaTest.value = material.alphaTest;
}
}

public static function refreshUniformsSprites(uniforms:Uniforms, material:Material):Void {
uniforms.diffuse.value.copy(material.color);
uniforms.opacity.value = material.opacity;
uniforms.rotation.value = material.rotation;
if (material.map) {
uniforms.map.value = material.map;
WebGLMaterials.refreshTransformUniform(material.map, uniforms.mapTransform);
}
if (material.alphaMap) {
uniforms.alphaMap.value = material.alphaMap;
WebGLMaterials.refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
}
if (material.alphaTest > 0) {
uniforms.alphaTest.value = material.alphaTest;
}
}

public static function refreshUniformsPhong(uniforms:Uniforms, material:Material):Void {
uniforms.specular.value.copy(material.specular);
uniforms.shininess.value = Math.max(material.shininess, 1e-4); // to prevent pow(0.0, 0.0)
}

public static function refreshUniformsToon(uniforms:Uniforms, material:Material):Void {
if (material.gradientMap) {
uniforms.gradientMap.value = material.gradientMap;
}
}

public static function refreshUniformsStandard(uniforms:Uniforms, material:Material):Void {
uniforms.metalness.value = material.metalness;
if (material.metalnessMap) {
uniforms.metalnessMap.value = material.metalnessMap;
WebGLMaterials.refreshTransformUniform(material.metalnessMap, uniforms.metalnessMapTransform);
}
uniforms.roughness.value = material.roughness;
if (material.roughnessMap) {
uniforms.roughnessMap.value = material.roughnessMap;
WebGLMaterials.refreshTransformUniform(material.roughnessMap, uniforms.roughnessMapTransform);
}
if (material.envMap) {
//uniforms.envMap.value = material.envMap; // part of uniforms common
uniforms.envMapIntensity.value = material.envMapIntensity;
}
}

public static function refreshUniformsPhysical(uniforms:Uniforms, material:Material, transmissionRenderTarget:RenderTarget):Void {
uniforms.ior.value = material.ior; // also part of uniforms common
if (material.sheen > 0) {
uniforms.sheenColor.value.copy(material.sheenColor).multiplyScalar(material.sheen);
uniforms.sheenRoughness.value = material.sheenRoughness;
if (material.sheenColorMap) {
uniforms.sheenColorMap.value = material.sheenColorMap;
WebGLMaterials.refreshTransformUniform(material.sheenColorMap, uniforms.sheenColorMapTransform);
}
if (material.sheenRoughnessMap) {
uniforms.sheenRoughnessMap.value = material.sheenRoughnessMap;
WebGLMaterials.refreshTransformUniform(material.sheenRoughnessMap, uniforms.sheenRoughnessMapTransform);
}
}
if (material.clearcoat > 0) {
uniforms.clearcoat.value = material.clearcoat;
uniforms.clearcoatRoughness.value = material.clearcoatRoughness;
if (material.clearcoatMap) {
uniforms.clearcoatMap.value = material.clearcoatMap;
WebGLMaterials.refreshTransformUniform(material.clearcoatMap, uniforms.clearcoatMapTransform);
}
if (material.clearcoatRoughnessMap) {
uniforms.clearcoatRoughnessMap.value = material.clearcoatRoughnessMap;
WebGLMaterials.refreshTransformUniform(material.clearcoatRoughnessMap, uniforms.clearcoatRoughnessMapTransform);
}
if (material.clearcoatNormalMap) {
uniforms.clearcoatNormalMap.value = material.clearcoatNormalMap;
WebGLMaterials.refreshTransformUniform(material.clearcoatNormalMap, uniforms.clearcoatNormalMapTransform);
uniforms.clearcoatNormalScale.value.copy(material.clearcoatNormalScale);
if (material.side === BackSide) {
uniforms.clearcoatNormalScale.value.negate();
}
}
}
if (material.dispersion > 0) {
uniforms.dispersion.value = material.dispersion;
}
if (material.iridescence > 0) {
uniforms.iridescence.value = material.iridescence;
uniforms.iridescenceIOR.value = material.iridescenceIOR;
uniforms.iridescenceThicknessMinimum.value = material.iridescenceThicknessRange[0];
uniforms.iridescenceThicknessMaximum.value = material.iridescenceThicknessRange[1];
if (material.iridescenceMap) {
uniforms.iridescenceMap.value = material.iridescenceMap;
WebGLMaterials.refreshTransformUniform(material.iridescenceMap, uniforms.iridescenceMapTransform);
}
if (material.iridescenceThicknessMap) {
uniforms.iridescenceThicknessMap.value = material.iridescenceThicknessMap;
WebGLMaterials.refreshTransformUniform(material.iridescenceThicknessMap, uniforms.iridescenceThicknessMapTransform);
}
}
if (material.transmission > 0) {
uniforms.transmission.value = material.transmission;
uniforms.transmissionSamplerMap.value = transmissionRenderTarget.texture;
uniforms.transmissionSamplerSize.value.set(transmissionRenderTarget.width, transmissionRenderTarget.height);
if (material.transmissionMap) {
uniforms.transmissionMap.value = material.transmissionMap;
WebGLMaterials.refreshTransformUniform(material.transmissionMap, uniforms.transmissionMapTransform);
}
uniforms.thickness.value = material.thickness;
if (material.thicknessMap) {
uniforms.thicknessMap.value = material.thicknessMap;
WebGLMaterials.refreshTransformUniform(material.thicknessMap, uniforms.thicknessMapTransform);
}
uniforms.attenuationDistance.value = material.attenuationDistance;
uniforms.attenuationColor.value.copy(material.attenuationColor);
}
if (material.anisotropy > 0) {
uniforms.anisotropyVector.value.set(material.anisotropy * Math.cos(material.anisotropyRotation), material.anisotropy * Math.sin(material.anisotropyRotation));
if (material.anisotropyMap) {
uniforms.anisotropyMap.value = material.anisotropyMap;
WebGLMaterials.refreshTransformUniform(material.anisotropyMap, uniforms.anisotropyMapTransform);
}
}
uniforms.specularIntensity.value = material.specularIntensity;
uniforms.specularColor.value.copy(material.specularColor);
if (material.specularColorMap) {
uniforms.specularColorMap.value = material.specularColorMap;
WebGLMaterials.refreshTransformUniform(material.specularColorMap, uniforms.specularColorMapTransform);
}
if (material.specularIntensityMap) {
uniforms.specularIntensityMap.value = material.specularIntensityMap;
WebGLMaterials.refreshTransformUniform(material.specularIntensityMap, uniforms.specularIntensityMapTransform);
}
}

public static function refreshUniformsMatcap(uniforms:Uniforms, material:Material):Void {
if (material.matcap) {
uniforms.matcap.value = material.matcap;
}
}

public static function refreshUniformsDistance(uniforms:Uniforms, material:Material):Void {
const light = properties.get(material).light;
uniforms.referencePosition.value.setFromMatrixPosition(light.matrixWorld);
uniforms.nearDistance.value = light.shadow.camera.near;
uniforms.farDistance.value = light.shadow.camera.far;
}

}