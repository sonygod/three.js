import three.js.src.renderers.webgl.WebGLUniforms.WebGLUniforms;
import three.js.src.renderers.webgl.WebGLShader.WebGLShader;
import three.js.src.shaders.ShaderChunk.ShaderChunk;
import three.js.src.constants.NoToneMapping.NoToneMapping;
import three.js.src.constants.AddOperation.AddOperation;
import three.js.src.constants.MixOperation.MixOperation;
import three.js.src.constants.MultiplyOperation.MultiplyOperation;
import three.js.src.constants.CubeRefractionMapping.CubeRefractionMapping;
import three.js.src.constants.CubeUVReflectionMapping.CubeUVReflectionMapping;
import three.js.src.constants.CubeReflectionMapping.CubeReflectionMapping;
import three.js.src.constants.PCFSoftShadowMap.PCFSoftShadowMap;
import three.js.src.constants.PCFShadowMap.PCFShadowMap;
import three.js.src.constants.VSMShadowMap.VSMShadowMap;
import three.js.src.constants.AgXToneMapping.AgXToneMapping;
import three.js.src.constants.ACESFilmicToneMapping.ACESFilmicToneMapping;
import three.js.src.constants.NeutralToneMapping.NeutralToneMapping;
import three.js.src.constants.CineonToneMapping.CineonToneMapping;
import three.js.src.constants.CustomToneMapping.CustomToneMapping;
import three.js.src.constants.ReinhardToneMapping.ReinhardToneMapping;
import three.js.src.constants.LinearToneMapping.LinearToneMapping;
import three.js.src.constants.GLSL3.GLSL3;
import three.js.src.constants.LinearSRGBColorSpace.LinearSRGBColorSpace;
import three.js.src.constants.SRGBColorSpace.SRGBColorSpace;
import three.js.src.constants.LinearDisplayP3ColorSpace.LinearDisplayP3ColorSpace;
import three.js.src.constants.DisplayP3ColorSpace.DisplayP3ColorSpace;
import three.js.src.constants.P3Primaries.P3Primaries;
import three.js.src.constants.Rec709Primaries.Rec709Primaries;
import three.js.src.math.ColorManagement.ColorManagement;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR:Int = 0x91B1;

var programIdCount:Int = 0;

function handleSource( string:String, errorLine:Int ):String {

	const lines:Array<String> = string.split( '\n' );
	const lines2:Array<String> = [];

	const from:Int = Math.max( errorLine - 6, 0 );
	const to:Int = Math.min( errorLine + 6, lines.length );

	for ( i in from...to ) {

		const line:Int = i + 1;
		lines2.push( `${line === errorLine ? '>' : ' '} ${line}: ${lines[ i ]}` );

	}

	return lines2.join( '\n' );

}

function getEncodingComponents( colorSpace:String ):Array<String> {

	const workingPrimaries:String = ColorManagement.getPrimaries( ColorManagement.workingColorSpace );
	const encodingPrimaries:String = ColorManagement.getPrimaries( colorSpace );

	var gamutMapping:String;

	if ( workingPrimaries === encodingPrimaries ) {

		gamutMapping = '';

	} else if ( workingPrimaries === P3Primaries && encodingPrimaries === Rec709Primaries ) {

		gamutMapping = 'LinearDisplayP3ToLinearSRGB';

	} else if ( workingPrimaries === Rec709Primaries && encodingPrimaries === P3Primaries ) {

		gamutMapping = 'LinearSRGBToLinearDisplayP3';

	}

	switch ( colorSpace ) {

		case LinearSRGBColorSpace:
		case LinearDisplayP3ColorSpace:
			return [ gamutMapping, 'LinearTransferOETF' ];

		case SRGBColorSpace:
		case DisplayP3ColorSpace:
			return [ gamutMapping, 'sRGBTransferOETF' ];

		default:
			trace( 'THREE.WebGLProgram: Unsupported color space:', colorSpace );
			return [ gamutMapping, 'LinearTransferOETF' ];

	}

}

function getShaderErrors( gl:WebGLRenderingContext, shader:WebGLShader, type:String ):String {

	const status:Bool = gl.getShaderParameter( shader, gl.COMPILE_STATUS );
	const errors:String = gl.getShaderInfoLog( shader ).trim();

	if ( status && errors === '' ) return '';

	const errorMatches:Array<String> = /ERROR: 0:(\d+)/.exec( errors );
	if ( errorMatches ) {

		// --enable-privileged-webgl-extension
		// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

		const errorLine:Int = parseInt( errorMatches[ 1 ] );
		return type.toUpperCase() + '\n\n' + errors + '\n\n' + handleSource( gl.getShaderSource( shader ), errorLine );

	} else {

		return errors;

	}

}

function getTexelEncodingFunction( functionName:String, colorSpace:String ):String {

	const components:Array<String> = getEncodingComponents( colorSpace );
	return `vec4 ${functionName}( vec4 value ) { return ${components[ 0 ]}( ${components[ 1 ]}( value ) ); }`;

}

function getToneMappingFunction( functionName:String, toneMapping:String ):String {

	var toneMappingName:String;

	switch ( toneMapping ) {

		case LinearToneMapping:
			toneMappingName = 'Linear';
			break;

		case ReinhardToneMapping:
			toneMappingName = 'Reinhard';
			break;

		case CineonToneMapping:
			toneMappingName = 'OptimizedCineon';
			break;

		case ACESFilmicToneMapping:
			toneMappingName = 'ACESFilmic';
			break;

		case AgXToneMapping:
			toneMappingName = 'AgX';
			break;

		case NeutralToneMapping:
			toneMappingName = 'Neutral';
			break;

		case CustomToneMapping:
			toneMappingName = 'Custom';
			break;

		default:
			trace( 'THREE.WebGLProgram: Unsupported toneMapping:', toneMapping );
			toneMappingName = 'Linear';

	}

	return 'vec3 ' + functionName + '( vec3 color ) { return ' + toneMappingName + 'ToneMapping( color ); }';

}

function generateVertexExtensions( parameters:Dynamic ):String {

	const chunks:Array<String> = [
		parameters.extensionClipCullDistance ? '#extension GL_ANGLE_clip_cull_distance : require' : '',
		parameters.extensionMultiDraw ? '#extension GL_ANGLE_multi_draw : require' : '',
	];

	return chunks.filter( filterEmptyLine ).join( '\n' );

}

function generateDefines( defines:Dynamic ):String {

	const chunks:Array<String> = [];

	for ( name in defines ) {

		const value:Dynamic = defines[ name ];

		if ( value === false ) continue;

		chunks.push( '#define ' + name + ' ' + value );

	}

	return chunks.join( '\n' );

}

function fetchAttributeLocations( gl:WebGLRenderingContext, program:WebGLProgram ):Dynamic {

	const attributes:Dynamic = {};

	const n:Int = gl.getProgramParameter( program, gl.ACTIVE_ATTRIBUTES );

	for ( i in 0...n ) {

		const info:WebGLActiveInfo = gl.getActiveAttrib( program, i );
		const name:String = info.name;

		var locationSize:Int = 1;
		if ( info.type === gl.FLOAT_MAT2 ) locationSize = 2;
		if ( info.type === gl.FLOAT_MAT3 ) locationSize = 3;
		if ( info.type === gl.FLOAT_MAT4 ) locationSize = 4;

		// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

		attributes[ name ] = {
			type: info.type,
			location: gl.getAttribLocation( program, name ),
			locationSize: locationSize
		};

	}

	return attributes;

}

function filterEmptyLine( string:String ):Bool {

	return string !== '';

}

function replaceLightNums( string:String, parameters:Dynamic ):String {

	const numSpotLightCoords:Int = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

	return string
		.replace( /NUM_DIR_LIGHTS/g, parameters.numDirLights )
		.replace( /NUM_SPOT_LIGHTS/g, parameters.numSpotLights )
		.replace( /NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps )
		.replace( /NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords )
		.replace( /NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights )
		.replace( /NUM_POINT_LIGHTS/g, parameters.numPointLights )
		.replace( /NUM_HEMI_LIGHTS/g, parameters.numHemiLights )
		.replace( /NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows )
		.replace( /NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps )
		.replace( /NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows )
		.replace( /NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows );

}

function replaceClippingPlaneNums( string:String, parameters:Dynamic ):String {

	return string
		.replace( /NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes )
		.replace( /UNION_CLIPPING_PLANES/g, ( parameters.numClippingPlanes - parameters.numClipIntersection ) );

}

// Resolve Includes

const includePattern:RegExp = /^[ \t]*#include +<([\w\d./]+)>/gm;

function resolveIncludes( string:String ):String {

	return string.replace( includePattern, includeReplacer );

}

const shaderChunkMap:Map<String, String> = new Map();

function includeReplacer( match:String, include:String ):String {

	let string:String = ShaderChunk[ include ];

	if ( string === undefined ) {

		const newInclude:String = shaderChunkMap.get( include );

		if ( newInclude !== undefined ) {

			string = ShaderChunk[ newInclude ];
			trace( 'THREE.WebGLProgram: Shader chunk "%s" has been deprecated. Use "%s" instead.', include, newInclude );

		} else {

			throw new Error( 'Can not resolve #include <' + include + '>' );

		}

	}

	return resolveIncludes( string );

}

// Unroll Loops

const unrollLoopPattern:RegExp = /#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end/g;

function unrollLoops( string:String ):String {

	return string.replace( unrollLoopPattern, loopReplacer );

}

function loopReplacer( match:String, start:String, end:String, snippet:String ):String {

	let string:String = '';

	for ( i in parseInt( start )...parseInt( end ) ) {

		string += snippet
			.replace( /\[\s*i\s*\]/g, '[ ' + i + ' ]' )
			.replace( /UNROLLED_LOOP_INDEX/g, i );

	}

	return string;

}

//

function generatePrecision( parameters:Dynamic ):String {

	let precisionstring:String = `precision ${parameters.precision} float;
	precision ${parameters.precision} int;
	precision ${parameters.precision} sampler2D;
	precision ${parameters.precision} samplerCube;
	precision ${parameters.precision} sampler3D;
	precision ${parameters.precision} sampler2DArray;
	precision ${parameters.precision} sampler2DShadow;
	precision ${parameters.precision} samplerCubeShadow;
	precision ${parameters.precision} sampler2DArrayShadow;
	precision ${parameters.precision} isampler2D;
	precision ${parameters.precision} isampler3D;
	precision ${parameters.precision} isamplerCube;
	precision ${parameters.precision} isampler2DArray;
	precision ${parameters.precision} usampler2D;
	precision ${parameters.precision} usampler3D;
	precision ${parameters.precision} usamplerCube;
	precision ${parameters.precision} usampler2DArray;
	`;

	if ( parameters.precision === 'highp' ) {

		precisionstring += '\n#define HIGH_PRECISION';

	} else if ( parameters.precision === 'mediump' ) {

		precisionstring += '\n#define MEDIUM_PRECISION';

	} else if ( parameters.precision === 'lowp' ) {

		precisionstring += '\n#define LOW_PRECISION';

	}

	return precisionstring;

}

function generateShadowMapTypeDefine( parameters:Dynamic ):String {

	let shadowMapTypeDefine:String = 'SHADOWMAP_TYPE_BASIC';

	if ( parameters.shadowMapType === PCFShadowMap ) {

		shadowMapTypeDefine = 'SHADOWMAP_TYPE_PCF';

	} else if ( parameters.shadowMapType === PCFSoftShadowMap ) {

		shadowMapTypeDefine = 'SHADOWMAP_TYPE_PCF_SOFT';

	} else if ( parameters.shadowMapType === VSMShadowMap ) {

		shadowMapTypeDefine = 'SHADOWMAP_TYPE_VSM';

	}

	return shadowMapTypeDefine;

}

function generateEnvMapTypeDefine( parameters:Dynamic ):String {

	let envMapTypeDefine:String = 'ENVMAP_TYPE_CUBE';

	if ( parameters.envMap ) {

		switch ( parameters.envMapMode ) {

			case CubeReflectionMapping:
			case CubeRefractionMapping:
				envMapTypeDefine = 'ENVMAP_TYPE_CUBE';
				break;

			case CubeUVReflectionMapping:
				envMapTypeDefine = 'ENVMAP_TYPE_CUBE_UV';
				break;

		}

	}

	return envMapTypeDefine;

}

function generateEnvMapModeDefine( parameters:Dynamic ):String {

	let envMapModeDefine:String = 'ENVMAP_MODE_REFLECTION';

	if ( parameters.envMap ) {

		switch ( parameters.envMapMode ) {

			case CubeRefractionMapping:

				envMapModeDefine = 'ENVMAP_MODE_REFRACTION';
				break;

		}

	}

	return envMapModeDefine;

}

function generateEnvMapBlendingDefine( parameters:Dynamic ):String {

	let envMapBlendingDefine:String = 'ENVMAP_BLENDING_NONE';

	if ( parameters.envMap ) {

		switch ( parameters.combine ) {

			case MultiplyOperation:
				envMapBlendingDefine = 'ENVMAP_BLENDING_MULTIPLY';
				break;

			case MixOperation:
				envMapBlendingDefine = 'ENVMAP_BLENDING_MIX';
				break;

			case AddOperation:
				envMapBlendingDefine = 'ENVMAP_BLENDING_ADD';
				break;

		}

	}

	return envMapBlendingDefine;

}

function generateCubeUVSize( parameters:Dynamic ):Dynamic {

	const imageHeight:Int = parameters.envMapCubeUVHeight;

	if ( imageHeight === null ) return null;

	const maxMip:Int = Math.log2( imageHeight ) - 2;

	const texelHeight:Float = 1.0 / imageHeight;

	const texelWidth:Float = 1.0 / ( 3 * Math.max( Math.pow( 2, maxMip ), 7 * 16 ) );

	return { texelWidth, texelHeight, maxMip };

}

class WebGLProgram {

	public var renderer:WebGLRenderer;
	public var cacheKey:String;
	public var parameters:Dynamic;
	public var bindingStates:BindingStates;

	public function new( renderer:WebGLRenderer, cacheKey:String, parameters:Dynamic, bindingStates:BindingStates ) {

		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

		const gl:WebGLRenderingContext = renderer.getContext();

		const defines:Dynamic = parameters.defines;

		var vertexShader:String = parameters.vertexShader;
		var fragmentShader:String = parameters.fragmentShader;

		const shadowMapTypeDefine:String = generateShadowMapTypeDefine( parameters );
		const envMapTypeDefine:String = generateEnvMapTypeDefine( parameters );
		const envMapModeDefine:String = generateEnvMapModeDefine( parameters );
		const envMapBlendingDefine:String = generateEnvMapBlendingDefine( parameters );
		const envMapCubeUVSize:Dynamic = generateCubeUVSize( parameters );

		const customVertexExtensions:String = generateVertexExtensions( parameters );

		const customDefines:String = generateDefines( defines );

		const program:WebGLProgram = gl.createProgram();

		var prefixVertex:String, prefixFragment:String;
		var versionString:String = parameters.glslVersion ? '#version ' + parameters.glslVersion + '\n' : '';

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

		const vertexGlsl:String = versionString + prefixVertex + vertexShader;
		const fragmentGlsl:String = versionString + prefixFragment + fragmentShader;

		// console.log( '*VERTEX*', vertexGlsl );
		// console.log( '*FRAGMENT*', fragmentGlsl );

		const glVertexShader:WebGLShader = WebGLShader( gl, gl.VERTEX_SHADER, vertexGlsl );
		const glFragmentShader:WebGLShader = WebGLShader( gl, gl.FRAGMENT_SHADER, fragmentGlsl );

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

		function onFirstUse( self:WebGLProgram ) {

			// check for link errors
			if ( renderer.debug.checkShaderErrors ) {

				const programLog:String = gl.getProgramInfoLog( program ).trim();
				const vertexLog:String = gl.getShaderInfoLog( glVertexShader ).trim();
				const fragmentLog:String = gl.getShaderInfoLog( glFragmentShader ).trim();

				let runnable:Bool = true;
				let haveDiagnostics:Bool = true;

				if ( gl.getProgramParameter( program, gl.LINK_STATUS ) === false ) {

					runnable = false;

					if ( typeof renderer.debug.onShaderError === 'function' ) {

						renderer.debug.onShaderError( gl, program, glVertexShader, glFragmentShader );

					} else {

						// default error reporting

						const vertexErrors:String = getShaderErrors( gl, glVertexShader, 'vertex' );
						const fragmentErrors:String = getShaderErrors( gl, glFragmentShader, 'fragment' );

						trace(
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

					trace( 'THREE.WebGLProgram: Program Info Log:', programLog );

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

		var cachedUniforms:WebGLUniforms;

		this.getUniforms = function():WebGLUniforms {

			if ( cachedUniforms === undefined ) {

				// Populates cachedUniforms and cachedAttributes
				onFirstUse( this );

			}

			return cachedUniforms;

		};

		// set up caching for attribute locations

		var cachedAttributes:Dynamic;

		this.getAttributes = function():Dynamic {

			if ( cachedAttributes === undefined ) {

				// Populates cachedAttributes and cachedUniforms
				onFirstUse( this );

			}

			return cachedAttributes;

		};

		// indicate when the program is ready to be used. if the KHR_parallel_shader_compile extension isn't supported,
		// flag the program as ready immediately. It may cause a stall when it's first used.

		var programReady:Bool = ( parameters.rendererExtensionParallelShaderCompile === false );

		this.isReady = function():Bool {

			if ( programReady === false ) {

				programReady = gl.getProgramParameter( program, COMPLETION_STATUS_KHR );

			}

			return programReady;

		};

		// free resource

		this.destroy = function() {

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

}

export class WebGLProgram {

	public var renderer:WebGLRenderer;
	public var cacheKey:String;
	public var parameters:Dynamic;
	public var bindingStates:BindingStates;

	public function new( renderer:WebGLRenderer, cacheKey:String, parameters:Dynamic, bindingStates:BindingStates ) {

		return new WebGLProgram( renderer, cacheKey, parameters, bindingStates );

	}

}