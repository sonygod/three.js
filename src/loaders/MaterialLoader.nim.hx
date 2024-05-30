import Color.Color;
import Vector2.Vector2;
import Vector3.Vector3;
import Vector4.Vector4;
import Matrix3.Matrix3;
import Matrix4.Matrix4;
import FileLoader.FileLoader;
import Loader.Loader;
import Materials.Materials;

class MaterialLoader extends Loader {

	public var textures:Map<String, Dynamic>;

	public function new(manager:Loader.Manager) {
		super(manager);
		this.textures = new Map<String, Dynamic>();
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
		var scope = this;

		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(Json.parse(text)));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					Sys.println(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(json:Dynamic) {
		var textures = this.textures;

		function getTexture(name:String) {
			if (textures.get(name) == null) {
				Sys.println("THREE.MaterialLoader: Undefined texture", name);
			}
			return textures.get(name);
		}

		var material = MaterialLoader.createMaterialFromType(json.type);

		if (json.uuid != null) material.uuid = json.uuid;
		if (json.name != null) material.name = json.name;
		if (json.color != null && material.color != null) material.color.setHex(json.color);
		if (json.roughness != null) material.roughness = json.roughness;
		if (json.metalness != null) material.metalness = json.metalness;
		if (json.sheen != null) material.sheen = json.sheen;
		if (json.sheenColor != null) material.sheenColor = new Color().setHex(json.sheenColor);
		if (json.sheenRoughness != null) material.sheenRoughness = json.sheenRoughness;
		if (json.emissive != null && material.emissive != null) material.emissive.setHex(json.emissive);
		if (json.specular != null && material.specular != null) material.specular.setHex(json.specular);
		if (json.specularIntensity != null) material.specularIntensity = json.specularIntensity;
		if (json.specularColor != null && material.specularColor != null) material.specularColor.setHex(json.specularColor);
		if (json.shininess != null) material.shininess = json.shininess;
		if (json.clearcoat != null) material.clearcoat = json.clearcoat;
		if (json.clearcoatRoughness != null) material.clearcoatRoughness = json.clearcoatRoughness;
		if (json.dispersion != null) material.dispersion = json.dispersion;
		if (json.iridescence != null) material.iridescence = json.iridescence;
		if (json.iridescenceIOR != null) material.iridescenceIOR = json.iridescenceIOR;
		if (json.iridescenceThicknessRange != null) material.iridescenceThicknessRange = json.iridescenceThicknessRange;
		if (json.transmission != null) material.transmission = json.transmission;
		if (json.thickness != null) material.thickness = json.thickness;
		if (json.attenuationDistance != null) material.attenuationDistance = json.attenuationDistance;
		if (json.attenuationColor != null && material.attenuationColor != null) material.attenuationColor.setHex(json.attenuationColor);
		if (json.anisotropy != null) material.anisotropy = json.anisotropy;
		if (json.anisotropyRotation != null) material.anisotropyRotation = json.anisotropyRotation;
		if (json.fog != null) material.fog = json.fog;
		if (json.flatShading != null) material.flatShading = json.flatShading;
		if (json.blending != null) material.blending = json.blending;
		if (json.combine != null) material.combine = json.combine;
		if (json.side != null) material.side = json.side;
		if (json.shadowSide != null) material.shadowSide = json.shadowSide;
		if (json.opacity != null) material.opacity = json.opacity;
		if (json.transparent != null) material.transparent = json.transparent;
		if (json.alphaTest != null) material.alphaTest = json.alphaTest;
		if (json.alphaHash != null) material.alphaHash = json.alphaHash;
		if (json.depthFunc != null) material.depthFunc = json.depthFunc;
		if (json.depthTest != null) material.depthTest = json.depthTest;
		if (json.depthWrite != null) material.depthWrite = json.depthWrite;
		if (json.colorWrite != null) material.colorWrite = json.colorWrite;
		if (json.blendSrc != null) material.blendSrc = json.blendSrc;
		if (json.blendDst != null) material.blendDst = json.blendDst;
		if (json.blendEquation != null) material.blendEquation = json.blendEquation;
		if (json.blendSrcAlpha != null) material.blendSrcAlpha = json.blendSrcAlpha;
		if (json.blendDstAlpha != null) material.blendDstAlpha = json.blendDstAlpha;
		if (json.blendEquationAlpha != null) material.blendEquationAlpha = json.blendEquationAlpha;
		if (json.blendColor != null && material.blendColor != null) material.blendColor.setHex(json.blendColor);
		if (json.blendAlpha != null) material.blendAlpha = json.blendAlpha;
		if (json.stencilWriteMask != null) material.stencilWriteMask = json.stencilWriteMask;
		if (json.stencilFunc != null) material.stencilFunc = json.stencilFunc;
		if (json.stencilRef != null) material.stencilRef = json.stencilRef;
		if (json.stencilFuncMask != null) material.stencilFuncMask = json.stencilFuncMask;
		if (json.stencilFail != null) material.stencilFail = json.stencilFail;
		if (json.stencilZFail != null) material.stencilZFail = json.stencilZFail;
		if (json.stencilZPass != null) material.stencilZPass = json.stencilZPass;
		if (json.stencilWrite != null) material.stencilWrite = json.stencilWrite;

		if (json.wireframe != null) material.wireframe = json.wireframe;
		if (json.wireframeLinewidth != null) material.wireframeLinewidth = json.wireframeLinewidth;
		if (json.wireframeLinecap != null) material.wireframeLinecap = json.wireframeLinecap;
		if (json.wireframeLinejoin != null) material.wireframeLinejoin = json.wireframeLinejoin;

		if (json.rotation != null) material.rotation = json.rotation;

		if (json.linewidth != null) material.linewidth = json.linewidth;
		if (json.dashSize != null) material.dashSize = json.dashSize;
		if (json.gapSize != null) material.gapSize = json.gapSize;
		if (json.scale != null) material.scale = json.scale;

		if (json.polygonOffset != null) material.polygonOffset = json.polygonOffset;
		if (json.polygonOffsetFactor != null) material.polygonOffsetFactor = json.polygonOffsetFactor;
		if (json.polygonOffsetUnits != null) material.polygonOffsetUnits = json.polygonOffsetUnits;

		if (json.dithering != null) material.dithering = json.dithering;

		if (json.alphaToCoverage != null) material.alphaToCoverage = json.alphaToCoverage;
		if (json.premultipliedAlpha != null) material.premultipliedAlpha = json.premultipliedAlpha;
		if (json.forceSinglePass != null) material.forceSinglePass = json.forceSinglePass;

		if (json.visible != null) material.visible = json.visible;

		if (json.toneMapped != null) material.toneMapped = json.toneMapped;

		if (json.userData != null) material.userData = json.userData;

		if (json.vertexColors != null) {
			if (Std.is(json.vertexColors, Int)) {
				material.vertexColors = (json.vertexColors > 0) ? true : false;
			} else {
				material.vertexColors = json.vertexColors;
			}
		}

		// Shader Material

		if (json.uniforms != null) {
			for (name in json.uniforms) {
				var uniform = json.uniforms[name];

				material.uniforms[name] = {};

				switch (uniform.type) {
					case 't':
						material.uniforms[name].value = getTexture(uniform.value);
						break;

					case 'c':
						material.uniforms[name].value = new Color().setHex(uniform.value);
						break;

					case 'v2':
						material.uniforms[name].value = new Vector2().fromArray(uniform.value);
						break;

					case 'v3':
						material.uniforms[name].value = new Vector3().fromArray(uniform.value);
						break;

					case 'v4':
						material.uniforms[name].value = new Vector4().fromArray(uniform.value);
						break;

					case 'm3':
						material.uniforms[name].value = new Matrix3().fromArray(uniform.value);
						break;

					case 'm4':
						material.uniforms[name].value = new Matrix4().fromArray(uniform.value);
						break;

					default:
						material.uniforms[name].value = uniform.value;

				}

			}
		}

		if (json.defines != null) material.defines = json.defines;
		if (json.vertexShader != null) material.vertexShader = json.vertexShader;
		if (json.fragmentShader != null) material.fragmentShader = json.fragmentShader;
		if (json.glslVersion != null) material.glslVersion = json.glslVersion;

		if (json.extensions != null) {
			for (key in json.extensions) {
				material.extensions[key] = json.extensions[key];
			}
		}

		if (json.lights != null) material.lights = json.lights;
		if (json.clipping != null) material.clipping = json.clipping;

		// for PointsMaterial

		if (json.size != null) material.size = json.size;
		if (json.sizeAttenuation != null) material.sizeAttenuation = json.sizeAttenuation;

		// maps

		if (json.map != null) material.map = getTexture(json.map);
		if (json.matcap != null) material.matcap = getTexture(json.matcap);

		if (json.alphaMap != null) material.alphaMap = getTexture(json.alphaMap);

		if (json.bumpMap != null) material.bumpMap = getTexture(json.bumpMap);
		if (json.bumpScale != null) material.bumpScale = json.bumpScale;

		if (json.normalMap != null) material.normalMap = getTexture(json.normalMap);
		if (json.normalMapType != null) material.normalMapType = json.normalMapType;
		if (json.normalScale != null) {
			var normalScale = json.normalScale;

			if (!Std.isArray(normalScale)) {
				// Blender exporter used to export a scalar. See #7459

				normalScale = [normalScale, normalScale];
			}

			material.normalScale = new Vector2().fromArray(normalScale);
		}

		if (json.displacementMap != null) material.displacementMap = getTexture(json.displacementMap);
		if (json.displacementScale != null) material.displacementScale = json.displacementScale;
		if (json.displacementBias != null) material.displacementBias = json.displacementBias;

		if (json.roughnessMap != null) material.roughnessMap = getTexture(json.roughnessMap);
		if (json.metalnessMap != null) material.metalnessMap = getTexture(json.metalnessMap);

		if (json.emissiveMap != null) material.emissiveMap = getTexture(json.emissiveMap);
		if (json.emissiveIntensity != null) material.emissiveIntensity = json.emissiveIntensity;

		if (json.specularMap != null) material.specularMap = getTexture(json.specularMap);
		if (json.specularIntensityMap != null) material.specularIntensityMap = getTexture(json.specularIntensityMap);
		if (json.specularColorMap != null) material.specularColorMap = getTexture(json.specularColorMap);

		if (json.envMap != null) material.envMap = getTexture(json.envMap);
		if (json.envMapRotation != null) material.envMapRotation.fromArray(json.envMapRotation);
		if (json.envMapIntensity != null) material.envMapIntensity = json.envMapIntensity;

		if (json.reflectivity != null) material.reflectivity = json.reflectivity;
		if (json.refractionRatio != null) material.refractionRatio = json.refractionRatio;

		if (json.lightMap != null) material.lightMap = getTexture(json.lightMap);
		if (json.lightMapIntensity != null) material.lightMapIntensity = json.lightMapIntensity;

		if (json.aoMap != null) material.aoMap = getTexture(json.aoMap);
		if (json.aoMapIntensity != null) material.aoMapIntensity = json.aoMapIntensity;

		if (json.gradientMap != null) material.gradientMap = getTexture(json.gradientMap);

		if (json.clearcoatMap != null) material.clearcoatMap = getTexture(json.clearcoatMap);
		if (json.clearcoatRoughnessMap != null) material.clearcoatRoughnessMap = getTexture(json.clearcoatRoughnessMap);
		if (json.clearcoatNormalMap != null) material.clearcoatNormalMap = getTexture(json.clearcoatNormalMap);
		if (json.clearcoatNormalScale != null) material.clearcoatNormalScale = new Vector2().fromArray(json.clearcoatNormalScale);

		if (json.iridescenceMap != null) material.iridescenceMap = getTexture(json.iridescenceMap);
		if (json.iridescenceThicknessMap != null) material.iridescenceThicknessMap = getTexture(json.iridescenceThicknessMap);

		if (json.transmissionMap != null) material.transmissionMap = getTexture(json.transmissionMap);
		if (json.thicknessMap != null) material.thicknessMap = getTexture(json.thicknessMap);

		if (json.anisotropyMap != null) material.anisotropyMap = getTexture(json.anisotropyMap);

		if (json.sheenColorMap != null) material.sheenColorMap = getTexture(json.sheenColorMap);
		if (json.sheenRoughnessMap != null) material.sheenRoughnessMap = getTexture(json.sheenRoughnessMap);

		return material;
	}

	public function setTextures(value:Map<String, Dynamic>) {
		this.textures = value;
		return this;
	}

	public static function createMaterialFromType(type:String) {
		var materialLib = {
			ShadowMaterial: Materials.ShadowMaterial,
			SpriteMaterial: Materials.SpriteMaterial,
			RawShaderMaterial: Materials.RawShaderMaterial,
			ShaderMaterial: Materials.ShaderMaterial,
			PointsMaterial: Materials.PointsMaterial,
			MeshPhysicalMaterial: Materials.MeshPhysicalMaterial,
			MeshStandardMaterial: Materials.MeshStandardMaterial,
			MeshPhongMaterial: Materials.MeshPhongMaterial,
			MeshToonMaterial: Materials.MeshToonMaterial,
			MeshNormalMaterial: Materials.MeshNormalMaterial,
			MeshLambertMaterial: Materials.MeshLambertMaterial,
			MeshDepthMaterial: Materials.MeshDepthMaterial,
			MeshDistanceMaterial: Materials.MeshDistanceMaterial,
			MeshBasicMaterial: Materials.MeshBasicMaterial,
			MeshMatcapMaterial: Materials.MeshMatcapMaterial,
			LineDashedMaterial: Materials.LineDashedMaterial,
			LineBasicMaterial: Materials.LineBasicMaterial,
			Material: Materials.Material
		};

		return new materialLib[type]();
	}
}