import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix3;
import three.math.Matrix4;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.materials.Materials.ShadowMaterial;
import three.materials.Materials.SpriteMaterial;
import three.materials.Materials.RawShaderMaterial;
import three.materials.Materials.ShaderMaterial;
import three.materials.Materials.PointsMaterial;
import three.materials.Materials.MeshPhysicalMaterial;
import three.materials.Materials.MeshStandardMaterial;
import three.materials.Materials.MeshPhongMaterial;
import three.materials.Materials.MeshToonMaterial;
import three.materials.Materials.MeshNormalMaterial;
import three.materials.Materials.MeshLambertMaterial;
import three.materials.Materials.MeshDepthMaterial;
import three.materials.Materials.MeshDistanceMaterial;
import three.materials.Materials.MeshBasicMaterial;
import three.materials.Materials.MeshMatcapMaterial;
import three.materials.Materials.LineDashedMaterial;
import three.materials.Materials.LineBasicMaterial;
import three.materials.Materials.Material;

class MaterialLoader extends Loader {

	public var textures:Map<String,Dynamic>;

	public function new(manager:Loader = null) {
		super(manager);
		textures = new Map<String,Dynamic>();
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null):Void {
		final scope = this;
		final loader = new FileLoader(manager);
		loader.setPath(path);
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);
		loader.load(url, function(text:String):Void {
			try {
				onLoad(scope.parse(js.JSON.parse(text)));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					Sys.println('ERROR: ${e}');
				}
				manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(json:Dynamic):Material {
		final textures = this.textures;

		final getTexture = function(name:String):Dynamic {
			if (!textures.exists(name)) {
				Sys.println('WARN: THREE.MaterialLoader: Undefined texture ${name}');
			}
			return textures.get(name);
		};

		final material = MaterialLoader.createMaterialFromType(cast json.type);

		if (js.Syntax.hasField(json, 'uuid')) material.uuid = cast json.uuid;
		if (js.Syntax.hasField(json, 'name')) material.name = cast json.name;
		if (js.Syntax.hasField(json, 'color') && material.color != null) material.color.setHex(cast json.color);
		if (js.Syntax.hasField(json, 'roughness')) material.roughness = cast json.roughness;
		if (js.Syntax.hasField(json, 'metalness')) material.metalness = cast json.metalness;
		if (js.Syntax.hasField(json, 'sheen')) material.sheen = cast json.sheen;
		if (js.Syntax.hasField(json, 'sheenColor') && material.sheenColor != null) material.sheenColor = new Color().setHex(cast json.sheenColor);
		if (js.Syntax.hasField(json, 'sheenRoughness')) material.sheenRoughness = cast json.sheenRoughness;
		if (js.Syntax.hasField(json, 'emissive') && material.emissive != null) material.emissive.setHex(cast json.emissive);
		if (js.Syntax.hasField(json, 'specular') && material.specular != null) material.specular.setHex(cast json.specular);
		if (js.Syntax.hasField(json, 'specularIntensity')) material.specularIntensity = cast json.specularIntensity;
		if (js.Syntax.hasField(json, 'specularColor') && material.specularColor != null) material.specularColor.setHex(cast json.specularColor);
		if (js.Syntax.hasField(json, 'shininess')) material.shininess = cast json.shininess;
		if (js.Syntax.hasField(json, 'clearcoat')) material.clearcoat = cast json.clearcoat;
		if (js.Syntax.hasField(json, 'clearcoatRoughness')) material.clearcoatRoughness = cast json.clearcoatRoughness;
		if (js.Syntax.hasField(json, 'dispersion')) material.dispersion = cast json.dispersion;
		if (js.Syntax.hasField(json, 'iridescence')) material.iridescence = cast json.iridescence;
		if (js.Syntax.hasField(json, 'iridescenceIOR')) material.iridescenceIOR = cast json.iridescenceIOR;
		if (js.Syntax.hasField(json, 'iridescenceThicknessRange')) material.iridescenceThicknessRange = cast json.iridescenceThicknessRange;
		if (js.Syntax.hasField(json, 'transmission')) material.transmission = cast json.transmission;
		if (js.Syntax.hasField(json, 'thickness')) material.thickness = cast json.thickness;
		if (js.Syntax.hasField(json, 'attenuationDistance')) material.attenuationDistance = cast json.attenuationDistance;
		if (js.Syntax.hasField(json, 'attenuationColor') && material.attenuationColor != null) material.attenuationColor.setHex(cast json.attenuationColor);
		if (js.Syntax.hasField(json, 'anisotropy')) material.anisotropy = cast json.anisotropy;
		if (js.Syntax.hasField(json, 'anisotropyRotation')) material.anisotropyRotation = cast json.anisotropyRotation;
		if (js.Syntax.hasField(json, 'fog')) material.fog = cast json.fog;
		if (js.Syntax.hasField(json, 'flatShading')) material.flatShading = cast json.flatShading;
		if (js.Syntax.hasField(json, 'blending')) material.blending = cast json.blending;
		if (js.Syntax.hasField(json, 'combine')) material.combine = cast json.combine;
		if (js.Syntax.hasField(json, 'side')) material.side = cast json.side;
		if (js.Syntax.hasField(json, 'shadowSide')) material.shadowSide = cast json.shadowSide;
		if (js.Syntax.hasField(json, 'opacity')) material.opacity = cast json.opacity;
		if (js.Syntax.hasField(json, 'transparent')) material.transparent = cast json.transparent;
		if (js.Syntax.hasField(json, 'alphaTest')) material.alphaTest = cast json.alphaTest;
		if (js.Syntax.hasField(json, 'alphaHash')) material.alphaHash = cast json.alphaHash;
		if (js.Syntax.hasField(json, 'depthFunc')) material.depthFunc = cast json.depthFunc;
		if (js.Syntax.hasField(json, 'depthTest')) material.depthTest = cast json.depthTest;
		if (js.Syntax.hasField(json, 'depthWrite')) material.depthWrite = cast json.depthWrite;
		if (js.Syntax.hasField(json, 'colorWrite')) material.colorWrite = cast json.colorWrite;
		if (js.Syntax.hasField(json, 'blendSrc')) material.blendSrc = cast json.blendSrc;
		if (js.Syntax.hasField(json, 'blendDst')) material.blendDst = cast json.blendDst;
		if (js.Syntax.hasField(json, 'blendEquation')) material.blendEquation = cast json.blendEquation;
		if (js.Syntax.hasField(json, 'blendSrcAlpha')) material.blendSrcAlpha = cast json.blendSrcAlpha;
		if (js.Syntax.hasField(json, 'blendDstAlpha')) material.blendDstAlpha = cast json.blendDstAlpha;
		if (js.Syntax.hasField(json, 'blendEquationAlpha')) material.blendEquationAlpha = cast json.blendEquationAlpha;
		if (js.Syntax.hasField(json, 'blendColor') && material.blendColor != null) material.blendColor.setHex(cast json.blendColor);
		if (js.Syntax.hasField(json, 'blendAlpha')) material.blendAlpha = cast json.blendAlpha;
		if (js.Syntax.hasField(json, 'stencilWriteMask')) material.stencilWriteMask = cast json.stencilWriteMask;
		if (js.Syntax.hasField(json, 'stencilFunc')) material.stencilFunc = cast json.stencilFunc;
		if (js.Syntax.hasField(json, 'stencilRef')) material.stencilRef = cast json.stencilRef;
		if (js.Syntax.hasField(json, 'stencilFuncMask')) material.stencilFuncMask = cast json.stencilFuncMask;
		if (js.Syntax.hasField(json, 'stencilFail')) material.stencilFail = cast json.stencilFail;
		if (js.Syntax.hasField(json, 'stencilZFail')) material.stencilZFail = cast json.stencilZFail;
		if (js.Syntax.hasField(json, 'stencilZPass')) material.stencilZPass = cast json.stencilZPass;
		if (js.Syntax.hasField(json, 'stencilWrite')) material.stencilWrite = cast json.stencilWrite;

		if (js.Syntax.hasField(json, 'wireframe')) material.wireframe = cast json.wireframe;
		if (js.Syntax.hasField(json, 'wireframeLinewidth')) material.wireframeLinewidth = cast json.wireframeLinewidth;
		if (js.Syntax.hasField(json, 'wireframeLinecap')) material.wireframeLinecap = cast json.wireframeLinecap;
		if (js.Syntax.hasField(json, 'wireframeLinejoin')) material.wireframeLinejoin = cast json.wireframeLinejoin;

		if (js.Syntax.hasField(json, 'rotation')) material.rotation = cast json.rotation;

		if (js.Syntax.hasField(json, 'linewidth')) material.linewidth = cast json.linewidth;
		if (js.Syntax.hasField(json, 'dashSize')) material.dashSize = cast json.dashSize;
		if (js.Syntax.hasField(json, 'gapSize')) material.gapSize = cast json.gapSize;
		if (js.Syntax.hasField(json, 'scale')) material.scale = cast json.scale;

		if (js.Syntax.hasField(json, 'polygonOffset')) material.polygonOffset = cast json.polygonOffset;
		if (js.Syntax.hasField(json, 'polygonOffsetFactor')) material.polygonOffsetFactor = cast json.polygonOffsetFactor;
		if (js.Syntax.hasField(json, 'polygonOffsetUnits')) material.polygonOffsetUnits = cast json.polygonOffsetUnits;

		if (js.Syntax.hasField(json, 'dithering')) material.dithering = cast json.dithering;

		if (js.Syntax.hasField(json, 'alphaToCoverage')) material.alphaToCoverage = cast json.alphaToCoverage;
		if (js.Syntax.hasField(json, 'premultipliedAlpha')) material.premultipliedAlpha = cast json.premultipliedAlpha;
		if (js.Syntax.hasField(json, 'forceSinglePass')) material.forceSinglePass = cast json.forceSinglePass;

		if (js.Syntax.hasField(json, 'visible')) material.visible = cast json.visible;

		if (js.Syntax.hasField(json, 'toneMapped')) material.toneMapped = cast json.toneMapped;

		if (js.Syntax.hasField(json, 'userData')) material.userData = cast json.userData;

		if (js.Syntax.hasField(json, 'vertexColors')) {
			if (js.Syntax.isInt(json.vertexColors)) {
				material.vertexColors = (cast json.vertexColors) > 0;
			} else {
				material.vertexColors = cast json.vertexColors;
			}
		}

		// Shader Material

		if (js.Syntax.hasField(json, 'uniforms')) {
			for (name in cast json.uniforms) {
				final uniform = cast json.uniforms[name];
				material.uniforms[name] = new Map<String,Dynamic>();
				switch (cast uniform.type) {
					case 't':
						material.uniforms[name].set('value', getTexture(cast uniform.value));
						break;
					case 'c':
						material.uniforms[name].set('value', new Color().setHex(cast uniform.value));
						break;
					case 'v2':
						material.uniforms[name].set('value', new Vector2().fromArray(cast uniform.value));
						break;
					case 'v3':
						material.uniforms[name].set('value', new Vector3().fromArray(cast uniform.value));
						break;
					case 'v4':
						material.uniforms[name].set('value', new Vector4().fromArray(cast uniform.value));
						break;
					case 'm3':
						material.uniforms[name].set('value', new Matrix3().fromArray(cast uniform.value));
						break;
					case 'm4':
						material.uniforms[name].set('value', new Matrix4().fromArray(cast uniform.value));
						break;
					default:
						material.uniforms[name].set('value', cast uniform.value);
				}
			}
		}

		if (js.Syntax.hasField(json, 'defines')) material.defines = cast json.defines;
		if (js.Syntax.hasField(json, 'vertexShader')) material.vertexShader = cast json.vertexShader;
		if (js.Syntax.hasField(json, 'fragmentShader')) material.fragmentShader = cast json.fragmentShader;
		if (js.Syntax.hasField(json, 'glslVersion')) material.glslVersion = cast json.glslVersion;

		if (js.Syntax.hasField(json, 'extensions')) {
			for (key in cast json.extensions) {
				material.extensions[key] = cast json.extensions[key];
			}
		}

		if (js.Syntax.hasField(json, 'lights')) material.lights = cast json.lights;
		if (js.Syntax.hasField(json, 'clipping')) material.clipping = cast json.clipping;

		// for PointsMaterial

		if (js.Syntax.hasField(json, 'size')) material.size = cast json.size;
		if (js.Syntax.hasField(json, 'sizeAttenuation')) material.sizeAttenuation = cast json.sizeAttenuation;

		// maps

		if (js.Syntax.hasField(json, 'map')) material.map = getTexture(cast json.map);
		if (js.Syntax.hasField(json, 'matcap')) material.matcap = getTexture(cast json.matcap);

		if (js.Syntax.hasField(json, 'alphaMap')) material.alphaMap = getTexture(cast json.alphaMap);

		if (js.Syntax.hasField(json, 'bumpMap')) material.bumpMap = getTexture(cast json.bumpMap);
		if (js.Syntax.hasField(json, 'bumpScale')) material.bumpScale = cast json.bumpScale;

		if (js.Syntax.hasField(json, 'normalMap')) material.normalMap = getTexture(cast json.normalMap);
		if (js.Syntax.hasField(json, 'normalMapType')) material.normalMapType = cast json.normalMapType;
		if (js.Syntax.hasField(json, 'normalScale')) {
			final normalScale = cast json.normalScale;
			final isArray = js.Syntax.isArray(normalScale);
			if (!isArray) {
				// Blender exporter used to export a scalar. See #7459
				material.normalScale = new Vector2().fromArray([normalScale, normalScale]);
			} else {
				material.normalScale = new Vector2().fromArray(normalScale);
			}
		}

		if (js.Syntax.hasField(json, 'displacementMap')) material.displacementMap = getTexture(cast json.displacementMap);
		if (js.Syntax.hasField(json, 'displacementScale')) material.displacementScale = cast json.displacementScale;
		if (js.Syntax.hasField(json, 'displacementBias')) material.displacementBias = cast json.displacementBias;

		if (js.Syntax.hasField(json, 'roughnessMap')) material.roughnessMap = getTexture(cast json.roughnessMap);
		if (js.Syntax.hasField(json, 'metalnessMap')) material.metalnessMap = getTexture(cast json.metalnessMap);

		if (js.Syntax.hasField(json, 'emissiveMap')) material.emissiveMap = getTexture(cast json.emissiveMap);
		if (js.Syntax.hasField(json, 'emissiveIntensity')) material.emissiveIntensity = cast json.emissiveIntensity;

		if (js.Syntax.hasField(json, 'specularMap')) material.specularMap = getTexture(cast json.specularMap);
		if (js.Syntax.hasField(json, 'specularIntensityMap')) material.specularIntensityMap = getTexture(cast json.specularIntensityMap);
		if (js.Syntax.hasField(json, 'specularColorMap')) material.specularColorMap = getTexture(cast json.specularColorMap);

		if (js.Syntax.hasField(json, 'envMap')) material.envMap = getTexture(cast json.envMap);
		if (js.Syntax.hasField(json, 'envMapRotation')) material.envMapRotation.fromArray(cast json.envMapRotation);
		if (js.Syntax.hasField(json, 'envMapIntensity')) material.envMapIntensity = cast json.envMapIntensity;

		if (js.Syntax.hasField(json, 'reflectivity')) material.reflectivity = cast json.reflectivity;
		if (js.Syntax.hasField(json, 'refractionRatio')) material.refractionRatio = cast json.refractionRatio;

		if (js.Syntax.hasField(json, 'lightMap')) material.lightMap = getTexture(cast json.lightMap);
		if (js.Syntax.hasField(json, 'lightMapIntensity')) material.lightMapIntensity = cast json.lightMapIntensity;

		if (js.Syntax.hasField(json, 'aoMap')) material.aoMap = getTexture(cast json.aoMap);
		if (js.Syntax.hasField(json, 'aoMapIntensity')) material.aoMapIntensity = cast json.aoMapIntensity;

		if (js.Syntax.hasField(json, 'gradientMap')) material.gradientMap = getTexture(cast json.gradientMap);

		if (js.Syntax.hasField(json, 'clearcoatMap')) material.clearcoatMap = getTexture(cast json.clearcoatMap);
		if (js.Syntax.hasField(json, 'clearcoatRoughnessMap')) material.clearcoatRoughnessMap = getTexture(cast json.clearcoatRoughnessMap);
		if (js.Syntax.hasField(json, 'clearcoatNormalMap')) material.clearcoatNormalMap = getTexture(cast json.clearcoatNormalMap);
		if (js.Syntax.hasField(json, 'clearcoatNormalScale')) material.clearcoatNormalScale = new Vector2().fromArray(cast json.clearcoatNormalScale);

		if (js.Syntax.hasField(json, 'iridescenceMap')) material.iridescenceMap = getTexture(cast json.iridescenceMap);
		if (js.Syntax.hasField(json, 'iridescenceThicknessMap')) material.iridescenceThicknessMap = getTexture(cast json.iridescenceThicknessMap);

		if (js.Syntax.hasField(json, 'transmissionMap')) material.transmissionMap = getTexture(cast json.transmissionMap);
		if (js.Syntax.hasField(json, 'thicknessMap')) material.thicknessMap = getTexture(cast json.thicknessMap);

		if (js.Syntax.hasField(json, 'anisotropyMap')) material.anisotropyMap = getTexture(cast json.anisotropyMap);

		if (js.Syntax.hasField(json, 'sheenColorMap')) material.sheenColorMap = getTexture(cast json.sheenColorMap);
		if (js.Syntax.hasField(json, 'sheenRoughnessMap')) material.sheenRoughnessMap = getTexture(cast json.sheenRoughnessMap);

		return material;
	}

	public function setTextures(value:Map<String,Dynamic>):MaterialLoader {
		textures = value;
		return this;
	}

	static public function createMaterialFromType(type:String):Material {
		switch (type) {
			case 'ShadowMaterial':
				return new ShadowMaterial();
			case 'SpriteMaterial':
				return new SpriteMaterial();
			case 'RawShaderMaterial':
				return new RawShaderMaterial();
			case 'ShaderMaterial':
				return new ShaderMaterial();
			case 'PointsMaterial':
				return new PointsMaterial();
			case 'MeshPhysicalMaterial':
				return new MeshPhysicalMaterial();
			case 'MeshStandardMaterial':
				return new MeshStandardMaterial();
			case 'MeshPhongMaterial':
				return new MeshPhongMaterial();
			case 'MeshToonMaterial':
				return new MeshToonMaterial();
			case 'MeshNormalMaterial':
				return new MeshNormalMaterial();
			case 'MeshLambertMaterial':
				return new MeshLambertMaterial();
			case 'MeshDepthMaterial':
				return new MeshDepthMaterial();
			case 'MeshDistanceMaterial':
				return new MeshDistanceMaterial();
			case 'MeshBasicMaterial':
				return new MeshBasicMaterial();
			case 'MeshMatcapMaterial':
				return new MeshMatcapMaterial();
			case 'LineDashedMaterial':
				return new LineDashedMaterial();
			case 'LineBasicMaterial':
				return new LineBasicMaterial();
			case 'Material':
				return new Material();
			default:
				Sys.println('WARN: THREE.MaterialLoader: Unsupported material type: ${type}');
				return null;
		}
	}

}