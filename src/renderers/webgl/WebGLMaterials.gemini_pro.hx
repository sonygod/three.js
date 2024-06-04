import haxe.ds.StringMap;
import three.constants.BackSide;
import three.math.Euler;
import three.math.Matrix4;
import three.renderers.WebGLRenderer;
import three.materials.MeshBasicMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshToonMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshStandardMaterial;
import three.materials.MeshPhysicalMaterial;
import three.materials.MeshMatcapMaterial;
import three.materials.MeshDepthMaterial;
import three.materials.MeshDistanceMaterial;
import three.materials.MeshNormalMaterial;
import three.materials.LineBasicMaterial;
import three.materials.LineDashedMaterial;
import three.materials.PointsMaterial;
import three.materials.SpriteMaterial;
import three.materials.ShadowMaterial;
import three.materials.ShaderMaterial;
import three.materials.Material;
import three.textures.Texture;
import three.scenes.Fog;
import three.scenes.FogExp2;
import three.lights.Light;

class WebGLMaterials {

	public static function new(renderer:WebGLRenderer, properties:StringMap<Dynamic>):WebGLMaterials {
		return new WebGLMaterials(renderer, properties);
	}

	private var _e1:Euler = new Euler();
	private var _m1:Matrix4 = new Matrix4();

	public function refreshTransformUniform(map:Texture, uniform:Dynamic) {
		if (map.matrixAutoUpdate) map.updateMatrix();
		uniform.value = map.matrix.clone();
	}

	public function refreshFogUniforms(uniforms:Dynamic, fog:Fog | FogExp2) {
		var colorSpace = getUnlitUniformColorSpace(renderer);
		uniforms.fogColor.value = fog.color.getRGB(colorSpace);

		if (cast fog.isFog) {
			uniforms.fogNear.value = fog.near;
			uniforms.fogFar.value = fog.far;
		} else if (cast fog.isFogExp2) {
			uniforms.fogDensity.value = fog.density;
		}
	}

	public function refreshMaterialUniforms(uniforms:Dynamic, material:Material, pixelRatio:Float, height:Float, transmissionRenderTarget:Dynamic) {
		if (cast material.isMeshBasicMaterial) {
			refreshUniformsCommon(uniforms, material);
		} else if (cast material.isMeshLambertMaterial) {
			refreshUniformsCommon(uniforms, material);
		} else if (cast material.isMeshToonMaterial) {
			refreshUniformsCommon(uniforms, material);
			refreshUniformsToon(uniforms, material);
		} else if (cast material.isMeshPhongMaterial) {
			refreshUniformsCommon(uniforms, material);
			refreshUniformsPhong(uniforms, material);
		} else if (cast material.isMeshStandardMaterial) {
			refreshUniformsCommon(uniforms, material);
			refreshUniformsStandard(uniforms, material);

			if (cast material.isMeshPhysicalMaterial) {
				refreshUniformsPhysical(uniforms, material, transmissionRenderTarget);
			}
		} else if (cast material.isMeshMatcapMaterial) {
			refreshUniformsCommon(uniforms, material);
			refreshUniformsMatcap(uniforms, material);
		} else if (cast material.isMeshDepthMaterial) {
			refreshUniformsCommon(uniforms, material);
		} else if (cast material.isMeshDistanceMaterial) {
			refreshUniformsCommon(uniforms, material);
			refreshUniformsDistance(uniforms, material);
		} else if (cast material.isMeshNormalMaterial) {
			refreshUniformsCommon(uniforms, material);
		} else if (cast material.isLineBasicMaterial) {
			refreshUniformsLine(uniforms, material);

			if (cast material.isLineDashedMaterial) {
				refreshUniformsDash(uniforms, material);
			}
		} else if (cast material.isPointsMaterial) {
			refreshUniformsPoints(uniforms, material, pixelRatio, height);
		} else if (cast material.isSpriteMaterial) {
			refreshUniformsSprites(uniforms, material);
		} else if (cast material.isShadowMaterial) {
			uniforms.color.value = material.color.clone();
			uniforms.opacity.value = material.opacity;
		} else if (cast material.isShaderMaterial) {
			// #15581
			material.uniformsNeedUpdate = false;
		}
	}

	public function refreshUniformsCommon(uniforms:Dynamic, material:Material) {
		uniforms.opacity.value = material.opacity;

		if (material.color != null) {
			uniforms.diffuse.value = material.color.clone();
		}

		if (material.emissive != null) {
			uniforms.emissive.value = material.emissive.clone().multiplyScalar(material.emissiveIntensity);
		}

		if (material.map != null) {
			uniforms.map.value = material.map;
			refreshTransformUniform(material.map, uniforms.mapTransform);
		}

		if (material.alphaMap != null) {
			uniforms.alphaMap.value = material.alphaMap;
			refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
		}

		if (material.bumpMap != null) {
			uniforms.bumpMap.value = material.bumpMap;
			refreshTransformUniform(material.bumpMap, uniforms.bumpMapTransform);
			uniforms.bumpScale.value = material.bumpScale;

			if (material.side == BackSide) {
				uniforms.bumpScale.value *= -1;
			}
		}

		if (material.normalMap != null) {
			uniforms.normalMap.value = material.normalMap;
			refreshTransformUniform(material.normalMap, uniforms.normalMapTransform);
			uniforms.normalScale.value = material.normalScale.clone();

			if (material.side == BackSide) {
				uniforms.normalScale.value.negate();
			}
		}

		if (material.displacementMap != null) {
			uniforms.displacementMap.value = material.displacementMap;
			refreshTransformUniform(material.displacementMap, uniforms.displacementMapTransform);
			uniforms.displacementScale.value = material.displacementScale;
			uniforms.displacementBias.value = material.displacementBias;
		}

		if (material.emissiveMap != null) {
			uniforms.emissiveMap.value = material.emissiveMap;
			refreshTransformUniform(material.emissiveMap, uniforms.emissiveMapTransform);
		}

		if (material.specularMap != null) {
			uniforms.specularMap.value = material.specularMap;
			refreshTransformUniform(material.specularMap, uniforms.specularMapTransform);
		}

		if (material.alphaTest > 0) {
			uniforms.alphaTest.value = material.alphaTest;
		}

		var materialProperties = properties.get(material);
		var envMap = materialProperties.envMap;
		var envMapRotation = materialProperties.envMapRotation;

		if (envMap != null) {
			uniforms.envMap.value = envMap;
			_e1.copy(envMapRotation);
			// accommodate left-handed frame
			_e1.x *= -1;
			_e1.y *= -1;
			_e1.z *= -1;

			if (envMap.isCubeTexture && !envMap.isRenderTargetTexture) {
				// environment maps which are not cube render targets or PMREMs follow a different convention
				_e1.y *= -1;
				_e1.z *= -1;
			}

			uniforms.envMapRotation.value = _m1.makeRotationFromEuler(_e1);
			uniforms.flipEnvMap.value = (envMap.isCubeTexture && !envMap.isRenderTargetTexture) ? -1 : 1;

			uniforms.reflectivity.value = material.reflectivity;
			uniforms.ior.value = material.ior;
			uniforms.refractionRatio.value = material.refractionRatio;
		}

		if (material.lightMap != null) {
			uniforms.lightMap.value = material.lightMap;

			// artist-friendly light intensity scaling factor
			var scaleFactor = (renderer._useLegacyLights) ? Math.PI : 1;
			uniforms.lightMapIntensity.value = material.lightMapIntensity * scaleFactor;

			refreshTransformUniform(material.lightMap, uniforms.lightMapTransform);
		}

		if (material.aoMap != null) {
			uniforms.aoMap.value = material.aoMap;
			uniforms.aoMapIntensity.value = material.aoMapIntensity;
			refreshTransformUniform(material.aoMap, uniforms.aoMapTransform);
		}
	}

	public function refreshUniformsLine(uniforms:Dynamic, material:Material) {
		uniforms.diffuse.value = material.color.clone();
		uniforms.opacity.value = material.opacity;

		if (material.map != null) {
			uniforms.map.value = material.map;
			refreshTransformUniform(material.map, uniforms.mapTransform);
		}
	}

	public function refreshUniformsDash(uniforms:Dynamic, material:Material) {
		uniforms.dashSize.value = material.dashSize;
		uniforms.totalSize.value = material.dashSize + material.gapSize;
		uniforms.scale.value = material.scale;
	}

	public function refreshUniformsPoints(uniforms:Dynamic, material:Material, pixelRatio:Float, height:Float) {
		uniforms.diffuse.value = material.color.clone();
		uniforms.opacity.value = material.opacity;
		uniforms.size.value = material.size * pixelRatio;
		uniforms.scale.value = height * 0.5;

		if (material.map != null) {
			uniforms.map.value = material.map;
			refreshTransformUniform(material.map, uniforms.uvTransform);
		}

		if (material.alphaMap != null) {
			uniforms.alphaMap.value = material.alphaMap;
			refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
		}

		if (material.alphaTest > 0) {
			uniforms.alphaTest.value = material.alphaTest;
		}
	}

	public function refreshUniformsSprites(uniforms:Dynamic, material:Material) {
		uniforms.diffuse.value = material.color.clone();
		uniforms.opacity.value = material.opacity;
		uniforms.rotation.value = material.rotation;

		if (material.map != null) {
			uniforms.map.value = material.map;
			refreshTransformUniform(material.map, uniforms.mapTransform);
		}

		if (material.alphaMap != null) {
			uniforms.alphaMap.value = material.alphaMap;
			refreshTransformUniform(material.alphaMap, uniforms.alphaMapTransform);
		}

		if (material.alphaTest > 0) {
			uniforms.alphaTest.value = material.alphaTest;
		}
	}

	public function refreshUniformsPhong(uniforms:Dynamic, material:Material) {
		uniforms.specular.value = material.specular.clone();
		uniforms.shininess.value = Math.max(material.shininess, 1e-4); // to prevent pow( 0.0, 0.0 )
	}

	public function refreshUniformsToon(uniforms:Dynamic, material:Material) {
		if (material.gradientMap != null) {
			uniforms.gradientMap.value = material.gradientMap;
		}
	}

	public function refreshUniformsStandard(uniforms:Dynamic, material:Material) {
		uniforms.metalness.value = material.metalness;

		if (material.metalnessMap != null) {
			uniforms.metalnessMap.value = material.metalnessMap;
			refreshTransformUniform(material.metalnessMap, uniforms.metalnessMapTransform);
		}

		uniforms.roughness.value = material.roughness;

		if (material.roughnessMap != null) {
			uniforms.roughnessMap.value = material.roughnessMap;
			refreshTransformUniform(material.roughnessMap, uniforms.roughnessMapTransform);
		}

		if (material.envMap != null) {
			//uniforms.envMap.value = material.envMap; // part of uniforms common
			uniforms.envMapIntensity.value = material.envMapIntensity;
		}
	}

	public function refreshUniformsPhysical(uniforms:Dynamic, material:Material, transmissionRenderTarget:Dynamic) {
		uniforms.ior.value = material.ior; // also part of uniforms common

		if (material.sheen > 0) {
			uniforms.sheenColor.value = material.sheenColor.clone().multiplyScalar(material.sheen);
			uniforms.sheenRoughness.value = material.sheenRoughness;

			if (material.sheenColorMap != null) {
				uniforms.sheenColorMap.value = material.sheenColorMap;
				refreshTransformUniform(material.sheenColorMap, uniforms.sheenColorMapTransform);
			}

			if (material.sheenRoughnessMap != null) {
				uniforms.sheenRoughnessMap.value = material.sheenRoughnessMap;
				refreshTransformUniform(material.sheenRoughnessMap, uniforms.sheenRoughnessMapTransform);
			}
		}

		if (material.clearcoat > 0) {
			uniforms.clearcoat.value = material.clearcoat;
			uniforms.clearcoatRoughness.value = material.clearcoatRoughness;

			if (material.clearcoatMap != null) {
				uniforms.clearcoatMap.value = material.clearcoatMap;
				refreshTransformUniform(material.clearcoatMap, uniforms.clearcoatMapTransform);
			}

			if (material.clearcoatRoughnessMap != null) {
				uniforms.clearcoatRoughnessMap.value = material.clearcoatRoughnessMap;
				refreshTransformUniform(material.clearcoatRoughnessMap, uniforms.clearcoatRoughnessMapTransform);
			}

			if (material.clearcoatNormalMap != null) {
				uniforms.clearcoatNormalMap.value = material.clearcoatNormalMap;
				refreshTransformUniform(material.clearcoatNormalMap, uniforms.clearcoatNormalMapTransform);
				uniforms.clearcoatNormalScale.value = material.clearcoatNormalScale.clone();

				if (material.side == BackSide) {
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

			if (material.iridescenceMap != null) {
				uniforms.iridescenceMap.value = material.iridescenceMap;
				refreshTransformUniform(material.iridescenceMap, uniforms.iridescenceMapTransform);
			}

			if (material.iridescenceThicknessMap != null) {
				uniforms.iridescenceThicknessMap.value = material.iridescenceThicknessMap;
				refreshTransformUniform(material.iridescenceThicknessMap, uniforms.iridescenceThicknessMapTransform);
			}
		}

		if (material.transmission > 0) {
			uniforms.transmission.value = material.transmission;
			uniforms.transmissionSamplerMap.value = transmissionRenderTarget.texture;
			uniforms.transmissionSamplerSize.value = transmissionRenderTarget.size;

			if (material.transmissionMap != null) {
				uniforms.transmissionMap.value = material.transmissionMap;
				refreshTransformUniform(material.transmissionMap, uniforms.transmissionMapTransform);
			}

			uniforms.thickness.value = material.thickness;

			if (material.thicknessMap != null) {
				uniforms.thicknessMap.value = material.thicknessMap;
				refreshTransformUniform(material.thicknessMap, uniforms.thicknessMapTransform);
			}

			uniforms.attenuationDistance.value = material.attenuationDistance;
			uniforms.attenuationColor.value = material.attenuationColor.clone();
		}

		if (material.anisotropy > 0) {
			uniforms.anisotropyVector.value = new Vector2(material.anisotropy * Math.cos(material.anisotropyRotation), material.anisotropy * Math.sin(material.anisotropyRotation));

			if (material.anisotropyMap != null) {
				uniforms.anisotropyMap.value = material.anisotropyMap;
				refreshTransformUniform(material.anisotropyMap, uniforms.anisotropyMapTransform);
			}
		}

		uniforms.specularIntensity.value = material.specularIntensity;
		uniforms.specularColor.value = material.specularColor.clone();

		if (material.specularColorMap != null) {
			uniforms.specularColorMap.value = material.specularColorMap;
			refreshTransformUniform(material.specularColorMap, uniforms.specularColorMapTransform);
		}

		if (material.specularIntensityMap != null) {
			uniforms.specularIntensityMap.value = material.specularIntensityMap;
			refreshTransformUniform(material.specularIntensityMap, uniforms.specularIntensityMapTransform);
		}
	}

	public function refreshUniformsMatcap(uniforms:Dynamic, material:Material) {
		if (material.matcap != null) {
			uniforms.matcap.value = material.matcap;
		}
	}

	public function refreshUniformsDistance(uniforms:Dynamic, material:Material) {
		var light = properties.get(material).light;
		uniforms.referencePosition.value = light.matrixWorld.getPosition();
		uniforms.nearDistance.value = light.shadow.camera.near;
		uniforms.farDistance.value = light.shadow.camera.far;
	}

	private function WebGLMaterials(renderer:WebGLRenderer, properties:StringMap<Dynamic>) {
		this.renderer = renderer;
		this.properties = properties;
	}

	private var renderer:WebGLRenderer;
	private var properties:StringMap<Dynamic>;
}

private function getUnlitUniformColorSpace(renderer:WebGLRenderer) {
	return renderer._useLegacyLights ? "srgb" : "linear";
}