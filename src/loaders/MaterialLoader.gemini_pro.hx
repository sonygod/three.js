import haxe.io.Bytes;
import haxe.io.StringTools;
import haxe.Json;
import three.materials.Material;
import three.materials.ShadowMaterial;
import three.materials.SpriteMaterial;
import three.materials.RawShaderMaterial;
import three.materials.ShaderMaterial;
import three.materials.PointsMaterial;
import three.materials.MeshPhysicalMaterial;
import three.materials.MeshStandardMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshToonMaterial;
import three.materials.MeshNormalMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshDepthMaterial;
import three.materials.MeshDistanceMaterial;
import three.materials.MeshBasicMaterial;
import three.materials.MeshMatcapMaterial;
import three.materials.LineDashedMaterial;
import three.materials.LineBasicMaterial;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.math.Color;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;

class MaterialLoader extends Loader {
	public var textures:Map<String,Dynamic>;

	public function new(manager:Loader = null) {
		super(manager);
		textures = new Map<String,Dynamic>();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
		var loader = new FileLoader(manager);
		loader.setPath(path);
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);
		loader.load(url, function(text:String) {
			try {
				onLoad(parse(Json.parse(text)));
			} catch(e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
				}
				manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(json:Dynamic):Material {
		var textures = this.textures;

		function getTexture(name:String):Dynamic {
			if (textures.exists(name)) {
				return textures.get(name);
			} else {
				trace('THREE.MaterialLoader: Undefined texture $name');
			}
			return null;
		}

		var material = MaterialLoader.createMaterialFromType(StringTools.trim(json.type));

		if (json.uuid != null) material.uuid = StringTools.trim(json.uuid);
		if (json.name != null) material.name = StringTools.trim(json.name);
		if (json.color != null && material.color != null) material.color.setHex(StringTools.trim(json.color));
		if (json.roughness != null) material.roughness = Std.parseFloat(StringTools.trim(json.roughness));
		if (json.metalness != null) material.metalness = Std.parseFloat(StringTools.trim(json.metalness));
		if (json.sheen != null) material.sheen = Std.parseFloat(StringTools.trim(json.sheen));
		if (json.sheenColor != null) material.sheenColor = new Color().setHex(StringTools.trim(json.sheenColor));
		if (json.sheenRoughness != null) material.sheenRoughness = Std.parseFloat(StringTools.trim(json.sheenRoughness));
		if (json.emissive != null && material.emissive != null) material.emissive.setHex(StringTools.trim(json.emissive));
		if (json.specular != null && material.specular != null) material.specular.setHex(StringTools.trim(json.specular));
		if (json.specularIntensity != null) material.specularIntensity = Std.parseFloat(StringTools.trim(json.specularIntensity));
		if (json.specularColor != null && material.specularColor != null) material.specularColor.setHex(StringTools.trim(json.specularColor));
		if (json.shininess != null) material.shininess = Std.parseFloat(StringTools.trim(json.shininess));
		if (json.clearcoat != null) material.clearcoat = Std.parseFloat(StringTools.trim(json.clearcoat));
		if (json.clearcoatRoughness != null) material.clearcoatRoughness = Std.parseFloat(StringTools.trim(json.clearcoatRoughness));
		if (json.dispersion != null) material.dispersion = Std.parseFloat(StringTools.trim(json.dispersion));
		if (json.iridescence != null) material.iridescence = Std.parseFloat(StringTools.trim(json.iridescence));
		if (json.iridescenceIOR != null) material.iridescenceIOR = Std.parseFloat(StringTools.trim(json.iridescenceIOR));
		if (json.iridescenceThicknessRange != null) material.iridescenceThicknessRange = Std.parseFloat(StringTools.trim(json.iridescenceThicknessRange));
		if (json.transmission != null) material.transmission = Std.parseFloat(StringTools.trim(json.transmission));
		if (json.thickness != null) material.thickness = Std.parseFloat(StringTools.trim(json.thickness));
		if (json.attenuationDistance != null) material.attenuationDistance = Std.parseFloat(StringTools.trim(json.attenuationDistance));
		if (json.attenuationColor != null && material.attenuationColor != null) material.attenuationColor.setHex(StringTools.trim(json.attenuationColor));
		if (json.anisotropy != null) material.anisotropy = Std.parseFloat(StringTools.trim(json.anisotropy));
		if (json.anisotropyRotation != null) material.anisotropyRotation = Std.parseFloat(StringTools.trim(json.anisotropyRotation));
		if (json.fog != null) material.fog = Std.parseInt(StringTools.trim(json.fog));
		if (json.flatShading != null) material.flatShading = Std.parseInt(StringTools.trim(json.flatShading)) > 0;
		if (json.blending != null) material.blending = Std.parseInt(StringTools.trim(json.blending));
		if (json.combine != null) material.combine = Std.parseInt(StringTools.trim(json.combine));
		if (json.side != null) material.side = Std.parseInt(StringTools.trim(json.side));
		if (json.shadowSide != null) material.shadowSide = Std.parseInt(StringTools.trim(json.shadowSide));
		if (json.opacity != null) material.opacity = Std.parseFloat(StringTools.trim(json.opacity));
		if (json.transparent != null) material.transparent = Std.parseInt(StringTools.trim(json.transparent)) > 0;
		if (json.alphaTest != null) material.alphaTest = Std.parseFloat(StringTools.trim(json.alphaTest));
		if (json.alphaHash != null) material.alphaHash = Std.parseFloat(StringTools.trim(json.alphaHash));
		if (json.depthFunc != null) material.depthFunc = Std.parseInt(StringTools.trim(json.depthFunc));
		if (json.depthTest != null) material.depthTest = Std.parseInt(StringTools.trim(json.depthTest)) > 0;
		if (json.depthWrite != null) material.depthWrite = Std.parseInt(StringTools.trim(json.depthWrite)) > 0;
		if (json.colorWrite != null) material.colorWrite = Std.parseInt(StringTools.trim(json.colorWrite)) > 0;
		if (json.blendSrc != null) material.blendSrc = Std.parseInt(StringTools.trim(json.blendSrc));
		if (json.blendDst != null) material.blendDst = Std.parseInt(StringTools.trim(json.blendDst));
		if (json.blendEquation != null) material.blendEquation = Std.parseInt(StringTools.trim(json.blendEquation));
		if (json.blendSrcAlpha != null) material.blendSrcAlpha = Std.parseInt(StringTools.trim(json.blendSrcAlpha));
		if (json.blendDstAlpha != null) material.blendDstAlpha = Std.parseInt(StringTools.trim(json.blendDstAlpha));
		if (json.blendEquationAlpha != null) material.blendEquationAlpha = Std.parseInt(StringTools.trim(json.blendEquationAlpha));
		if (json.blendColor != null && material.blendColor != null) material.blendColor.setHex(StringTools.trim(json.blendColor));
		if (json.blendAlpha != null) material.blendAlpha = Std.parseFloat(StringTools.trim(json.blendAlpha));
		if (json.stencilWriteMask != null) material.stencilWriteMask = Std.parseInt(StringTools.trim(json.stencilWriteMask));
		if (json.stencilFunc != null) material.stencilFunc = Std.parseInt(StringTools.trim(json.stencilFunc));
		if (json.stencilRef != null) material.stencilRef = Std.parseInt(StringTools.trim(json.stencilRef));
		if (json.stencilFuncMask != null) material.stencilFuncMask = Std.parseInt(StringTools.trim(json.stencilFuncMask));
		if (json.stencilFail != null) material.stencilFail = Std.parseInt(StringTools.trim(json.stencilFail));
		if (json.stencilZFail != null) material.stencilZFail = Std.parseInt(StringTools.trim(json.stencilZFail));
		if (json.stencilZPass != null) material.stencilZPass = Std.parseInt(StringTools.trim(json.stencilZPass));
		if (json.stencilWrite != null) material.stencilWrite = Std.parseInt(StringTools.trim(json.stencilWrite)) > 0;

		if (json.wireframe != null) material.wireframe = Std.parseInt(StringTools.trim(json.wireframe)) > 0;
		if (json.wireframeLinewidth != null) material.wireframeLinewidth = Std.parseFloat(StringTools.trim(json.wireframeLinewidth));
		if (json.wireframeLinecap != null) material.wireframeLinecap = StringTools.trim(json.wireframeLinecap);
		if (json.wireframeLinejoin != null) material.wireframeLinejoin = StringTools.trim(json.wireframeLinejoin);

		if (json.rotation != null) material.rotation = Std.parseFloat(StringTools.trim(json.rotation));

		if (json.linewidth != null) material.linewidth = Std.parseFloat(StringTools.trim(json.linewidth));
		if (json.dashSize != null) material.dashSize = Std.parseFloat(StringTools.trim(json.dashSize));
		if (json.gapSize != null) material.gapSize = Std.parseFloat(StringTools.trim(json.gapSize));
		if (json.scale != null) material.scale = Std.parseFloat(StringTools.trim(json.scale));

		if (json.polygonOffset != null) material.polygonOffset = Std.parseInt(StringTools.trim(json.polygonOffset)) > 0;
		if (json.polygonOffsetFactor != null) material.polygonOffsetFactor = Std.parseFloat(StringTools.trim(json.polygonOffsetFactor));
		if (json.polygonOffsetUnits != null) material.polygonOffsetUnits = Std.parseFloat(StringTools.trim(json.polygonOffsetUnits));

		if (json.dithering != null) material.dithering = Std.parseInt(StringTools.trim(json.dithering)) > 0;

		if (json.alphaToCoverage != null) material.alphaToCoverage = Std.parseInt(StringTools.trim(json.alphaToCoverage)) > 0;
		if (json.premultipliedAlpha != null) material.premultipliedAlpha = Std.parseInt(StringTools.trim(json.premultipliedAlpha)) > 0;
		if (json.forceSinglePass != null) material.forceSinglePass = Std.parseInt(StringTools.trim(json.forceSinglePass)) > 0;

		if (json.visible != null) material.visible = Std.parseInt(StringTools.trim(json.visible)) > 0;

		if (json.toneMapped != null) material.toneMapped = Std.parseInt(StringTools.trim(json.toneMapped)) > 0;

		if (json.userData != null) material.userData = json.userData;

		if (json.vertexColors != null) {
			if (Std.is(json.vertexColors, Int)) {
				material.vertexColors = Std.parseInt(StringTools.trim(json.vertexColors)) > 0;
			} else {
				material.vertexColors = StringTools.trim(json.vertexColors);
			}
		}

		// Shader Material

		if (json.uniforms != null) {
			for (uniformName in json.uniforms) {
				var uniform = json.uniforms[uniformName];
				material.uniforms[uniformName] = new Map<String,Dynamic>();
				switch (StringTools.trim(uniform.type)) {
					case 't':
						material.uniforms[uniformName].set('value', getTexture(StringTools.trim(uniform.value)));
					case 'c':
						material.uniforms[uniformName].set('value', new Color().setHex(StringTools.trim(uniform.value)));
					case 'v2':
						material.uniforms[uniformName].set('value', new Vector2().fromArray(uniform.value));
					case 'v3':
						material.uniforms[uniformName].set('value', new Vector3().fromArray(uniform.value));
					case 'v4':
						material.uniforms[uniformName].set('value', new Vector4().fromArray(uniform.value));
					case 'm3':
						material.uniforms[uniformName].set('value', new Matrix3().fromArray(uniform.value));
					case 'm4':
						material.uniforms[uniformName].set('value', new Matrix4().fromArray(uniform.value));
					default:
						material.uniforms[uniformName].set('value', uniform.value);
				}
			}
		}

		if (json.defines != null) material.defines = json.defines;
		if (json.vertexShader != null) material.vertexShader = StringTools.trim(json.vertexShader);
		if (json.fragmentShader != null) material.fragmentShader = StringTools.trim(json.fragmentShader);
		if (json.glslVersion != null) material.glslVersion = Std.parseInt(StringTools.trim(json.glslVersion));

		if (json.extensions != null) {
			for (key in json.extensions) {
				material.extensions[key] = json.extensions[key];
			}
		}

		if (json.lights != null) material.lights = Std.parseInt(StringTools.trim(json.lights)) > 0;
		if (json.clipping != null) material.clipping = Std.parseInt(StringTools.trim(json.clipping)) > 0;

		// for PointsMaterial

		if (json.size != null) material.size = Std.parseFloat(StringTools.trim(json.size));
		if (json.sizeAttenuation != null) material.sizeAttenuation = Std.parseInt(StringTools.trim(json.sizeAttenuation)) > 0;

		// maps

		if (json.map != null) material.map = getTexture(StringTools.trim(json.map));
		if (json.matcap != null) material.matcap = getTexture(StringTools.trim(json.matcap));

		if (json.alphaMap != null) material.alphaMap = getTexture(StringTools.trim(json.alphaMap));

		if (json.bumpMap != null) material.bumpMap = getTexture(StringTools.trim(json.bumpMap));
		if (json.bumpScale != null) material.bumpScale = Std.parseFloat(StringTools.trim(json.bumpScale));

		if (json.normalMap != null) material.normalMap = getTexture(StringTools.trim(json.normalMap));
		if (json.normalMapType != null) material.normalMapType = Std.parseInt(StringTools.trim(json.normalMapType));
		if (json.normalScale != null) {
			var normalScale = json.normalScale;
			if (Std.is(normalScale, Array)) {
				material.normalScale = new Vector2().fromArray(normalScale);
			} else {
				material.normalScale = new Vector2(Std.parseFloat(StringTools.trim(normalScale)), Std.parseFloat(StringTools.trim(normalScale)));
			}
		}

		if (json.displacementMap != null) material.displacementMap = getTexture(StringTools.trim(json.displacementMap));
		if (json.displacementScale != null) material.displacementScale = Std.parseFloat(StringTools.trim(json.displacementScale));
		if (json.displacementBias != null) material.displacementBias = Std.parseFloat(StringTools.trim(json.displacementBias));

		if (json.roughnessMap != null) material.roughnessMap = getTexture(StringTools.trim(json.roughnessMap));
		if (json.metalnessMap != null) material.metalnessMap = getTexture(StringTools.trim(json.metalnessMap));

		if (json.emissiveMap != null) material.emissiveMap = getTexture(StringTools.trim(json.emissiveMap));
		if (json.emissiveIntensity != null) material.emissiveIntensity = Std.parseFloat(StringTools.trim(json.emissiveIntensity));

		if (json.specularMap != null) material.specularMap = getTexture(StringTools.trim(json.specularMap));
		if (json.specularIntensityMap != null) material.specularIntensityMap = getTexture(StringTools.trim(json.specularIntensityMap));
		if (json.specularColorMap != null) material.specularColorMap = getTexture(StringTools.trim(json.specularColorMap));

		if (json.envMap != null) material.envMap = getTexture(StringTools.trim(json.envMap));
		if (json.envMapRotation != null) material.envMapRotation.fromArray(json.envMapRotation);
		if (json.envMapIntensity != null) material.envMapIntensity = Std.parseFloat(StringTools.trim(json.envMapIntensity));

		if (json.reflectivity != null) material.reflectivity = Std.parseFloat(StringTools.trim(json.reflectivity));
		if (json.refractionRatio != null) material.refractionRatio = Std.parseFloat(StringTools.trim(json.refractionRatio));

		if (json.lightMap != null) material.lightMap = getTexture(StringTools.trim(json.lightMap));
		if (json.lightMapIntensity != null) material.lightMapIntensity = Std.parseFloat(StringTools.trim(json.lightMapIntensity));

		if (json.aoMap != null) material.aoMap = getTexture(StringTools.trim(json.aoMap));
		if (json.aoMapIntensity != null) material.aoMapIntensity = Std.parseFloat(StringTools.trim(json.aoMapIntensity));

		if (json.gradientMap != null) material.gradientMap = getTexture(StringTools.trim(json.gradientMap));

		if (json.clearcoatMap != null) material.clearcoatMap = getTexture(StringTools.trim(json.clearcoatMap));
		if (json.clearcoatRoughnessMap != null) material.clearcoatRoughnessMap = getTexture(StringTools.trim(json.clearcoatRoughnessMap));
		if (json.clearcoatNormalMap != null) material.clearcoatNormalMap = getTexture(StringTools.trim(json.clearcoatNormalMap));
		if (json.clearcoatNormalScale != null) material.clearcoatNormalScale = new Vector2().fromArray(json.clearcoatNormalScale);

		if (json.iridescenceMap != null) material.iridescenceMap = getTexture(StringTools.trim(json.iridescenceMap));
		if (json.iridescenceThicknessMap != null) material.iridescenceThicknessMap = getTexture(StringTools.trim(json.iridescenceThicknessMap));

		if (json.transmissionMap != null) material.transmissionMap = getTexture(StringTools.trim(json.transmissionMap));
		if (json.thicknessMap != null) material.thicknessMap = getTexture(StringTools.trim(json.thicknessMap));

		if (json.anisotropyMap != null) material.anisotropyMap = getTexture(StringTools.trim(json.anisotropyMap));

		if (json.sheenColorMap != null) material.sheenColorMap = getTexture(StringTools.trim(json.sheenColorMap));
		if (json.sheenRoughnessMap != null) material.sheenRoughnessMap = getTexture(StringTools.trim(json.sheenRoughnessMap));

		return material;
	}

	public function setTextures(value:Map<String,Dynamic>):MaterialLoader {
		textures = value;
		return this;
	}

	public static function createMaterialFromType(type:String):Material {
		var materialLib = {
			'ShadowMaterial':ShadowMaterial,
			'SpriteMaterial':SpriteMaterial,
			'RawShaderMaterial':RawShaderMaterial,
			'ShaderMaterial':ShaderMaterial,
			'PointsMaterial':PointsMaterial,
			'MeshPhysicalMaterial':MeshPhysicalMaterial,
			'MeshStandardMaterial':MeshStandardMaterial,
			'MeshPhongMaterial':MeshPhongMaterial,
			'MeshToonMaterial':MeshToonMaterial,
			'MeshNormalMaterial':MeshNormalMaterial,
			'MeshLambertMaterial':MeshLambertMaterial,
			'MeshDepthMaterial':MeshDepthMaterial,
			'MeshDistanceMaterial':MeshDistanceMaterial,
			'MeshBasicMaterial':MeshBasicMaterial,
			'MeshMatcapMaterial':MeshMatcapMaterial,
			'LineDashedMaterial':LineDashedMaterial,
			'LineBasicMaterial':LineBasicMaterial,
			'Material':Material
		};
		return Type.createInstance(materialLib[type]);
	}
}