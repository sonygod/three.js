import haxe.ds.StringMap;
import three.constants.BackSide;
import three.math.Euler;
import three.math.Matrix4;
import three.renderers.shaders.UniformsUtils;
import three.materials.MeshBasicMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshToonMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshStandardMaterial;
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
import three.materials.MeshPhysicalMaterial;

class WebGLMaterials {

	private var renderer:three.renderers.WebGLRenderer;
	private var properties:StringMap<Dynamic>;

	public function new(renderer:three.renderers.WebGLRenderer, properties:StringMap<Dynamic>) {
		this.renderer = renderer;
		this.properties = properties;
	}

	public function refreshTransformUniform(map:Dynamic, uniform:Dynamic) {
		if (Reflect.getProperty(map, "matrixAutoUpdate") == true) {
			Reflect.callMethod(map, "updateMatrix", []);
		}
		Reflect.setProperty(uniform, "value", Reflect.callMethod(uniform.value, "copy", [Reflect.getProperty(map, "matrix")]));
	}

	public function refreshFogUniforms(uniforms:Dynamic, fog:Dynamic) {
		Reflect.callMethod(fog.color, "getRGB", [Reflect.getProperty(uniforms, "fogColor").value, UniformsUtils.getUnlitUniformColorSpace(renderer)]);

		if (Reflect.isInstanceOf(fog, three.scenes.Fog)) {
			Reflect.setProperty(uniforms, "fogNear", {value: Reflect.getProperty(fog, "near")});
			Reflect.setProperty(uniforms, "fogFar", {value: Reflect.getProperty(fog, "far")});
		} else if (Reflect.isInstanceOf(fog, three.scenes.FogExp2)) {
			Reflect.setProperty(uniforms, "fogDensity", {value: Reflect.getProperty(fog, "density")});
		}
	}

	public function refreshMaterialUniforms(uniforms:Dynamic, material:Dynamic, pixelRatio:Float, height:Float, transmissionRenderTarget:Dynamic) {

		if (Reflect.isInstanceOf(material, MeshBasicMaterial)) {
			refreshUniformsCommon(uniforms, material);

		} else if (Reflect.isInstanceOf(material, MeshLambertMaterial)) {
			refreshUniformsCommon(uniforms, material);

		} else if (Reflect.isInstanceOf(material, MeshToonMaterial)) {
			refreshUniformsCommon(uniforms, material);
			refreshUniformsToon(uniforms, material);

		} else if (Reflect.isInstanceOf(material, MeshPhongMaterial)) {
			refreshUniformsCommon(uniforms, material);
			refreshUniformsPhong(uniforms, material);

		} else if (Reflect.isInstanceOf(material, MeshStandardMaterial)) {
			refreshUniformsCommon(uniforms, material);
			refreshUniformsStandard(uniforms, material);

			if (Reflect.isInstanceOf(material, MeshPhysicalMaterial)) {
				refreshUniformsPhysical(uniforms, material, transmissionRenderTarget);
			}

		} else if (Reflect.isInstanceOf(material, MeshMatcapMaterial)) {
			refreshUniformsCommon(uniforms, material);
			refreshUniformsMatcap(uniforms, material);

		} else if (Reflect.isInstanceOf(material, MeshDepthMaterial)) {
			refreshUniformsCommon(uniforms, material);

		} else if (Reflect.isInstanceOf(material, MeshDistanceMaterial)) {
			refreshUniformsCommon(uniforms, material);
			refreshUniformsDistance(uniforms, material);

		} else if (Reflect.isInstanceOf(material, MeshNormalMaterial)) {
			refreshUniformsCommon(uniforms, material);

		} else if (Reflect.isInstanceOf(material, LineBasicMaterial)) {
			refreshUniformsLine(uniforms, material);

			if (Reflect.isInstanceOf(material, LineDashedMaterial)) {
				refreshUniformsDash(uniforms, material);
			}

		} else if (Reflect.isInstanceOf(material, PointsMaterial)) {
			refreshUniformsPoints(uniforms, material, pixelRatio, height);

		} else if (Reflect.isInstanceOf(material, SpriteMaterial)) {
			refreshUniformsSprites(uniforms, material);

		} else if (Reflect.isInstanceOf(material, ShadowMaterial)) {
			Reflect.setProperty(uniforms, "color", {value: Reflect.callMethod(Reflect.getProperty(material, "color"), "copy", [])});
			Reflect.setProperty(uniforms, "opacity", {value: Reflect.getProperty(material, "opacity")});

		} else if (Reflect.isInstanceOf(material, ShaderMaterial)) {
			Reflect.setProperty(material, "uniformsNeedUpdate", false); // #15581
		}
	}

	public function refreshUniformsCommon(uniforms:Dynamic, material:Dynamic) {
		Reflect.setProperty(uniforms, "opacity", {value: Reflect.getProperty(material, "opacity")});

		if (Reflect.hasField(material, "color")) {
			Reflect.setProperty(uniforms, "diffuse", {value: Reflect.callMethod(Reflect.getProperty(uniforms, "diffuse").value, "copy", [Reflect.getProperty(material, "color")])});
		}

		if (Reflect.hasField(material, "emissive")) {
			Reflect.setProperty(uniforms, "emissive", {value: Reflect.callMethod(Reflect.getProperty(material, "emissive").value, "copy", [Reflect.getProperty(material, "emissive")]).multiplyScalar(Reflect.getProperty(material, "emissiveIntensity"))});
		}

		if (Reflect.hasField(material, "map")) {
			Reflect.setProperty(uniforms, "map", {value: Reflect.getProperty(material, "map")});
			refreshTransformUniform(Reflect.getProperty(material, "map"), Reflect.getProperty(uniforms, "mapTransform"));
		}

		if (Reflect.hasField(material, "alphaMap")) {
			Reflect.setProperty(uniforms, "alphaMap", {value: Reflect.getProperty(material, "alphaMap")});
			refreshTransformUniform(Reflect.getProperty(material, "alphaMap"), Reflect.getProperty(uniforms, "alphaMapTransform"));
		}

		if (Reflect.hasField(material, "bumpMap")) {
			Reflect.setProperty(uniforms, "bumpMap", {value: Reflect.getProperty(material, "bumpMap")});
			refreshTransformUniform(Reflect.getProperty(material, "bumpMap"), Reflect.getProperty(uniforms, "bumpMapTransform"));
			Reflect.setProperty(uniforms, "bumpScale", {value: Reflect.getProperty(material, "bumpScale")});

			if (Reflect.getProperty(material, "side") == BackSide) {
				Reflect.setProperty(uniforms, "bumpScale", {value: Reflect.getProperty(uniforms, "bumpScale").value * -1});
			}
		}

		if (Reflect.hasField(material, "normalMap")) {
			Reflect.setProperty(uniforms, "normalMap", {value: Reflect.getProperty(material, "normalMap")});
			refreshTransformUniform(Reflect.getProperty(material, "normalMap"), Reflect.getProperty(uniforms, "normalMapTransform"));
			Reflect.setProperty(uniforms, "normalScale", {value: Reflect.callMethod(Reflect.getProperty(material, "normalScale"), "copy", [])});

			if (Reflect.getProperty(material, "side") == BackSide) {
				Reflect.callMethod(Reflect.getProperty(uniforms, "normalScale").value, "negate", []);
			}
		}

		if (Reflect.hasField(material, "displacementMap")) {
			Reflect.setProperty(uniforms, "displacementMap", {value: Reflect.getProperty(material, "displacementMap")});
			refreshTransformUniform(Reflect.getProperty(material, "displacementMap"), Reflect.getProperty(uniforms, "displacementMapTransform"));
			Reflect.setProperty(uniforms, "displacementScale", {value: Reflect.getProperty(material, "displacementScale")});
			Reflect.setProperty(uniforms, "displacementBias", {value: Reflect.getProperty(material, "displacementBias")});
		}

		if (Reflect.hasField(material, "emissiveMap")) {
			Reflect.setProperty(uniforms, "emissiveMap", {value: Reflect.getProperty(material, "emissiveMap")});
			refreshTransformUniform(Reflect.getProperty(material, "emissiveMap"), Reflect.getProperty(uniforms, "emissiveMapTransform"));
		}

		if (Reflect.hasField(material, "specularMap")) {
			Reflect.setProperty(uniforms, "specularMap", {value: Reflect.getProperty(material, "specularMap")});
			refreshTransformUniform(Reflect.getProperty(material, "specularMap"), Reflect.getProperty(uniforms, "specularMapTransform"));
		}

		if (Reflect.getProperty(material, "alphaTest") > 0) {
			Reflect.setProperty(uniforms, "alphaTest", {value: Reflect.getProperty(material, "alphaTest")});
		}

		var materialProperties:Dynamic = this.properties.get(material);
		var envMap:Dynamic = Reflect.getProperty(materialProperties, "envMap");
		var envMapRotation:Dynamic = Reflect.getProperty(materialProperties, "envMapRotation");

		if (envMap != null) {
			Reflect.setProperty(uniforms, "envMap", {value: envMap});

			var _e1:Euler = new Euler();
			_e1.copy(envMapRotation);

			// accommodate left-handed frame
			_e1.x *= -1; _e1.y *= -1; _e1.z *= -1;

			if (Reflect.isInstanceOf(envMap, three.textures.CubeTexture) && Reflect.getProperty(envMap, "isRenderTargetTexture") == false) {

				// environment maps which are not cube render targets or PMREMs follow a different convention
				_e1.y *= -1;
				_e1.z *= -1;
			}

			var _m1:Matrix4 = new Matrix4();
			Reflect.setProperty(uniforms, "envMapRotation", {value: _m1.makeRotationFromEuler(_e1)});
			Reflect.setProperty(uniforms, "flipEnvMap", {value: (Reflect.isInstanceOf(envMap, three.textures.CubeTexture) && Reflect.getProperty(envMap, "isRenderTargetTexture") == false) ? -1 : 1});
			Reflect.setProperty(uniforms, "reflectivity", {value: Reflect.getProperty(material, "reflectivity")});
			Reflect.setProperty(uniforms, "ior", {value: Reflect.getProperty(material, "ior")});
			Reflect.setProperty(uniforms, "refractionRatio", {value: Reflect.getProperty(material, "refractionRatio")});
		}

		if (Reflect.hasField(material, "lightMap")) {
			Reflect.setProperty(uniforms, "lightMap", {value: Reflect.getProperty(material, "lightMap")});
			// artist-friendly light intensity scaling factor
			var scaleFactor:Float = (Reflect.getProperty(this.renderer, "_useLegacyLights") == true) ? Math.PI : 1;
			Reflect.setProperty(uniforms, "lightMapIntensity", {value: Reflect.getProperty(material, "lightMapIntensity") * scaleFactor});
			refreshTransformUniform(Reflect.getProperty(material, "lightMap"), Reflect.getProperty(uniforms, "lightMapTransform"));
		}

		if (Reflect.hasField(material, "aoMap")) {
			Reflect.setProperty(uniforms, "aoMap", {value: Reflect.getProperty(material, "aoMap")});
			Reflect.setProperty(uniforms, "aoMapIntensity", {value: Reflect.getProperty(material, "aoMapIntensity")});
			refreshTransformUniform(Reflect.getProperty(material, "aoMap"), Reflect.getProperty(uniforms, "aoMapTransform"));
		}
	}

	public function refreshUniformsLine(uniforms:Dynamic, material:Dynamic) {
		Reflect.setProperty(uniforms, "diffuse", {value: Reflect.callMethod(Reflect.getProperty(uniforms, "diffuse").value, "copy", [Reflect.getProperty(material, "color")])});
		Reflect.setProperty(uniforms, "opacity", {value: Reflect.getProperty(material, "opacity")});

		if (Reflect.hasField(material, "map")) {
			Reflect.setProperty(uniforms, "map", {value: Reflect.getProperty(material, "map")});
			refreshTransformUniform(Reflect.getProperty(material, "map"), Reflect.getProperty(uniforms, "mapTransform"));
		}
	}

	public function refreshUniformsDash(uniforms:Dynamic, material:Dynamic) {
		Reflect.setProperty(uniforms, "dashSize", {value: Reflect.getProperty(material, "dashSize")});
		Reflect.setProperty(uniforms, "totalSize", {value: Reflect.getProperty(material, "dashSize") + Reflect.getProperty(material, "gapSize")});
		Reflect.setProperty(uniforms, "scale", {value: Reflect.getProperty(material, "scale")});
	}

	public function refreshUniformsPoints(uniforms:Dynamic, material:Dynamic, pixelRatio:Float, height:Float) {
		Reflect.setProperty(uniforms, "diffuse", {value: Reflect.callMethod(Reflect.getProperty(uniforms, "diffuse").value, "copy", [Reflect.getProperty(material, "color")])});
		Reflect.setProperty(uniforms, "opacity", {value: Reflect.getProperty(material, "opacity")});
		Reflect.setProperty(uniforms, "size", {value: Reflect.getProperty(material, "size") * pixelRatio});
		Reflect.setProperty(uniforms, "scale", {value: height * 0.5});

		if (Reflect.hasField(material, "map")) {
			Reflect.setProperty(uniforms, "map", {value: Reflect.getProperty(material, "map")});
			refreshTransformUniform(Reflect.getProperty(material, "map"), Reflect.getProperty(uniforms, "uvTransform"));
		}

		if (Reflect.hasField(material, "alphaMap")) {
			Reflect.setProperty(uniforms, "alphaMap", {value: Reflect.getProperty(material, "alphaMap")});
			refreshTransformUniform(Reflect.getProperty(material, "alphaMap"), Reflect.getProperty(uniforms, "alphaMapTransform"));
		}

		if (Reflect.getProperty(material, "alphaTest") > 0) {
			Reflect.setProperty(uniforms, "alphaTest", {value: Reflect.getProperty(material, "alphaTest")});
		}
	}

	public function refreshUniformsSprites(uniforms:Dynamic, material:Dynamic) {
		Reflect.setProperty(uniforms, "diffuse", {value: Reflect.callMethod(Reflect.getProperty(uniforms, "diffuse").value, "copy", [Reflect.getProperty(material, "color")])});
		Reflect.setProperty(uniforms, "opacity", {value: Reflect.getProperty(material, "opacity")});
		Reflect.setProperty(uniforms, "rotation", {value: Reflect.getProperty(material, "rotation")});

		if (Reflect.hasField(material, "map")) {
			Reflect.setProperty(uniforms, "map", {value: Reflect.getProperty(material, "map")});
			refreshTransformUniform(Reflect.getProperty(material, "map"), Reflect.getProperty(uniforms, "mapTransform"));
		}

		if (Reflect.hasField(material, "alphaMap")) {
			Reflect.setProperty(uniforms, "alphaMap", {value: Reflect.getProperty(material, "alphaMap")});
			refreshTransformUniform(Reflect.getProperty(material, "alphaMap"), Reflect.getProperty(uniforms, "alphaMapTransform"));
		}

		if (Reflect.getProperty(material, "alphaTest") > 0) {
			Reflect.setProperty(uniforms, "alphaTest", {value: Reflect.getProperty(material, "alphaTest")});
		}
	}

	public function refreshUniformsPhong(uniforms:Dynamic, material:Dynamic) {
		Reflect.setProperty(uniforms, "specular", {value: Reflect.callMethod(Reflect.getProperty(uniforms, "specular").value, "copy", [Reflect.getProperty(material, "specular")])});
		Reflect.setProperty(uniforms, "shininess", {value: Math.max(Reflect.getProperty(material, "shininess"), 1e-4)}); // to prevent pow( 0.0, 0.0 )
	}

	public function refreshUniformsToon(uniforms:Dynamic, material:Dynamic) {
		if (Reflect.hasField(material, "gradientMap")) {
			Reflect.setProperty(uniforms, "gradientMap", {value: Reflect.getProperty(material, "gradientMap")});
		}
	}

	public function refreshUniformsStandard(uniforms:Dynamic, material:Dynamic) {
		Reflect.setProperty(uniforms, "metalness", {value: Reflect.getProperty(material, "metalness")});

		if (Reflect.hasField(material, "metalnessMap")) {
			Reflect.setProperty(uniforms, "metalnessMap", {value: Reflect.getProperty(material, "metalnessMap")});
			refreshTransformUniform(Reflect.getProperty(material, "metalnessMap"), Reflect.getProperty(uniforms, "metalnessMapTransform"));
		}

		Reflect.setProperty(uniforms, "roughness", {value: Reflect.getProperty(material, "roughness")});

		if (Reflect.hasField(material, "roughnessMap")) {
			Reflect.setProperty(uniforms, "roughnessMap", {value: Reflect.getProperty(material, "roughnessMap")});
			refreshTransformUniform(Reflect.getProperty(material, "roughnessMap"), Reflect.getProperty(uniforms, "roughnessMapTransform"));
		}

		if (Reflect.hasField(material, "envMap")) {
			//uniforms.envMap.value = material.envMap; // part of uniforms common
			Reflect.setProperty(uniforms, "envMapIntensity", {value: Reflect.getProperty(material, "envMapIntensity")});
		}
	}

	public function refreshUniformsPhysical(uniforms:Dynamic, material:Dynamic, transmissionRenderTarget:Dynamic) {
		Reflect.setProperty(uniforms, "ior", {value: Reflect.getProperty(material, "ior")}); // also part of uniforms common

		if (Reflect.getProperty(material, "sheen") > 0) {
			Reflect.setProperty(uniforms, "sheenColor", {value: Reflect.callMethod(Reflect.getProperty(material, "sheenColor").value, "copy", [Reflect.getProperty(material, "sheenColor")]).multiplyScalar(Reflect.getProperty(material, "sheen"))});
			Reflect.setProperty(uniforms, "sheenRoughness", {value: Reflect.getProperty(material, "sheenRoughness")});

			if (Reflect.hasField(material, "sheenColorMap")) {
				Reflect.setProperty(uniforms, "sheenColorMap", {value: Reflect.getProperty(material, "sheenColorMap")});
				refreshTransformUniform(Reflect.getProperty(material, "sheenColorMap"), Reflect.getProperty(uniforms, "sheenColorMapTransform"));
			}

			if (Reflect.hasField(material, "sheenRoughnessMap")) {
				Reflect.setProperty(uniforms, "sheenRoughnessMap", {value: Reflect.getProperty(material, "sheenRoughnessMap")});
				refreshTransformUniform(Reflect.getProperty(material, "sheenRoughnessMap"), Reflect.getProperty(uniforms, "sheenRoughnessMapTransform"));
			}
		}

		if (Reflect.getProperty(material, "clearcoat") > 0) {
			Reflect.setProperty(uniforms, "clearcoat", {value: Reflect.getProperty(material, "clearcoat")});
			Reflect.setProperty(uniforms, "clearcoatRoughness", {value: Reflect.getProperty(material, "clearcoatRoughness")});

			if (Reflect.hasField(material, "clearcoatMap")) {
				Reflect.setProperty(uniforms, "clearcoatMap", {value: Reflect.getProperty(material, "clearcoatMap")});
				refreshTransformUniform(Reflect.getProperty(material, "clearcoatMap"), Reflect.getProperty(uniforms, "clearcoatMapTransform"));
			}

			if (Reflect.hasField(material, "clearcoatRoughnessMap")) {
				Reflect.setProperty(uniforms, "clearcoatRoughnessMap", {value: Reflect.getProperty(material, "clearcoatRoughnessMap")});
				refreshTransformUniform(Reflect.getProperty(material, "clearcoatRoughnessMap"), Reflect.getProperty(uniforms, "clearcoatRoughnessMapTransform"));
			}

			if (Reflect.hasField(material, "clearcoatNormalMap")) {
				Reflect.setProperty(uniforms, "clearcoatNormalMap", {value: Reflect.getProperty(material, "clearcoatNormalMap")});
				refreshTransformUniform(Reflect.getProperty(material, "clearcoatNormalMap"), Reflect.getProperty(uniforms, "clearcoatNormalMapTransform"));
				Reflect.setProperty(uniforms, "clearcoatNormalScale", {value: Reflect.callMethod(Reflect.getProperty(material, "clearcoatNormalScale"), "copy", [])});

				if (Reflect.getProperty(material, "side") == BackSide) {
					Reflect.callMethod(Reflect.getProperty(uniforms, "clearcoatNormalScale").value, "negate", []);
				}
			}
		}

		if (Reflect.getProperty(material, "dispersion") > 0) {
			Reflect.setProperty(uniforms, "dispersion", {value: Reflect.getProperty(material, "dispersion")});
		}

		if (Reflect.getProperty(material, "iridescence") > 0) {
			Reflect.setProperty(uniforms, "iridescence", {value: Reflect.getProperty(material, "iridescence")});
			Reflect.setProperty(uniforms, "iridescenceIOR", {value: Reflect.getProperty(material, "iridescenceIOR")});
			Reflect.setProperty(uniforms, "iridescenceThicknessMinimum", {value: Reflect.getProperty(material, "iridescenceThicknessRange")[0]});
			Reflect.setProperty(uniforms, "iridescenceThicknessMaximum", {value: Reflect.getProperty(material, "iridescenceThicknessRange")[1]});

			if (Reflect.hasField(material, "iridescenceMap")) {
				Reflect.setProperty(uniforms, "iridescenceMap", {value: Reflect.getProperty(material, "iridescenceMap")});
				refreshTransformUniform(Reflect.getProperty(material, "iridescenceMap"), Reflect.getProperty(uniforms, "iridescenceMapTransform"));
			}

			if (Reflect.hasField(material, "iridescenceThicknessMap")) {
				Reflect.setProperty(uniforms, "iridescenceThicknessMap", {value: Reflect.getProperty(material, "iridescenceThicknessMap")});
				refreshTransformUniform(Reflect.getProperty(material, "iridescenceThicknessMap"), Reflect.getProperty(uniforms, "iridescenceThicknessMapTransform"));
			}
		}

		if (Reflect.getProperty(material, "transmission") > 0) {
			Reflect.setProperty(uniforms, "transmission", {value: Reflect.getProperty(material, "transmission")});
			Reflect.setProperty(uniforms, "transmissionSamplerMap", {value: Reflect.getProperty(transmissionRenderTarget, "texture")});
			Reflect.setProperty(uniforms, "transmissionSamplerSize", {value: Reflect.callMethod(Reflect.getProperty(transmissionRenderTarget, "width"), "set", [Reflect.getProperty(transmissionRenderTarget, "width"), Reflect.getProperty(transmissionRenderTarget, "height")])});

			if (Reflect.hasField(material, "transmissionMap")) {
				Reflect.setProperty(uniforms, "transmissionMap", {value: Reflect.getProperty(material, "transmissionMap")});
				refreshTransformUniform(Reflect.getProperty(material, "transmissionMap"), Reflect.getProperty(uniforms, "transmissionMapTransform"));
			}

			Reflect.setProperty(uniforms, "thickness", {value: Reflect.getProperty(material, "thickness")});

			if (Reflect.hasField(material, "thicknessMap")) {
				Reflect.setProperty(uniforms, "thicknessMap", {value: Reflect.getProperty(material, "thicknessMap")});
				refreshTransformUniform(Reflect.getProperty(material, "thicknessMap"), Reflect.getProperty(uniforms, "thicknessMapTransform"));
			}

			Reflect.setProperty(uniforms, "attenuationDistance", {value: Reflect.getProperty(material, "attenuationDistance")});
			Reflect.setProperty(uniforms, "attenuationColor", {value: Reflect.callMethod(Reflect.getProperty(material, "attenuationColor").value, "copy", [Reflect.getProperty(material, "attenuationColor")])});
		}

		if (Reflect.getProperty(material, "anisotropy") > 0) {
			Reflect.setProperty(uniforms, "anisotropyVector", {value: Reflect.callMethod(Reflect.getProperty(uniforms, "anisotropyVector").value, "set", [Reflect.getProperty(material, "anisotropy") * Math.cos(Reflect.getProperty(material, "anisotropyRotation")), Reflect.getProperty(material, "anisotropy") * Math.sin(Reflect.getProperty(material, "anisotropyRotation"))])});

			if (Reflect.hasField(material, "anisotropyMap")) {
				Reflect.setProperty(uniforms, "anisotropyMap", {value: Reflect.getProperty(material, "anisotropyMap")});
				refreshTransformUniform(Reflect.getProperty(material, "anisotropyMap"), Reflect.getProperty(uniforms, "anisotropyMapTransform"));
			}
		}

		Reflect.setProperty(uniforms, "specularIntensity", {value: Reflect.getProperty(material, "specularIntensity")});
		Reflect.setProperty(uniforms, "specularColor", {value: Reflect.callMethod(Reflect.getProperty(uniforms, "specularColor").value, "copy", [Reflect.getProperty(material, "specularColor")])});

		if (Reflect.hasField(material, "specularColorMap")) {
			Reflect.setProperty(uniforms, "specularColorMap", {value: Reflect.getProperty(material, "specularColorMap")});
			refreshTransformUniform(Reflect.getProperty(material, "specularColorMap"), Reflect.getProperty(uniforms, "specularColorMapTransform"));
		}

		if (Reflect.hasField(material, "specularIntensityMap")) {
			Reflect.setProperty(uniforms, "specularIntensityMap", {value: Reflect.getProperty(material, "specularIntensityMap")});
			refreshTransformUniform(Reflect.getProperty(material, "specularIntensityMap"), Reflect.getProperty(uniforms, "specularIntensityMapTransform"));
		}
	}

	public function refreshUniformsMatcap(uniforms:Dynamic, material:Dynamic) {
		if (Reflect.hasField(material, "matcap")) {
			Reflect.setProperty(uniforms, "matcap", {value: Reflect.getProperty(material, "matcap")});
		}
	}

	public function refreshUniformsDistance(uniforms:Dynamic, material:Dynamic) {
		var light:Dynamic = this.properties.get(material).light;
		Reflect.setProperty(uniforms, "referencePosition", {value: Reflect.callMethod(Reflect.getProperty(uniforms, "referencePosition").value, "setFromMatrixPosition", [Reflect.getProperty(light, "matrixWorld")])});
		Reflect.setProperty(uniforms, "nearDistance", {value: Reflect.getProperty(Reflect.getProperty(light, "shadow"), "camera").near});
		Reflect.setProperty(uniforms, "farDistance", {value: Reflect.getProperty(Reflect.getProperty(light, "shadow"), "camera").far});
	}

	public function getRefreshFogUniforms():Dynamic {
		return refreshFogUniforms;
	}

	public function getRefreshMaterialUniforms():Dynamic {
		return refreshMaterialUniforms;
	}
}