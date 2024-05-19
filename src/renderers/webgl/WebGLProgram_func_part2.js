function WebGLProgram( renderer, cacheKey, parameters, bindingStates ) {

	// TODO Send this event to Three.js DevTools
	// console.log( 'WebGLProgram', cacheKey );

	const gl = renderer.getContext();

	const defines = parameters.defines;

	let vertexShader = parameters.vertexShader;
	let fragmentShader = parameters.fragmentShader;

	const shadowMapTypeDefine = generateShadowMapTypeDefine( parameters );
	const envMapTypeDefine = generateEnvMapTypeDefine( parameters );
	const envMapModeDefine = generateEnvMapModeDefine( parameters );
	const envMapBlendingDefine = generateEnvMapBlendingDefine( parameters );
	const envMapCubeUVSize = generateCubeUVSize( parameters );

	const customVertexExtensions = generateVertexExtensions( parameters );

	const customDefines = generateDefines( defines );

	const program = gl.createProgram();

	let prefixVertex, prefixFragment;
	let versionString = parameters.glslVersion ? '#version ' + parameters.glslVersion + '\n' : '';

	if ( parameters.isRawShaderMaterial ) {

		prefixVertex = [

			'#define SHADER_TYPE ' + parameters.shaderType,
			'#define SHADER_NAME ' + parameters.shaderName,

			customDefines

		].filter( filterEmptyLine ).join( '\n' );

		if ( prefixVertex.length > 0 ) {

			prefixVertex += '\n';

		}

		prefixFragment = [

			'#define SHADER_TYPE ' + parameters.shaderType,
			'#define SHADER_NAME ' + parameters.shaderName,

			customDefines

		].filter( filterEmptyLine ).join( '\n' );

		if ( prefixFragment.length > 0 ) {

			prefixFragment += '\n';

		}

	} else {

		prefixVertex = [

			generatePrecision( parameters ),

			'#define SHADER_TYPE ' + parameters.shaderType,
			'#define SHADER_NAME ' + parameters.shaderName,

			customDefines,

			parameters.extensionClipCullDistance ? '#define USE_CLIP_DISTANCE' : '',
			parameters.batching ? '#define USE_BATCHING' : '',
			parameters.batchingColor ? '#define USE_BATCHING_COLOR' : '',
			parameters.instancing ? '#define USE_INSTANCING' : '',
			parameters.instancingColor ? '#define USE_INSTANCING_COLOR' : '',
			parameters.instancingMorph ? '#define USE_INSTANCING_MORPH' : '',

			parameters.useFog && parameters.fog ? '#define USE_FOG' : '',
			parameters.useFog && parameters.fogExp2 ? '#define FOG_EXP2' : '',

			parameters.map ? '#define USE_MAP' : '',
			parameters.envMap ? '#define USE_ENVMAP' : '',
			parameters.envMap ? '#define ' + envMapModeDefine : '',
			parameters.lightMap ? '#define USE_LIGHTMAP' : '',
			parameters.aoMap ? '#define USE_AOMAP' : '',
			parameters.bumpMap ? '#define USE_BUMPMAP' : '',
			parameters.normalMap ? '#define USE_NORMALMAP' : '',
			parameters.normalMapObjectSpace ? '#define USE_NORMALMAP_OBJECTSPACE' : '',
			parameters.normalMapTangentSpace ? '#define USE_NORMALMAP_TANGENTSPACE' : '',
			parameters.displacementMap ? '#define USE_DISPLACEMENTMAP' : '',
			parameters.emissiveMap ? '#define USE_EMISSIVEMAP' : '',

			parameters.anisotropy ? '#define USE_ANISOTROPY' : '',
			parameters.anisotropyMap ? '#define USE_ANISOTROPYMAP' : '',

			parameters.clearcoatMap ? '#define USE_CLEARCOATMAP' : '',
			parameters.clearcoatRoughnessMap ? '#define USE_CLEARCOAT_ROUGHNESSMAP' : '',
			parameters.clearcoatNormalMap ? '#define USE_CLEARCOAT_NORMALMAP' : '',

			parameters.iridescenceMap ? '#define USE_IRIDESCENCEMAP' : '',
			parameters.iridescenceThicknessMap ? '#define USE_IRIDESCENCE_THICKNESSMAP' : '',

			parameters.specularMap ? '#define USE_SPECULARMAP' : '',
			parameters.specularColorMap ? '#define USE_SPECULAR_COLORMAP' : '',
			parameters.specularIntensityMap ? '#define USE_SPECULAR_INTENSITYMAP' : '',

			parameters.roughnessMap ? '#define USE_ROUGHNESSMAP' : '',
			parameters.metalnessMap ? '#define USE_METALNESSMAP' : '',
			parameters.alphaMap ? '#define USE_ALPHAMAP' : '',
			parameters.alphaHash ? '#define USE_ALPHAHASH' : '',

			parameters.transmission ? '#define USE_TRANSMISSION' : '',
			parameters.transmissionMap ? '#define USE_TRANSMISSIONMAP' : '',
			parameters.thicknessMap ? '#define USE_THICKNESSMAP' : '',

			parameters.sheenColorMap ? '#define USE_SHEEN_COLORMAP' : '',
			parameters.sheenRoughnessMap ? '#define USE_SHEEN_ROUGHNESSMAP' : '',

			//

			parameters.mapUv ? '#define MAP_UV ' + parameters.mapUv : '',
			parameters.alphaMapUv ? '#define ALPHAMAP_UV ' + parameters.alphaMapUv : '',
			parameters.lightMapUv ? '#define LIGHTMAP_UV ' + parameters.lightMapUv : '',
			parameters.aoMapUv ? '#define AOMAP_UV ' + parameters.aoMapUv : '',
			parameters.emissiveMapUv ? '#define EMISSIVEMAP_UV ' + parameters.emissiveMapUv : '',
			parameters.bumpMapUv ? '#define BUMPMAP_UV ' + parameters.bumpMapUv : '',
			parameters.normalMapUv ? '#define NORMALMAP_UV ' + parameters.normalMapUv : '',
			parameters.displacementMapUv ? '#define DISPLACEMENTMAP_UV ' + parameters.displacementMapUv : '',

			parameters.metalnessMapUv ? '#define METALNESSMAP_UV ' + parameters.metalnessMapUv : '',
			parameters.roughnessMapUv ? '#define ROUGHNESSMAP_UV ' + parameters.roughnessMapUv : '',

			parameters.anisotropyMapUv ? '#define ANISOTROPYMAP_UV ' + parameters.anisotropyMapUv : '',

			parameters.clearcoatMapUv ? '#define CLEARCOATMAP_UV ' + parameters.clearcoatMapUv : '',
			parameters.clearcoatNormalMapUv ? '#define CLEARCOAT_NORMALMAP_UV ' + parameters.clearcoatNormalMapUv : '',
			parameters.clearcoatRoughnessMapUv ? '#define CLEARCOAT_ROUGHNESSMAP_UV ' + parameters.clearcoatRoughnessMapUv : '',

			parameters.iridescenceMapUv ? '#define IRIDESCENCEMAP_UV ' + parameters.iridescenceMapUv : '',
			parameters.iridescenceThicknessMapUv ? '#define IRIDESCENCE_THICKNESSMAP_UV ' + parameters.iridescenceThicknessMapUv : '',

			parameters.sheenColorMapUv ? '#define SHEEN_COLORMAP_UV ' + parameters.sheenColorMapUv : '',
			parameters.sheenRoughnessMapUv ? '#define SHEEN_ROUGHNESSMAP_UV ' + parameters.sheenRoughnessMapUv : '',

			parameters.specularMapUv ? '#define SPECULARMAP_UV ' + parameters.specularMapUv : '',
			parameters.specularColorMapUv ? '#define SPECULAR_COLORMAP_UV ' + parameters.specularColorMapUv : '',
			parameters.specularIntensityMapUv ? '#define SPECULAR_INTENSITYMAP_UV ' + parameters.specularIntensityMapUv : '',

			parameters.transmissionMapUv ? '#define TRANSMISSIONMAP_UV ' + parameters.transmissionMapUv : '',
			parameters.thicknessMapUv ? '#define THICKNESSMAP_UV ' + parameters.thicknessMapUv : '',

			//

			parameters.vertexTangents && parameters.flatShading === false ? '#define USE_TANGENT' : '',
			parameters.vertexColors ? '#define USE_COLOR' : '',
			parameters.vertexAlphas ? '#define USE_COLOR_ALPHA' : '',
			parameters.vertexUv1s ? '#define USE_UV1' : '',
			parameters.vertexUv2s ? '#define USE_UV2' : '',
			parameters.vertexUv3s ? '#define USE_UV3' : '',

			parameters.pointsUvs ? '#define USE_POINTS_UV' : '',

			parameters.flatShading ? '#define FLAT_SHADED' : '',

			parameters.skinning ? '#define USE_SKINNING' : '',

			parameters.morphTargets ? '#define USE_MORPHTARGETS' : '',
			parameters.morphNormals && parameters.flatShading === false ? '#define USE_MORPHNORMALS' : '',
			( parameters.morphColors ) ? '#define USE_MORPHCOLORS' : '',
			( parameters.morphTargetsCount > 0 ) ? '#define MORPHTARGETS_TEXTURE_STRIDE ' + parameters.morphTextureStride : '',
			( parameters.morphTargetsCount > 0 ) ? '#define MORPHTARGETS_COUNT ' + parameters.morphTargetsCount : '',
			parameters.doubleSided ? '#define DOUBLE_SIDED' : '',
			parameters.flipSided ? '#define FLIP_SIDED' : '',

			parameters.shadowMapEnabled ? '#define USE_SHADOWMAP' : '',
			parameters.shadowMapEnabled ? '#define ' + shadowMapTypeDefine : '',

			parameters.sizeAttenuation ? '#define USE_SIZEATTENUATION' : '',

			parameters.numLightProbes > 0 ? '#define USE_LIGHT_PROBES' : '',

			parameters.useLegacyLights ? '#define LEGACY_LIGHTS' : '',

			parameters.logarithmicDepthBuffer ? '#define USE_LOGDEPTHBUF' : '',

			'uniform mat4 modelMatrix;',
			'uniform mat4 modelViewMatrix;',
			'uniform mat4 projectionMatrix;',
			'uniform mat4 viewMatrix;',
			'uniform mat3 normalMatrix;',
			'uniform vec3 cameraPosition;',
			'uniform bool isOrthographic;',

			'#ifdef USE_INSTANCING',

			'	attribute mat4 instanceMatrix;',

			'#endif',

			'#ifdef USE_INSTANCING_COLOR',

			'	attribute vec3 instanceColor;',

			'#endif',

			'#ifdef USE_INSTANCING_MORPH',

			'	uniform sampler2D morphTexture;',

			'#endif',

			'attribute vec3 position;',
			'attribute vec3 normal;',
			'attribute vec2 uv;',

			'#ifdef USE_UV1',

			'	attribute vec2 uv1;',

			'#endif',

			'#ifdef USE_UV2',

			'	attribute vec2 uv2;',

			'#endif',

			'#ifdef USE_UV3',

			'	attribute vec2 uv3;',

			'#endif',

			'#ifdef USE_TANGENT',

			'	attribute vec4 tangent;',

			'#endif',

			'#if defined( USE_COLOR_ALPHA )',

			'	attribute vec4 color;',

			'#elif defined( USE_COLOR )',

			'	attribute vec3 color;',

			'#endif',

			'#ifdef USE_SKINNING',

			'	attribute vec4 skinIndex;',
			'	attribute vec4 skinWeight;',

			'#endif',

			'\n'

		].filter( filterEmptyLine ).join( '\n' );

		prefixFragment = [

			generatePrecision( parameters ),

			'#define SHADER_TYPE ' + parameters.shaderType,
			'#define SHADER_NAME ' + parameters.shaderName,

			customDefines,

			parameters.useFog && parameters.fog ? '#define USE_FOG' : '',
			parameters.useFog && parameters.fogExp2 ? '#define FOG_EXP2' : '',

			parameters.alphaToCoverage ? '#define ALPHA_TO_COVERAGE' : '',
			parameters.map ? '#define USE_MAP' : '',
			parameters.matcap ? '#define USE_MATCAP' : '',
			parameters.envMap ? '#define USE_ENVMAP' : '',
			parameters.envMap ? '#define ' + envMapTypeDefine : '',
			parameters.envMap ? '#define ' + envMapModeDefine : '',
			parameters.envMap ? '#define ' + envMapBlendingDefine : '',
			envMapCubeUVSize ? '#define CUBEUV_TEXEL_WIDTH ' + envMapCubeUVSize.texelWidth : '',
			envMapCubeUVSize ? '#define CUBEUV_TEXEL_HEIGHT ' + envMapCubeUVSize.texelHeight : '',
			envMapCubeUVSize ? '#define CUBEUV_MAX_MIP ' + envMapCubeUVSize.maxMip + '.0' : '',
			parameters.lightMap ? '#define USE_LIGHTMAP' : '',
			parameters.aoMap ? '#define USE_AOMAP' : '',
			parameters.bumpMap ? '#define USE_BUMPMAP' : '',
			parameters.normalMap ? '#define USE_NORMALMAP' : '',
			parameters.normalMapObjectSpace ? '#define USE_NORMALMAP_OBJECTSPACE' : '',
			parameters.normalMapTangentSpace ? '#define USE_NORMALMAP_TANGENTSPACE' : '',
			parameters.emissiveMap ? '#define USE_EMISSIVEMAP' : '',

			parameters.anisotropy ? '#define USE_ANISOTROPY' : '',
			parameters.anisotropyMap ? '#define USE_ANISOTROPYMAP' : '',

			parameters.clearcoat ? '#define USE_CLEARCOAT' : '',
			parameters.clearcoatMap ? '#define USE_CLEARCOATMAP' : '',
			parameters.clearcoatRoughnessMap ? '#define USE_CLEARCOAT_ROUGHNESSMAP' : '',
			parameters.clearcoatNormalMap ? '#define USE_CLEARCOAT_NORMALMAP' : '',

			parameters.dispersion ? '#define USE_DISPERSION' : '',

			parameters.iridescence ? '#define USE_IRIDESCENCE' : '',
			parameters.iridescenceMap ? '#define USE_IRIDESCENCEMAP' : '',
			parameters.iridescenceThicknessMap ? '#define USE_IRIDESCENCE_THICKNESSMAP' : '',

			parameters.specularMap ? '#define USE_SPECULARMAP' : '',
			parameters.specularColorMap ? '#define USE_SPECULAR_COLORMAP' : '',
			parameters.specularIntensityMap ? '#define USE_SPECULAR_INTENSITYMAP' : '',

			parameters.roughnessMap ? '#define USE_ROUGHNESSMAP' : '',
			parameters.metalnessMap ? '#define USE_METALNESSMAP' : '',

			parameters.alphaMap ? '#define USE_ALPHAMAP' : '',
			parameters.alphaTest ? '#define USE_ALPHATEST' : '',
			parameters.alphaHash ? '#define USE_ALPHAHASH' : '',

			parameters.sheen ? '#define USE_SHEEN' : '',
			parameters.sheenColorMap ? '#define USE_SHEEN_COLORMAP' : '',
			parameters.sheenRoughnessMap ? '#define USE_SHEEN_ROUGHNESSMAP' : '',

			parameters.transmission ? '#define USE_TRANSMISSION' : '',
			parameters.transmissionMap ? '#define USE_TRANSMISSIONMAP' : '',
			parameters.thicknessMap ? '#define USE_THICKNESSMAP' : '',

			parameters.vertexTangents && parameters.flatShading === false ? '#define USE_TANGENT' : '',
			parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? '#define USE_COLOR' : '',
			parameters.vertexAlphas ? '#define USE_COLOR_ALPHA' : '',
			parameters.vertexUv1s ? '#define USE_UV1' : '',
			parameters.vertexUv2s ? '#define USE_UV2' : '',
			parameters.vertexUv3s ? '#define USE_UV3' : '',

			parameters.pointsUvs ? '#define USE_POINTS_UV' : '',

			parameters.gradientMap ? '#define USE_GRADIENTMAP' : '',

			parameters.flatShading ? '#define FLAT_SHADED' : '',

			parameters.doubleSided ? '#define DOUBLE_SIDED' : '',
			parameters.flipSided ? '#define FLIP_SIDED' : '',

			parameters.shadowMapEnabled ? '#define USE_SHADOWMAP' : '',
			parameters.shadowMapEnabled ? '#define ' + shadowMapTypeDefine : '',

			parameters.premultipliedAlpha ? '#define PREMULTIPLIED_ALPHA' : '',

			parameters.numLightProbes > 0 ? '#define USE_LIGHT_PROBES' : '',

			parameters.useLegacyLights ? '#define LEGACY_LIGHTS' : '',

			parameters.decodeVideoTexture ? '#define DECODE_VIDEO_TEXTURE' : '',

			parameters.logarithmicDepthBuffer ? '#define USE_LOGDEPTHBUF' : '',

			'uniform mat4 viewMatrix;',
			'uniform vec3 cameraPosition;',
			'uniform bool isOrthographic;',

			( parameters.toneMapping !== NoToneMapping ) ? '#define TONE_MAPPING' : '',
			( parameters.toneMapping !== NoToneMapping ) ? ShaderChunk[ 'tonemapping_pars_fragment' ] : '', // this code is required here because it is used by the toneMapping() function defined below
			( parameters.toneMapping !== NoToneMapping ) ? getToneMappingFunction( 'toneMapping', parameters.toneMapping ) : '',

			parameters.dithering ? '#define DITHERING' : '',
			parameters.opaque ? '#define OPAQUE' : '',

			ShaderChunk[ 'colorspace_pars_fragment' ], // this code is required here because it is used by the various encoding/decoding function defined below
			getTexelEncodingFunction( 'linearToOutputTexel', parameters.outputColorSpace ),

			parameters.useDepthPacking ? '#define DEPTH_PACKING ' + parameters.depthPacking : '',

			'\n'

		].filter( filterEmptyLine ).join( '\n' );

	}

	vertexShader = resolveIncludes( vertexShader );
	vertexShader = replaceLightNums( vertexShader, parameters );
	vertexShader = replaceClippingPlaneNums( vertexShader, parameters );

	fragmentShader = resolveIncludes( fragmentShader );
	fragmentShader = replaceLightNums( fragmentShader, parameters );
	fragmentShader = replaceClippingPlaneNums( fragmentShader, parameters );

	vertexShader = unrollLoops( vertexShader );
	fragmentShader = unrollLoops( fragmentShader );

	if ( parameters.isRawShaderMaterial !== true ) {

		// GLSL 3.0 conversion for built-in materials and ShaderMaterial

		versionString = '#version 300 es\n';

		prefixVertex = [
			customVertexExtensions,
			'#define attribute in',
			'#define varying out',
			'#define texture2D texture'
		].join( '\n' ) + '\n' + prefixVertex;

		prefixFragment = [
			'#define varying in',
			( parameters.glslVersion === GLSL3 ) ? '' : 'layout(location = 0) out highp vec4 pc_fragColor;',
			( parameters.glslVersion === GLSL3 ) ? '' : '#define gl_FragColor pc_fragColor',
			'#define gl_FragDepthEXT gl_FragDepth',
			'#define texture2D texture',
			'#define textureCube texture',
			'#define texture2DProj textureProj',
			'#define texture2DLodEXT textureLod',
			'#define texture2DProjLodEXT textureProjLod',
			'#define textureCubeLodEXT textureLod',
			'#define texture2DGradEXT textureGrad',
			'#define texture2DProjGradEXT textureProjGrad',
			'#define textureCubeGradEXT textureGrad'
		].join( '\n' ) + '\n' + prefixFragment;

	}

	const vertexGlsl = versionString + prefixVertex + vertexShader;
	const fragmentGlsl = versionString + prefixFragment + fragmentShader;

	// console.log( '*VERTEX*', vertexGlsl );
	// console.log( '*FRAGMENT*', fragmentGlsl );

	const glVertexShader = WebGLShader( gl, gl.VERTEX_SHADER, vertexGlsl );
	const glFragmentShader = WebGLShader( gl, gl.FRAGMENT_SHADER, fragmentGlsl );

	gl.attachShader( program, glVertexShader );
	gl.attachShader( program, glFragmentShader );

	// Force a particular attribute to index 0.

	if ( parameters.index0AttributeName !== undefined ) {

		gl.bindAttribLocation( program, 0, parameters.index0AttributeName );

	} else if ( parameters.morphTargets === true ) {

		// programs with morphTargets displace position out of attribute 0
		gl.bindAttribLocation( program, 0, 'position' );

	}

	gl.linkProgram( program );

	function onFirstUse( self ) {

		// check for link errors
		if ( renderer.debug.checkShaderErrors ) {

			const programLog = gl.getProgramInfoLog( program ).trim();
			const vertexLog = gl.getShaderInfoLog( glVertexShader ).trim();
			const fragmentLog = gl.getShaderInfoLog( glFragmentShader ).trim();

			let runnable = true;
			let haveDiagnostics = true;

			if ( gl.getProgramParameter( program, gl.LINK_STATUS ) === false ) {

				runnable = false;

				if ( typeof renderer.debug.onShaderError === 'function' ) {

					renderer.debug.onShaderError( gl, program, glVertexShader, glFragmentShader );

				} else {

					// default error reporting

					const vertexErrors = getShaderErrors( gl, glVertexShader, 'vertex' );
					const fragmentErrors = getShaderErrors( gl, glFragmentShader, 'fragment' );

					console.error(
						'THREE.WebGLProgram: Shader Error ' + gl.getError() + ' - ' +
						'VALIDATE_STATUS ' + gl.getProgramParameter( program, gl.VALIDATE_STATUS ) + '\n\n' +
						'Material Name: ' + self.name + '\n' +
						'Material Type: ' + self.type + '\n\n' +
						'Program Info Log: ' + programLog + '\n' +
						vertexErrors + '\n' +
						fragmentErrors
					);

				}

			} else if ( programLog !== '' ) {

				console.warn( 'THREE.WebGLProgram: Program Info Log:', programLog );

			} else if ( vertexLog === '' || fragmentLog === '' ) {

				haveDiagnostics = false;

			}

			if ( haveDiagnostics ) {

				self.diagnostics = {

					runnable: runnable,

					programLog: programLog,

					vertexShader: {

						log: vertexLog,
						prefix: prefixVertex

					},

					fragmentShader: {

						log: fragmentLog,
						prefix: prefixFragment

					}

				};

			}

		}

		// Clean up

		// Crashes in iOS9 and iOS10. #18402
		// gl.detachShader( program, glVertexShader );
		// gl.detachShader( program, glFragmentShader );

		gl.deleteShader( glVertexShader );
		gl.deleteShader( glFragmentShader );

		cachedUniforms = new WebGLUniforms( gl, program );
		cachedAttributes = fetchAttributeLocations( gl, program );

	}

	// set up caching for uniform locations

	let cachedUniforms;

	this.getUniforms = function () {

		if ( cachedUniforms === undefined ) {

			// Populates cachedUniforms and cachedAttributes
			onFirstUse( this );

		}

		return cachedUniforms;

	};

	// set up caching for attribute locations

	let cachedAttributes;

	this.getAttributes = function () {

		if ( cachedAttributes === undefined ) {

			// Populates cachedAttributes and cachedUniforms
			onFirstUse( this );

		}

		return cachedAttributes;

	};

	// indicate when the program is ready to be used. if the KHR_parallel_shader_compile extension isn't supported,
	// flag the program as ready immediately. It may cause a stall when it's first used.

	let programReady = ( parameters.rendererExtensionParallelShaderCompile === false );

	this.isReady = function () {

		if ( programReady === false ) {

			programReady = gl.getProgramParameter( program, COMPLETION_STATUS_KHR );

		}

		return programReady;

	};

	// free resource

	this.destroy = function () {

		bindingStates.releaseStatesOfProgram( this );

		gl.deleteProgram( program );
		this.program = undefined;

	};

	//

	this.type = parameters.shaderType;
	this.name = parameters.shaderName;
	this.id = programIdCount ++;
	this.cacheKey = cacheKey;
	this.usedTimes = 1;
	this.program = program;
	this.vertexShader = glVertexShader;
	this.fragmentShader = glFragmentShader;

	return this;

}