package three.js.src.renderers.webgl;

import three.constants.BackSide;
import three.shaders.UniformsUtils.getUnlitUniformColorSpace;
import three.math.Euler;
import three.math.Matrix4;

class WebGLMaterials {
  static var _e1 = new Euler();
  static var _m1 = new Matrix4();

  public function new(renderer:Dynamic, properties:Dynamic) {
    // ...
  }

  function refreshTransformUniform(map:Dynamic, uniform:Dynamic) {
    if (map.matrixAutoUpdate) map.updateMatrix();
    uniform.value.copy(map.matrix);
  }

  function refreshFogUniforms(uniforms:Dynamic, fog:Dynamic) {
    fog.color.getRGB(uniforms.fogColor.value, getUnlitUniformColorSpace(renderer));
    if (fog.isFog) {
      uniforms.fogNear.value = fog.near;
      uniforms.fogFar.value = fog.far;
    } else if (fog.isFogExp2) {
      uniforms.fogDensity.value = fog.density;
    }
  }

  function refreshMaterialUniforms(uniforms:Dynamic, material:Dynamic, pixelRatio:Float, height:Float, transmissionRenderTarget:Dynamic) {
    switch (material.type) {
      case "MeshBasicMaterial":
        refreshUniformsCommon(uniforms, material);
      case "MeshLambertMaterial":
        refreshUniformsCommon(uniforms, material);
      case "MeshToonMaterial":
        refreshUniformsCommon(uniforms, material);
        refreshUniformsToon(uniforms, material);
      case "MeshPhongMaterial":
        refreshUniformsCommon(uniforms, material);
        refreshUniformsPhong(uniforms, material);
      case "MeshStandardMaterial":
        refreshUniformsCommon(uniforms, material);
        refreshUniformsStandard(uniforms, material);
        if (material.isMeshPhysicalMaterial) {
          refreshUniformsPhysical(uniforms, material, transmissionRenderTarget);
        }
      case "MeshMatcapMaterial":
        refreshUniformsCommon(uniforms, material);
        refreshUniformsMatcap(uniforms, material);
      case "MeshDepthMaterial":
        refreshUniformsCommon(uniforms, material);
      case "MeshDistanceMaterial":
        refreshUniformsCommon(uniforms, material);
        refreshUniformsDistance(uniforms, material);
      case "MeshNormalMaterial":
        refreshUniformsCommon(uniforms, material);
      case "LineBasicMaterial":
        refreshUniformsLine(uniforms, material);
        if (material.isLineDashedMaterial) {
          refreshUniformsDash(uniforms, material);
        }
      case "PointsMaterial":
        refreshUniformsPoints(uniforms, material, pixelRatio, height);
      case "SpriteMaterial":
        refreshUniformsSprites(uniforms, material);
      case "ShadowMaterial":
        uniforms.color.value.copy(material.color);
        uniforms.opacity.value = material.opacity;
      case "ShaderMaterial":
        material.uniformsNeedUpdate = false; // #15581
    }
  }

  function refreshUniformsCommon(uniforms:Dynamic, material:Dynamic) {
    uniforms.opacity.value = material.opacity;
    if (material.color) {
      uniforms.diffuse.value.copy(material.color);
    }
    if (material.emissive) {
      uniforms.emissive.value.copy(material.emissive).multiplyScalar(material.emissiveIntensity);
    }
    if (material.map) {
      uniforms.map.value = material.map;
      refreshTransformUniform(material.map, uniforms.mapTransform);
    }
    if (material.alphaMap) {
      uniforms.alphaMap.value = material.alphaMap;
      refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
    }
    if (material.bumpMap) {
      uniforms.bumpMap.value = material.bumpMap;
      refreshTransformUniform(material.bumpMap, uniforms.bumpMapTransform);
      uniforms.bumpScale.value = material.bumpScale;
      if (material.side == BackSide) {
        uniforms.bumpScale.value *= -1;
      }
    }
    if (material.normalMap) {
      uniforms.normalMap.value = material.normalMap;
      refreshTransformUniform(material.normalMap, uniforms.normalMapTransform);
      uniforms.normalScale.value.copy(material.normalScale);
      if (material.side == BackSide) {
        uniforms.normalScale.value.negate();
      }
    }
    if (material.displacementMap) {
      uniforms.displacementMap.value = material.displacementMap;
      refreshTransformUniform(material.displacementMap, uniforms.displacementMapTransform);
      uniforms.displacementScale.value = material.displacementScale;
      uniforms.displacementBias.value = material.displacementBias;
    }
    if (material.emissiveMap) {
      uniforms.emissiveMap.value = material.emissiveMap;
      refreshTransformUniform(material.emissiveMap, uniforms.emissiveMapTransform);
    }
    if (material.specularMap) {
      uniforms.specularMap.value = material.specularMap;
      refreshTransformUniform(material.specularMap, uniforms.specularMapTransform);
    }
    if (material.alphaTest > 0) {
      uniforms.alphaTest.value = material.alphaTest;
    }
    var materialProperties = properties.get(material);
    var envMap = materialProperties.envMap;
    var envMapRotation = materialProperties.envMapRotation;
    if (envMap) {
      uniforms.envMap.value = envMap;
      _e1.copy(envMapRotation);
      // accommodate left-handed frame
      _e1.x *= -1; _e1.y *= -1; _e1.z *= -1;
      if (envMap.isCubeTexture && envMap.isRenderTargetTexture === false) {
        // environment maps which are not cube render targets or PMREMs follow a different convention
        _e1.y *= -1;
        _e1.z *= -1;
      }
      uniforms.envMapRotation.value.setFromMatrix4(_m1.makeRotationFromEuler(_e1));
      uniforms.flipEnvMap.value = (envMap.isCubeTexture && envMap.isRenderTargetTexture === false) ? -1 : 1;
      uniforms.reflectivity.value = material.reflectivity;
      uniforms.ior.value = material.ior;
      uniforms.refractionRatio.value = material.refractionRatio;
    }
    if (material.lightMap) {
      uniforms.lightMap.value = material.lightMap;
      // artist-friendly light intensity scaling factor
      var scaleFactor = (renderer._useLegacyLights === true) ? Math.PI : 1;
      uniforms.lightMapIntensity.value = material.lightMapIntensity * scaleFactor;
      refreshTransformUniform(material.lightMap, uniforms.lightMapTransform);
    }
    if (material.aoMap) {
      uniforms.aoMap.value = material.aoMap;
      uniforms.aoMapIntensity.value = material.aoMapIntensity;
      refreshTransformUniform(material.aoMap, uniforms.aoMapTransform);
    }
  }

  function refreshUniformsLine(uniforms:Dynamic, material:Dynamic) {
    uniforms.diffuse.value.copy(material.color);
    uniforms.opacity.value = material.opacity;
    if (material.map) {
      uniforms.map.value = material.map;
      refreshTransformUniform(material.map, uniforms.mapTransform);
    }
  }

  function refreshUniformsDash(uniforms:Dynamic, material:Dynamic) {
    uniforms.dashSize.value = material.dashSize;
    uniforms.totalSize.value = material.dashSize + material.gapSize;
    uniforms.scale.value = material.scale;
  }

  function refreshUniformsPoints(uniforms:Dynamic, material:Dynamic, pixelRatio:Float, height:Float) {
    uniforms.diffuse.value.copy(material.color);
    uniforms.opacity.value = material.opacity;
    uniforms.size.value = material.size * pixelRatio;
    uniforms.scale.value = height * 0.5;
    if (material.map) {
      uniforms.map.value = material.map;
      refreshTransformUniform(material.map, uniforms.uvTransform);
    }
    if (material.alphaMap) {
      uniforms.alphaMap.value = material.alphaMap;
      refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
    }
    if (material.alphaTest > 0) {
      uniforms.alphaTest.value = material.alphaTest;
    }
  }

  function refreshUniformsSprites(uniforms:Dynamic, material:Dynamic) {
    uniforms.diffuse.value.copy(material.color);
    uniforms.opacity.value = material.opacity;
    uniforms.rotation.value = material.rotation;
    if (material.map) {
      uniforms.map.value = material.map;
      refreshTransformUniform(material.map, uniforms.mapTransform);
    }
    if (material.alphaMap) {
      uniforms.alphaMap.value = material.alphaMap;
      refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
    }
    if (material.alphaTest > 0) {
      uniforms.alphaTest.value = material.alphaTest;
    }
  }

  function refreshUniformsPhong(uniforms:Dynamic, material:Dynamic) {
    uniforms.specular.value.copy(material.specular);
    uniforms.shininess.value = Math.max(material.shininess, 1e-4); // to prevent pow( 0.0, 0.0 )
  }

  function refreshUniformsToon(uniforms:Dynamic, material:Dynamic) {
    if (material.gradientMap) {
      uniforms.gradientMap.value = material.gradientMap;
    }
  }

  function refreshUniformsStandard(uniforms:Dynamic, material:Dynamic) {
    uniforms.metalness.value = material.metalness;
    if (material.metalnessMap) {
      uniforms.metalnessMap.value = material.metalnessMap;
      refreshTransformUniform(material.metalnessMap, uniforms.metalnessMapTransform);
    }
    uniforms.roughness.value = material.roughness;
    if (material.roughnessMap) {
      uniforms.roughnessMap.value = material.roughnessMap;
      refreshTransformUniform(material.roughnessMap, uniforms.roughnessMapTransform);
    }
    if (material.envMap) {
      // part of uniforms common
      uniforms.envMapIntensity.value = material.envMapIntensity;
    }
  }

  function refreshUniformsPhysical(uniforms:Dynamic, material:Dynamic, transmissionRenderTarget:Dynamic) {
    uniforms.ior.value = material.ior; // also part of uniforms common
    if (material.sheen > 0) {
      uniforms.sheenColor.value.copy(material.sheenColor).multiplyScalar(material.sheen);
      uniforms.sheenRoughness.value = material.sheenRoughness;
      if (material.sheenColorMap) {
        uniforms.sheenColorMap.value = material.sheenColorMap;
        refreshTransformUniform(material.sheenColorMap, uniforms.sheenColorMapTransform);
      }
      if (material.sheenRoughnessMap) {
        uniforms.sheenRoughnessMap.value = material.sheenRoughnessMap;
        refreshTransformUniform(material.sheenRoughnessMap, uniforms.sheenRoughnessMapTransform);
      }
    }
    if (material.clearcoat > 0) {
      uniforms.clearcoat.value = material.clearcoat;
      uniforms.clearcoatRoughness.value = material.clearcoatRoughness;
      if (material.clearcoatMap) {
        uniforms.clearcoatMap.value = material.clearcoatMap;
        refreshTransformUniform(material.clearcoatMap, uniforms.clearcoatMapTransform);
      }
      if (material.clearcoatRoughnessMap) {
        uniforms.clearcoatRoughnessMap.value = material.clearcoatRoughnessMap;
        refreshTransformUniform(material.clearcoatRoughnessMap, uniforms.clearcoatRoughnessMapTransform);
      }
      if (material.clearcoatNormalMap) {
        uniforms.clearcoatNormalMap.value = material.clearcoatNormalMap;
        refreshTransformUniform(material.clearcoatNormalMap, uniforms.clearcoatNormalMapTransform);
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
        refreshTransformUniform(material.iridescenceMap, uniforms.iridescenceMapTransform);
      }
      if (material.iridescenceThicknessMap) {
        uniforms.iridescenceThicknessMap.value = material.iridescenceThicknessMap;
        refreshTransformUniform(material.iridescenceThicknessMap, uniforms.iridescenceThicknessMapTransform);
      }
    }
    if (material.transmission > 0) {
      uniforms.transmission.value = material.transmission;
      uniforms.transmissionSamplerMap.value = transmissionRenderTarget.texture;
      uniforms.transmissionSamplerSize.value.set(transmissionRenderTarget.width, transmissionRenderTarget.height);
      if (material.transmissionMap) {
        uniforms.transmissionMap.value = material.transmissionMap;
        refreshTransformUniform(material.transmissionMap, uniforms.transmissionMapTransform);
      }
      uniforms.thickness.value = material.thickness;
      if (material.thicknessMap) {
        uniforms.thicknessMap.value = material.thicknessMap;
        refreshTransformUniform(material.thicknessMap, uniforms.thicknessMapTransform);
      }
      uniforms.attenuationDistance.value = material.attenuationDistance;
      uniforms.attenuationColor.value.copy(material.attenuationColor);
    }
    if (material.anisotropy > 0) {
      uniforms.anisotropyVector.value.set(material.anisotropy * Math.cos(material.anisotropyRotation), material.anisotropy * Math.sin(material.anisotropyRotation));
      if (material.anisotropyMap) {
        uniforms.anisotropyMap.value = material.anisotropyMap;
        refreshTransformUniform(material.anisotropyMap, uniforms.anisotropyMapTransform);
      }
    }
    uniforms.specularIntensity.value = material.specularIntensity;
    uniforms.specularColor.value.copy(material.specularColor);
    if (material.specularColorMap) {
      uniforms.specularColorMap.value = material.specularColorMap;
      refreshTransformUniform(material.specularColorMap, uniforms.specularColorMapTransform);
    }
    if (material.specularIntensityMap) {
      uniforms.specularIntensityMap.value = material.specularIntensityMap;
      refreshTransformUniform(material.specularIntensityMap, uniforms.specularIntensityMapTransform);
    }
  }

  function refreshUniformsMatcap(uniforms:Dynamic, material:Dynamic) {
    if (material.matcap) {
      uniforms.matcap.value = material.matcap;
    }
  }

  function refreshUniformsDistance(uniforms:Dynamic, material:Dynamic) {
    var light = properties.get(material).light;
    uniforms.referencePosition.value.setFromMatrixPosition(light.matrixWorld);
    uniforms.nearDistance.value = light.shadow.camera.near;
    uniforms.farDistance.value = light.shadow.camera.far;
  }

  public function getUniforms():Dynamic {
    return {
      refreshFogUniforms: refreshFogUniforms,
      refreshMaterialUniforms: refreshMaterialUniforms
    };
  }
}