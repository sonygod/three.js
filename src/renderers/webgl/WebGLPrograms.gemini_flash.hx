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
	
	private var _programLayers:Layers;
	private var _customShaders:WebGLShaderCache;
	private var _activeChannels:haxe.ds.Set<Int>;
	private var programs:Array<WebGLProgram>;
	
	private var logarithmicDepthBuffer:Bool;
	private var SUPPORTS_VERTEX_TEXTURES:Bool;
	
	private var precision:String;
	
	private var shaderIDs:Map<String, String>;
	
	public function new(renderer, cubemaps, cubeuvmaps, extensions, capabilities, bindingStates, clipping) {
		
		this._programLayers = new Layers();
		this._customShaders = new WebGLShaderCache();
		this._activeChannels = new haxe.ds.Set();
		this.programs = [];
		
		this.logarithmicDepthBuffer = capabilities.logarithmicDepthBuffer;
		this.SUPPORTS_VERTEX_TEXTURES = capabilities.vertexTextures;
		
		this.precision = capabilities.precision;
		
		this.shaderIDs = new Map<String, String>({
			'MeshDepthMaterial': 'depth',
			'MeshDistanceMaterial': 'distanceRGBA',
			'MeshNormalMaterial': 'normal',
			'MeshBasicMaterial': 'basic',
			'MeshLambertMaterial': 'lambert',
			'MeshPhongMaterial': 'phong',
			'MeshToonMaterial': 'toon',
			'MeshStandardMaterial': 'physical',
			'MeshPhysicalMaterial': 'physical',
			'MeshMatcapMaterial': 'matcap',
			'LineBasicMaterial': 'basic',
			'LineDashedMaterial': 'dashed',
			'PointsMaterial': 'points',
			'ShadowMaterial': 'shadow',
			'SpriteMaterial': 'sprite'
		});
		
	}
	
	private function getChannel(value:Int):String {
		
		_activeChannels.add(value);
		
		if (value == 0) return 'uv';
		
		return 'uv' + value;
		
	}
	
	private function getParameters(material, lights, shadows, scene, object) {
		
		var fog = scene.fog;
		var geometry = object.geometry;
		var environment = material.isMeshStandardMaterial ? scene.environment : null;
		
		var envMap = (material.isMeshStandardMaterial ? cubeuvmaps : cubemaps).get(material.envMap || environment);
		var envMapCubeUVHeight:Int = (envMap != null) && (envMap.mapping == CubeUVReflectionMapping) ? envMap.image.height : null;
		
		var shaderID = shaderIDs.get(material.type);
		
		// heuristics to create shader parameters according to lights in the scene
		// (not to blow over maxLights budget)
		
		if (material.precision != null) {
			
			precision = capabilities.getMaxPrecision(material.precision);
			
			if (precision != material.precision) {
				
				Sys.println('THREE.WebGLProgram.getParameters: ' + material.precision + ' not supported, using ' + precision + ' instead.');
				
			}
			
		}
		
		//
		
		var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
		var morphTargetsCount = (morphAttribute != null) ? morphAttribute.length : 0;
		
		var morphTextureStride:Int = 0;
		
		if (geometry.morphAttributes.position != null) morphTextureStride = 1;
		if (geometry.morphAttributes.normal != null) morphTextureStride = 2;
		if (geometry.morphAttributes.color != null) morphTextureStride = 3;
		
		//
		
		var vertexShader:String;
		var fragmentShader:String;
		var customVertexShaderID:String;
		var customFragmentShaderID:String;
		
		if (shaderID != null) {
			
			var shader = ShaderLib.get(shaderID);
			
			vertexShader = shader.vertexShader;
			fragmentShader = shader.fragmentShader;
			
		} else {
			
			vertexShader = material.vertexShader;
			fragmentShader = material.fragmentShader;
			
			_customShaders.update(material);
			
			customVertexShaderID = _customShaders.getVertexShaderID(material);
			customFragmentShaderID = _customShaders.getFragmentShaderID(material);
			
		}
		
		var currentRenderTarget = renderer.getRenderTarget();
		
		var IS_INSTANCEDMESH = object.isInstancedMesh;
		var IS_BATCHEDMESH = object.isBatchedMesh;
		
		var HAS_MAP = material.map != null;
		var HAS_MATCAP = material.matcap != null;
		var HAS_ENVMAP = envMap != null;
		var HAS_AOMAP = material.aoMap != null;
		var HAS_LIGHTMAP = material.lightMap != null;
		var HAS_BUMPMAP = material.bumpMap != null;
		var HAS_NORMALMAP = material.normalMap != null;
		var HAS_DISPLACEMENTMAP = SUPPORTS_VERTEX_TEXTURES && material.displacementMap != null;
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
		
		var toneMapping:Int = NoToneMapping;
		
		if (material.toneMapped) {
			
			if (currentRenderTarget == null || currentRenderTarget.isXRRenderTarget) {
				
				toneMapping = renderer.toneMapping;
				
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
			
			isRawShaderMaterial: material.isRawShaderMaterial,
			glslVersion: material.glslVersion,
			
			precision: precision,
			
			batching: IS_BATCHEDMESH,
			batchingColor: IS_BATCHEDMESH && object._colorsTexture != null,
			instancing: IS_INSTANCEDMESH,
			instancingColor: IS_INSTANCEDMESH && object.instanceColor != null,
			instancingMorph: IS_INSTANCEDMESH && object.morphTexture != null,
			
			supportsVertexTextures: SUPPORTS_VERTEX_TEXTURES,
			outputColorSpace: (currentRenderTarget == null) ? renderer.outputColorSpace : (currentRenderTarget.isXRRenderTarget ? currentRenderTarget.texture.colorSpace : LinearSRGBColorSpace),
			alphaToCoverage: material.alphaToCoverage,
			
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
			
			//
			
			mapUv: HAS_MAP && getChannel(material.map.channel),
			aoMapUv: HAS_AOMAP && getChannel(material.aoMap.channel),
			lightMapUv: HAS_LIGHTMAP && getChannel(material.lightMap.channel),
			bumpMapUv: HAS_BUMPMAP && getChannel(material.bumpMap.channel),
			normalMapUv: HAS_NORMALMAP && getChannel(material.normalMap.channel),
			displacementMapUv: HAS_DISPLACEMENTMAP && getChannel(material.displacementMap.channel),
			emissiveMapUv: HAS_EMISSIVEMAP && getChannel(material.emissiveMap.channel),
			
			metalnessMapUv: HAS_METALNESSMAP && getChannel(material.metalnessMap.channel),
			roughnessMapUv: HAS_ROUGHNESSMAP && getChannel(material.roughnessMap.channel),
			
			anisotropyMapUv: HAS_ANISOTROPYMAP && getChannel(material.anisotropyMap.channel),
			
			clearcoatMapUv: HAS_CLEARCOATMAP && getChannel(material.clearcoatMap.channel),
			clearcoatNormalMapUv: HAS_CLEARCOAT_NORMALMAP && getChannel(material.clearcoatNormalMap.channel),
			clearcoatRoughnessMapUv: HAS_CLEARCOAT_ROUGHNESSMAP && getChannel(material.clearcoatRoughnessMap.channel),
			
			iridescenceMapUv: HAS_IRIDESCENCEMAP && getChannel(material.iridescenceMap.channel),
			iridescenceThicknessMapUv: HAS_IRIDESCENCE_THICKNESSMAP && getChannel(material.iridescenceThicknessMap.channel),
			
			sheenColorMapUv: HAS_SHEEN_COLORMAP && getChannel(material.sheenColorMap.channel),
			sheenRoughnessMapUv: HAS_SHEEN_ROUGHNESSMAP && getChannel(material.sheenRoughnessMap.channel),
			
			specularMapUv: HAS_SPECULARMAP && getChannel(material.specularMap.channel),
			specularColorMapUv: HAS_SPECULAR_COLORMAP && getChannel(material.specularColorMap.channel),
			specularIntensityMapUv: HAS_SPECULAR_INTENSITYMAP && getChannel(material.specularIntensityMap.channel),
			
			transmissionMapUv: HAS_TRANSMISSIONMAP && getChannel(material.transmissionMap.channel),
			thicknessMapUv: HAS_THICKNESSMAP && getChannel(material.thicknessMap.channel),
			
			alphaMapUv: HAS_ALPHAMAP && getChannel(material.alphaMap.channel),
			
			//
			
			vertexTangents: geometry.attributes.tangent != null && (HAS_NORMALMAP || HAS_ANISOTROPY),
			vertexColors: material.vertexColors,
			vertexAlphas: material.vertexColors && geometry.attributes.color != null && geometry.attributes.color.itemSize == 4,
			
			pointsUvs: object.isPoints && geometry.attributes.uv != null && (HAS_MAP || HAS_ALPHAMAP),
			
			fog: fog != null,
			useFog: material.fog,
			fogExp2: fog != null && fog.isFogExp2,
			
			flatShading: material.flatShading,
			
			sizeAttenuation: material.sizeAttenuation,
			logarithmicDepthBuffer: logarithmicDepthBuffer,
			
			skinning: object.isSkinnedMesh,
			
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
			
			numClippingPlanes: clipping.numPlanes,
			numClipIntersection: clipping.numIntersection,
			
			dithering: material.dithering,
			
			shadowMapEnabled: renderer.shadowMap.enabled && shadows.length > 0,
			shadowMapType: renderer.shadowMap.type,
			
			toneMapping: toneMapping,
			useLegacyLights: renderer._useLegacyLights,
			
			decodeVideoTexture: HAS_MAP && (material.map.isVideoTexture && (ColorManagement.getTransfer(material.map.colorSpace) == SRGBTransfer)),
			
			premultipliedAlpha: material.premultipliedAlpha,
			
			doubleSided: material.side == DoubleSide,
			flipSided: material.side == BackSide,
			
			useDepthPacking: material.depthPacking >= 0,
			depthPacking: material.depthPacking,
			
			index0AttributeName: material.index0AttributeName,
			
			extensionClipCullDistance: HAS_EXTENSIONS && material.extensions.clipCullDistance && extensions.has('WEBGL_clip_cull_distance'),
			extensionMultiDraw: HAS_EXTENSIONS && material.extensions.multiDraw && extensions.has('WEBGL_multi_draw'),
			
			rendererExtensionParallelShaderCompile: extensions.has('KHR_parallel_shader_compile'),
			
			customProgramCacheKey: material.customProgramCacheKey()
			
		};
		
		// the usage of getChannel() determines the active texture channels for this shader
		
		parameters.vertexUv1s = _activeChannels.has(1);
		parameters.vertexUv2s = _activeChannels.has(2);
		parameters.vertexUv3s = _activeChannels.has(3);
		
		_activeChannels.clear();
		
		return parameters;
		
	}
	
	private function getProgramCacheKey(parameters) {
		
		var array:Array<String> = [];
		
		if (parameters.shaderID != null) {
			
			array.push(parameters.shaderID);
			
		} else {
			
			array.push(parameters.customVertexShaderID);
			array.push(parameters.customFragmentShaderID);
			
		}
		
		if (parameters.defines != null) {
			
			for (name in parameters.defines) {
				
				array.push(name);
				array.push(parameters.defines.get(name));
				
			}
			
		}
		
		if (parameters.isRawShaderMaterial == false) {
			
			getProgramCacheKeyParameters(array, parameters);
			getProgramCacheKeyBooleans(array, parameters);
			array.push(renderer.outputColorSpace);
			
		}
		
		array.push(parameters.customProgramCacheKey);
		
		return array.join('');
		
	}
	
	private function getProgramCacheKeyParameters(array:Array<String>, parameters) {
		
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
	
	private function getProgramCacheKeyBooleans(array:Array<String>, parameters) {
		
		_programLayers.disableAll();
		
		if (parameters.supportsVertexTextures) _programLayers.enable(0);
		if (parameters.instancing) _programLayers.enable(1);
		if (parameters.instancingColor) _programLayers.enable(2);
		if (parameters.instancingMorph) _programLayers.enable(3);
		if (parameters.matcap) _programLayers.enable(4);
		if (parameters.envMap) _programLayers.enable(5);
		if (parameters.normalMapObjectSpace) _programLayers.enable(6);
		if (parameters.normalMapTangentSpace) _programLayers.enable(7);
		if (parameters.clearcoat) _programLayers.enable(8);
		if (parameters.iridescence) _programLayers.enable(9);
		if (parameters.alphaTest) _programLayers.enable(10);
		if (parameters.vertexColors) _programLayers.enable(11);
		if (parameters.vertexAlphas) _programLayers.enable(12);
		if (parameters.vertexUv1s) _programLayers.enable(13);
		if (parameters.vertexUv2s) _programLayers.enable(14);
		if (parameters.vertexUv3s) _programLayers.enable(15);
		if (parameters.vertexTangents) _programLayers.enable(16);
		if (parameters.anisotropy) _programLayers.enable(17);
		if (parameters.alphaHash) _programLayers.enable(18);
		if (parameters.batching) _programLayers.enable(19);
		if (parameters.dispersion) _programLayers.enable(20);
		if (parameters.batchingColor) _programLayers.enable(21);
		
		array.push(_programLayers.mask);
		_programLayers.disableAll();
		
		if (parameters.fog) _programLayers.enable(0);
		if (parameters.useFog) _programLayers.enable(1);
		if (parameters.flatShading) _programLayers.enable(2);
		if (parameters.logarithmicDepthBuffer) _programLayers.enable(3);
		if (parameters.skinning) _programLayers.enable(4);
		if (parameters.morphTargets) _programLayers.enable(5);
		if (parameters.morphNormals) _programLayers.enable(6);
		if (parameters.morphColors) _programLayers.enable(7);
		if (parameters.premultipliedAlpha) _programLayers.enable(8);
		if (parameters.shadowMapEnabled) _programLayers.enable(9);
		if (parameters.useLegacyLights) _programLayers.enable(10);
		if (parameters.doubleSided) _programLayers.enable(11);
		if (parameters.flipSided) _programLayers.enable(12);
		if (parameters.useDepthPacking) _programLayers.enable(13);
		if (parameters.dithering) _programLayers.enable(14);
		if (parameters.transmission) _programLayers.enable(15);
		if (parameters.sheen) _programLayers.enable(16);
		if (parameters.opaque) _programLayers.enable(17);
		if (parameters.pointsUvs) _programLayers.enable(18);
		if (parameters.decodeVideoTexture) _programLayers.enable(19);
		if (parameters.alphaToCoverage) _programLayers.enable(20);
		
		array.push(_programLayers.mask);
		
	}
	
	private function getUniforms(material) {
		
		var shaderID = shaderIDs.get(material.type);
		var uniforms:Dynamic;
		
		if (shaderID != null) {
			
			var shader = ShaderLib.get(shaderID);
			uniforms = UniformsUtils.clone(shader.uniforms);
			
		} else {
			
			uniforms = material.uniforms;
			
		}
		
		return uniforms;
		
	}
	
	public function acquireProgram(parameters, cacheKey:String) {
		
		var program:WebGLProgram;
		
		// Check if code has been already compiled
		for (p in 0...programs.length) {
			
			var preexistingProgram = programs[p];
			
			if (preexistingProgram.cacheKey == cacheKey) {
				
				program = preexistingProgram;
				program.usedTimes++;
				
				break;
				
			}
			
		}
		
		if (program == null) {
			
			program = new WebGLProgram(renderer, cacheKey, parameters, bindingStates);
			programs.push(program);
			
		}
		
		return program;
		
	}
	
	public function releaseProgram(program:WebGLProgram) {
		
		if (--program.usedTimes == 0) {
			
			// Remove from unordered set
			var i = programs.indexOf(program);
			programs[i] = programs[programs.length - 1];
			programs.pop();
			
			// Free WebGL resources
			program.destroy();
			
		}
		
	}
	
	public function releaseShaderCache(material) {
		
		_customShaders.remove(material);
		
	}
	
	public function dispose() {
		
		_customShaders.dispose();
		
	}
	
	public var getParameters = getParameters;
	public var getProgramCacheKey = getProgramCacheKey;
	public var getUniforms = getUniforms;
	public var acquireProgram = acquireProgram;
	public var releaseProgram = releaseProgram;
	public var releaseShaderCache = releaseShaderCache;
	// Exposed for resource monitoring & error feedback via renderer.info:
	public var programs:Array<WebGLProgram>;
	public var dispose:Void->Void = dispose;
	
}