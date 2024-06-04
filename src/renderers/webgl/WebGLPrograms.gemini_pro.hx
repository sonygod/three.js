import three.constants.BackSide;
import three.constants.DoubleSide;
import three.constants.CubeUVReflectionMapping;
import three.constants.ObjectSpaceNormalMap;
import three.constants.TangentSpaceNormalMap;
import three.constants.NoToneMapping;
import three.constants.NormalBlending;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBTransfer;
import three.core.Layers;
import three.renderers.webgl.WebGLProgram;
import three.renderers.webgl.WebGLShaderCache;
import three.shaders.ShaderLib;
import three.shaders.UniformsUtils;
import three.math.ColorManagement;

class WebGLPrograms {

	public var _programLayers:Layers;
	public var _customShaders:WebGLShaderCache;
	public var _activeChannels:haxe.ds.Set<Int>;
	public var programs:Array<WebGLProgram>;
	public var logarithmicDepthBuffer:Bool;
	public var SUPPORTS_VERTEX_TEXTURES:Bool;
	public var precision:String;
	public var shaderIDs:Dynamic;
	public var renderer:Dynamic;
	public var cubemaps:Dynamic;
	public var cubeuvmaps:Dynamic;
	public var extensions:Dynamic;
	public var capabilities:Dynamic;
	public var bindingStates:Dynamic;
	public var clipping:Dynamic;

	public function new(renderer, cubemaps, cubeuvmaps, extensions, capabilities, bindingStates, clipping) {
		this._programLayers = new Layers();
		this._customShaders = new WebGLShaderCache();
		this._activeChannels = new haxe.ds.Set();
		this.programs = new Array<WebGLProgram>();
		this.logarithmicDepthBuffer = capabilities.logarithmicDepthBuffer;
		this.SUPPORTS_VERTEX_TEXTURES = capabilities.vertexTextures;
		this.precision = capabilities.precision;
		this.shaderIDs = {
			MeshDepthMaterial: "depth",
			MeshDistanceMaterial: "distanceRGBA",
			MeshNormalMaterial: "normal",
			MeshBasicMaterial: "basic",
			MeshLambertMaterial: "lambert",
			MeshPhongMaterial: "phong",
			MeshToonMaterial: "toon",
			MeshStandardMaterial: "physical",
			MeshPhysicalMaterial: "physical",
			MeshMatcapMaterial: "matcap",
			LineBasicMaterial: "basic",
			LineDashedMaterial: "dashed",
			PointsMaterial: "points",
			ShadowMaterial: "shadow",
			SpriteMaterial: "sprite"
		};
		this.renderer = renderer;
		this.cubemaps = cubemaps;
		this.cubeuvmaps = cubeuvmaps;
		this.extensions = extensions;
		this.capabilities = capabilities;
		this.bindingStates = bindingStates;
		this.clipping = clipping;
	}

	public function getChannel(value:Int):String {
		this._activeChannels.add(value);
		if (value == 0) {
			return "uv";
		}
		return "uv${value}";
	}

	public function getParameters(material:Dynamic, lights:Dynamic, shadows:Dynamic, scene:Dynamic, object:Dynamic):Dynamic {
		var fog = scene.fog;
		var geometry = object.geometry;
		var environment = material.isMeshStandardMaterial ? scene.environment : null;
		var envMap = (material.isMeshStandardMaterial ? this.cubeuvmaps : this.cubemaps).get(material.envMap || environment);
		var envMapCubeUVHeight = (envMap != null) && (envMap.mapping == CubeUVReflectionMapping) ? envMap.image.height : null;
		var shaderID = this.shaderIDs[material.type];
		if (material.precision != null) {
			this.precision = this.capabilities.getMaxPrecision(material.precision);
			if (this.precision != material.precision) {
				js.Lib.warn("THREE.WebGLProgram.getParameters: ${material.precision} not supported, using ${this.precision} instead.");
			}
		}
		var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
		var morphTargetsCount = (morphAttribute != null) ? morphAttribute.length : 0;
		var morphTextureStride = 0;
		if (geometry.morphAttributes.position != null) morphTextureStride = 1;
		if (geometry.morphAttributes.normal != null) morphTextureStride = 2;
		if (geometry.morphAttributes.color != null) morphTextureStride = 3;
		var vertexShader:String, fragmentShader:String;
		var customVertexShaderID:String, customFragmentShaderID:String;
		if (shaderID != null) {
			var shader = ShaderLib[shaderID];
			vertexShader = shader.vertexShader;
			fragmentShader = shader.fragmentShader;
		} else {
			vertexShader = material.vertexShader;
			fragmentShader = material.fragmentShader;
			this._customShaders.update(material);
			customVertexShaderID = this._customShaders.getVertexShaderID(material);
			customFragmentShaderID = this._customShaders.getFragmentShaderID(material);
		}
		var currentRenderTarget = this.renderer.getRenderTarget();
		var IS_INSTANCEDMESH = object.isInstancedMesh == true;
		var IS_BATCHEDMESH = object.isBatchedMesh == true;
		var HAS_MAP = material.map != null;
		var HAS_MATCAP = material.matcap != null;
		var HAS_ENVMAP = envMap != null;
		var HAS_AOMAP = material.aoMap != null;
		var HAS_LIGHTMAP = material.lightMap != null;
		var HAS_BUMPMAP = material.bumpMap != null;
		var HAS_NORMALMAP = material.normalMap != null;
		var HAS_DISPLACEMENTMAP = material.displacementMap != null && this.SUPPORTS_VERTEX_TEXTURES;
		var HAS_EMISSIVEMAP = material.emissiveMap != null;
		var HAS_METALNESSMAP = material.metalnessMap != null;
		var HAS_ROUGHNESSMAP = material.roughnessMap != null;
		var HAS_ANISOTROPY = material.anisotropy > 0;
		var HAS_CLEARCOAT = material.clearcoat > 0;
		var HAS_DISPERSION = material.dispersion > 0;
		var HAS_IRIDESCENCE = material.iridescence > 0;
		var HAS_SHEEN = material.sheen > 0;
		var HAS_TRANSMISSION = material.transmission > 0;
		var HAS_ANISOTROPYMAP = HAS_ANISOTROPY && material.anisotropyMap != null;
		var HAS_CLEARCOATMAP = HAS_CLEARCOAT && material.clearcoatMap != null;
		var HAS_CLEARCOAT_NORMALMAP = HAS_CLEARCOAT && material.clearcoatNormalMap != null;
		var HAS_CLEARCOAT_ROUGHNESSMAP = HAS_CLEARCOAT && material.clearcoatRoughnessMap != null;
		var HAS_IRIDESCENCEMAP = HAS_IRIDESCENCE && material.iridescenceMap != null;
		var HAS_IRIDESCENCE_THICKNESSMAP = HAS_IRIDESCENCE && material.iridescenceThicknessMap != null;
		var HAS_SHEEN_COLORMAP = HAS_SHEEN && material.sheenColorMap != null;
		var HAS_SHEEN_ROUGHNESSMAP = HAS_SHEEN && material.sheenRoughnessMap != null;
		var HAS_SPECULARMAP = material.specularMap != null;
		var HAS_SPECULAR_COLORMAP = material.specularColorMap != null;
		var HAS_SPECULAR_INTENSITYMAP = material.specularIntensityMap != null;
		var HAS_TRANSMISSIONMAP = HAS_TRANSMISSION && material.transmissionMap != null;
		var HAS_THICKNESSMAP = HAS_TRANSMISSION && material.thicknessMap != null;
		var HAS_GRADIENTMAP = material.gradientMap != null;
		var HAS_ALPHAMAP = material.alphaMap != null;
		var HAS_ALPHATEST = material.alphaTest > 0;
		var HAS_ALPHAHASH = material.alphaHash != null;
		var HAS_EXTENSIONS = material.extensions != null;
		var toneMapping = NoToneMapping;
		if (material.toneMapped) {
			if (currentRenderTarget == null || currentRenderTarget.isXRRenderTarget == true) {
				toneMapping = this.renderer.toneMapping;
			}
		}
		var parameters = {
			shaderID: shaderID,
			shaderType: material.type,
			shaderName: material.name,
			vertexShader: vertexShader,
			fragmentShader: fragmentShader,
			defines: material.defines,
			customVertexShaderID: customVertexShaderID,
			customFragmentShaderID: customFragmentShaderID,
			isRawShaderMaterial: material.isRawShaderMaterial == true,
			glslVersion: material.glslVersion,
			precision: this.precision,
			batching: IS_BATCHEDMESH,
			batchingColor: IS_BATCHEDMESH && object._colorsTexture != null,
			instancing: IS_INSTANCEDMESH,
			instancingColor: IS_INSTANCEDMESH && object.instanceColor != null,
			instancingMorph: IS_INSTANCEDMESH && object.morphTexture != null,
			supportsVertexTextures: this.SUPPORTS_VERTEX_TEXTURES,
			outputColorSpace: (currentRenderTarget == null) ? this.renderer.outputColorSpace : (currentRenderTarget.isXRRenderTarget == true ? currentRenderTarget.texture.colorSpace : LinearSRGBColorSpace),
			alphaToCoverage: material.alphaToCoverage != null,
			map: HAS_MAP,
			matcap: HAS_MATCAP,
			envMap: HAS_ENVMAP,
			envMapMode: HAS_ENVMAP && envMap.mapping,
			envMapCubeUVHeight: envMapCubeUVHeight,
			aoMap: HAS_AOMAP,
			lightMap: HAS_LIGHTMAP,
			bumpMap: HAS_BUMPMAP,
			normalMap: HAS_NORMALMAP,
			displacementMap: HAS_DISPLACEMENTMAP,
			emissiveMap: HAS_EMISSIVEMAP,
			normalMapObjectSpace: HAS_NORMALMAP && material.normalMapType == ObjectSpaceNormalMap,
			normalMapTangentSpace: HAS_NORMALMAP && material.normalMapType == TangentSpaceNormalMap,
			metalnessMap: HAS_METALNESSMAP,
			roughnessMap: HAS_ROUGHNESSMAP,
			anisotropy: HAS_ANISOTROPY,
			anisotropyMap: HAS_ANISOTROPYMAP,
			clearcoat: HAS_CLEARCOAT,
			clearcoatMap: HAS_CLEARCOATMAP,
			clearcoatNormalMap: HAS_CLEARCOAT_NORMALMAP,
			clearcoatRoughnessMap: HAS_CLEARCOAT_ROUGHNESSMAP,
			dispersion: HAS_DISPERSION,
			iridescence: HAS_IRIDESCENCE,
			iridescenceMap: HAS_IRIDESCENCEMAP,
			iridescenceThicknessMap: HAS_IRIDESCENCE_THICKNESSMAP,
			sheen: HAS_SHEEN,
			sheenColorMap: HAS_SHEEN_COLORMAP,
			sheenRoughnessMap: HAS_SHEEN_ROUGHNESSMAP,
			specularMap: HAS_SPECULARMAP,
			specularColorMap: HAS_SPECULAR_COLORMAP,
			specularIntensityMap: HAS_SPECULAR_INTENSITYMAP,
			transmission: HAS_TRANSMISSION,
			transmissionMap: HAS_TRANSMISSIONMAP,
			thicknessMap: HAS_THICKNESSMAP,
			gradientMap: HAS_GRADIENTMAP,
			opaque: material.transparent == false && material.blending == NormalBlending && material.alphaToCoverage == false,
			alphaMap: HAS_ALPHAMAP,
			alphaTest: HAS_ALPHATEST,
			alphaHash: HAS_ALPHAHASH,
			combine: material.combine,
			mapUv: HAS_MAP && this.getChannel(material.map.channel),
			aoMapUv: HAS_AOMAP && this.getChannel(material.aoMap.channel),
			lightMapUv: HAS_LIGHTMAP && this.getChannel(material.lightMap.channel),
			bumpMapUv: HAS_BUMPMAP && this.getChannel(material.bumpMap.channel),
			normalMapUv: HAS_NORMALMAP && this.getChannel(material.normalMap.channel),
			displacementMapUv: HAS_DISPLACEMENTMAP && this.getChannel(material.displacementMap.channel),
			emissiveMapUv: HAS_EMISSIVEMAP && this.getChannel(material.emissiveMap.channel),
			metalnessMapUv: HAS_METALNESSMAP && this.getChannel(material.metalnessMap.channel),
			roughnessMapUv: HAS_ROUGHNESSMAP && this.getChannel(material.roughnessMap.channel),
			anisotropyMapUv: HAS_ANISOTROPYMAP && this.getChannel(material.anisotropyMap.channel),
			clearcoatMapUv: HAS_CLEARCOATMAP && this.getChannel(material.clearcoatMap.channel),
			clearcoatNormalMapUv: HAS_CLEARCOAT_NORMALMAP && this.getChannel(material.clearcoatNormalMap.channel),
			clearcoatRoughnessMapUv: HAS_CLEARCOAT_ROUGHNESSMAP && this.getChannel(material.clearcoatRoughnessMap.channel),
			iridescenceMapUv: HAS_IRIDESCENCEMAP && this.getChannel(material.iridescenceMap.channel),
			iridescenceThicknessMapUv: HAS_IRIDESCENCE_THICKNESSMAP && this.getChannel(material.iridescenceThicknessMap.channel),
			sheenColorMapUv: HAS_SHEEN_COLORMAP && this.getChannel(material.sheenColorMap.channel),
			sheenRoughnessMapUv: HAS_SHEEN_ROUGHNESSMAP && this.getChannel(material.sheenRoughnessMap.channel),
			specularMapUv: HAS_SPECULARMAP && this.getChannel(material.specularMap.channel),
			specularColorMapUv: HAS_SPECULAR_COLORMAP && this.getChannel(material.specularColorMap.channel),
			specularIntensityMapUv: HAS_SPECULAR_INTENSITYMAP && this.getChannel(material.specularIntensityMap.channel),
			transmissionMapUv: HAS_TRANSMISSIONMAP && this.getChannel(material.transmissionMap.channel),
			thicknessMapUv: HAS_THICKNESSMAP && this.getChannel(material.thicknessMap.channel),
			alphaMapUv: HAS_ALPHAMAP && this.getChannel(material.alphaMap.channel),
			vertexTangents: geometry.attributes.tangent != null && (HAS_NORMALMAP || HAS_ANISOTROPY),
			vertexColors: material.vertexColors,
			vertexAlphas: material.vertexColors == true && geometry.attributes.color != null && geometry.attributes.color.itemSize == 4,
			pointsUvs: object.isPoints == true && geometry.attributes.uv != null && (HAS_MAP || HAS_ALPHAMAP),
			fog: fog != null,
			useFog: material.fog == true,
			fogExp2: (fog != null && fog.isFogExp2),
			flatShading: material.flatShading == true,
			sizeAttenuation: material.sizeAttenuation == true,
			logarithmicDepthBuffer: this.logarithmicDepthBuffer,
			skinning: object.isSkinnedMesh == true,
			morphTargets: geometry.morphAttributes.position != null,
			morphNormals: geometry.morphAttributes.normal != null,
			morphColors: geometry.morphAttributes.color != null,
			morphTargetsCount: morphTargetsCount,
			morphTextureStride: morphTextureStride,
			numDirLights: lights.directional.length,
			numPointLights: lights.point.length,
			numSpotLights: lights.spot.length,
			numSpotLightMaps: lights.spotLightMap.length,
			numRectAreaLights: lights.rectArea.length,
			numHemiLights: lights.hemi.length,
			numDirLightShadows: lights.directionalShadowMap.length,
			numPointLightShadows: lights.pointShadowMap.length,
			numSpotLightShadows: lights.spotShadowMap.length,
			numSpotLightShadowsWithMaps: lights.numSpotLightShadowsWithMaps,
			numLightProbes: lights.numLightProbes,
			numClippingPlanes: this.clipping.numPlanes,
			numClipIntersection: this.clipping.numIntersection,
			dithering: material.dithering,
			shadowMapEnabled: this.renderer.shadowMap.enabled && shadows.length > 0,
			shadowMapType: this.renderer.shadowMap.type,
			toneMapping: toneMapping,
			useLegacyLights: this.renderer._useLegacyLights,
			decodeVideoTexture: HAS_MAP && (material.map.isVideoTexture == true) && (ColorManagement.getTransfer(material.map.colorSpace) == SRGBTransfer),
			premultipliedAlpha: material.premultipliedAlpha,
			doubleSided: material.side == DoubleSide,
			flipSided: material.side == BackSide,
			useDepthPacking: material.depthPacking >= 0,
			depthPacking: material.depthPacking || 0,
			index0AttributeName: material.index0AttributeName,
			extensionClipCullDistance: HAS_EXTENSIONS && material.extensions.clipCullDistance == true && this.extensions.has("WEBGL_clip_cull_distance"),
			extensionMultiDraw: HAS_EXTENSIONS && material.extensions.multiDraw == true && this.extensions.has("WEBGL_multi_draw"),
			rendererExtensionParallelShaderCompile: this.extensions.has("KHR_parallel_shader_compile"),
			customProgramCacheKey: material.customProgramCacheKey()
		};
		parameters.vertexUv1s = this._activeChannels.has(1);
		parameters.vertexUv2s = this._activeChannels.has(2);
		parameters.vertexUv3s = this._activeChannels.has(3);
		this._activeChannels.clear();
		return parameters;
	}

	public function getProgramCacheKey(parameters:Dynamic):String {
		var array = new Array<String>();
		if (parameters.shaderID != null) {
			array.push(parameters.shaderID);
		} else {
			array.push(parameters.customVertexShaderID);
			array.push(parameters.customFragmentShaderID);
		}
		if (parameters.defines != null) {
			for (name in parameters.defines) {
				array.push(name);
				array.push(parameters.defines[name]);
			}
		}
		if (parameters.isRawShaderMaterial == false) {
			this.getProgramCacheKeyParameters(array, parameters);
			this.getProgramCacheKeyBooleans(array, parameters);
			array.push(this.renderer.outputColorSpace);
		}
		array.push(parameters.customProgramCacheKey);
		return array.join("");
	}

	public function getProgramCacheKeyParameters(array:Array<String>, parameters:Dynamic):Void {
		array.push(parameters.precision);
		array.push(parameters.outputColorSpace);
		array.push(parameters.envMapMode);
		array.push(parameters.envMapCubeUVHeight);
		array.push(parameters.mapUv);
		array.push(parameters.alphaMapUv);
		array.push(parameters.lightMapUv);
		array.push(parameters.aoMapUv);
		array.push(parameters.bumpMapUv);
		array.push(parameters.normalMapUv);
		array.push(parameters.displacementMapUv);
		array.push(parameters.emissiveMapUv);
		array.push(parameters.metalnessMapUv);
		array.push(parameters.roughnessMapUv);
		array.push(parameters.anisotropyMapUv);
		array.push(parameters.clearcoatMapUv);
		array.push(parameters.clearcoatNormalMapUv);
		array.push(parameters.clearcoatRoughnessMapUv);
		array.push(parameters.iridescenceMapUv);
		array.push(parameters.iridescenceThicknessMapUv);
		array.push(parameters.sheenColorMapUv);
		array.push(parameters.sheenRoughnessMapUv);
		array.push(parameters.specularMapUv);
		array.push(parameters.specularColorMapUv);
		array.push(parameters.specularIntensityMapUv);
		array.push(parameters.transmissionMapUv);
		array.push(parameters.thicknessMapUv);
		array.push(parameters.combine);
		array.push(parameters.fogExp2);
		array.push(parameters.sizeAttenuation);
		array.push(parameters.morphTargetsCount);
		array.push(parameters.morphAttributeCount);
		array.push(parameters.numDirLights);
		array.push(parameters.numPointLights);
		array.push(parameters.numSpotLights);
		array.push(parameters.numSpotLightMaps);
		array.push(parameters.numHemiLights);
		array.push(parameters.numRectAreaLights);
		array.push(parameters.numDirLightShadows);
		array.push(parameters.numPointLightShadows);
		array.push(parameters.numSpotLightShadows);
		array.push(parameters.numSpotLightShadowsWithMaps);
		array.push(parameters.numLightProbes);
		array.push(parameters.shadowMapType);
		array.push(parameters.toneMapping);
		array.push(parameters.numClippingPlanes);
		array.push(parameters.numClipIntersection);
		array.push(parameters.depthPacking);
	}

	public function getProgramCacheKeyBooleans(array:Array<String>, parameters:Dynamic):Void {
		this._programLayers.disableAll();
		if (parameters.supportsVertexTextures) this._programLayers.enable(0);
		if (parameters.instancing) this._programLayers.enable(1);
		if (parameters.instancingColor) this._programLayers.enable(2);
		if (parameters.instancingMorph) this._programLayers.enable(3);
		if (parameters.matcap) this._programLayers.enable(4);
		if (parameters.envMap) this._programLayers.enable(5);
		if (parameters.normalMapObjectSpace) this._programLayers.enable(6);
		if (parameters.normalMapTangentSpace) this._programLayers.enable(7);
		if (parameters.clearcoat) this._programLayers.enable(8);
		if (parameters.iridescence) this._programLayers.enable(9);
		if (parameters.alphaTest) this._programLayers.enable(10);
		if (parameters.vertexColors) this._programLayers.enable(11);
		if (parameters.vertexAlphas) this._programLayers.enable(12);
		if (parameters.vertexUv1s) this._programLayers.enable(13);
		if (parameters.vertexUv2s) this._programLayers.enable(14);
		if (parameters.vertexUv3s) this._programLayers.enable(15);
		if (parameters.vertexTangents) this._programLayers.enable(16);
		if (parameters.anisotropy) this._programLayers.enable(17);
		if (parameters.alphaHash) this._programLayers.enable(18);
		if (parameters.batching) this._programLayers.enable(19);
		if (parameters.dispersion) this._programLayers.enable(20);
		if (parameters.batchingColor) this._programLayers.enable(21);
		array.push(this._programLayers.mask);
		this._programLayers.disableAll();
		if (parameters.fog) this._programLayers.enable(0);
		if (parameters.useFog) this._programLayers.enable(1);
		if (parameters.flatShading) this._programLayers.enable(2);
		if (parameters.logarithmicDepthBuffer) this._programLayers.enable(3);
		if (parameters.skinning) this._programLayers.enable(4);
		if (parameters.morphTargets) this._programLayers.enable(5);
		if (parameters.morphNormals) this._programLayers.enable(6);
		if (parameters.morphColors) this._programLayers.enable(7);
		if (parameters.premultipliedAlpha) this._programLayers.enable(8);
		if (parameters.shadowMapEnabled) this._programLayers.enable(9);
		if (parameters.useLegacyLights) this._programLayers.enable(10);
		if (parameters.doubleSided) this._programLayers.enable(11);
		if (parameters.flipSided) this._programLayers.enable(12);
		if (parameters.useDepthPacking) this._programLayers.enable(13);
		if (parameters.dithering) this._programLayers.enable(14);
		if (parameters.transmission) this._programLayers.enable(15);
		if (parameters.sheen) this._programLayers.enable(16);
		if (parameters.opaque) this._programLayers.enable(17);
		if (parameters.pointsUvs) this._programLayers.enable(18);
		if (parameters.decodeVideoTexture) this._programLayers.enable(19);
		if (parameters.alphaToCoverage) this._programLayers.enable(20);
		array.push(this._programLayers.mask);
	}

	public function getUniforms(material:Dynamic):Dynamic {
		var shaderID = this.shaderIDs[material.type];
		var uniforms:Dynamic;
		if (shaderID != null) {
			var shader = ShaderLib[shaderID];
			uniforms = UniformsUtils.clone(shader.uniforms);
		} else {
			uniforms = material.uniforms;
		}
		return uniforms;
	}

	public function acquireProgram(parameters:Dynamic, cacheKey:String):WebGLProgram {
		var program:WebGLProgram;
		for (p in 0...this.programs.length) {
			var preexistingProgram = this.programs[p];
			if (preexistingProgram.cacheKey == cacheKey) {
				program = preexistingProgram;
				++program.usedTimes;
				break;
			}
		}
		if (program == null) {
			program = new WebGLProgram(this.renderer, cacheKey, parameters, this.bindingStates);
			this.programs.push(program);
		}
		return program;
	}

	public function releaseProgram(program:WebGLProgram):Void {
		if (--program.usedTimes == 0) {
			var i = this.programs.indexOf(program);
			this.programs[i] = this.programs[this.programs.length - 1];
			this.programs.pop();
			program.destroy();
		}
	}

	public function releaseShaderCache(material:Dynamic):Void {
		this._customShaders.remove(material);
	}

	public function dispose():Void {
		this._customShaders.dispose();
	}

}