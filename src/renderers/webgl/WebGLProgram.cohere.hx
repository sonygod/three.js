import js.WebGLUniforms;
import js.WebGLShader;
import js.ShaderChunk;
import js.NoToneMapping;
import js.AddOperation;
import js.MixOperation;
import js.MultiplyOperation;
import js.CubeRefractionMapping;
import js.CubeUVReflectionMapping;
import js.CubeReflectionMapping;
import js.PCFSoftShadowMap;
import js.PCFShadowMap;
import js.VSMShadowMap;
import js.AgXToneMapping;
import js.ACESFilmicToneMapping;
import js.NeutralToneMapping;
import js.CineonToneMapping;
import js.CustomToneMapping;
import js.ReinhardToneMapping;
import js.LinearToneMapping;
import js.GLSL3;
import js.LinearSRGBColorSpace;
import js.SRGBColorSpace;
import js.LinearDisplayP3ColorSpace;
import js.DisplayP3ColorSpace;
import js.P3Primaries;
import js.Rec709Primaries;
import js.ColorManagement;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

var programIdCount:Int = 0;

function handleSource(string:String, errorLine:Int):String {
	var lines = string.split('\n');
	var lines2 = [];

	var from = Math.max(errorLine - 6, 0);
	var to = Math.min(errorLine + 6, lines.length);

	for (var i = from; i < to; i++) {
		var line = i + 1;
		lines2.push($'> ${line}: ${lines[i]}');
	}

	return lines2.join('\n');
}

function getEncodingComponents(colorSpace:Dynamic):Dynamic {
	var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
	var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

	var gamutMapping;

	if (workingPrimaries == encodingPrimaries) {
		gamutMapping = '';
	} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
		gamutMapping = 'LinearDisplayP3ToLinearSRGB';
	} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
		gamutMapping = 'LinearSRGBToLinearDisplayP3';
	}

	switch (colorSpace) {
		case LinearSRGBColorSpace:
		case LinearDisplayP3ColorSpace:
			return [gamutMapping, 'LinearTransferOETF'];

		case SRGBColorSpace:
		case DisplayP3ColorSpace:
			return [gamutMapping, 'sRGBTransferOETF'];

		default:
			trace('THREE.WebGLProgram: Unsupported color space:', colorSpace);
			return [gamutMapping, 'LinearTransferOETF'];
	}
}

function getShaderErrors(gl:Dynamic, shader:Dynamic, type:String):String {
	var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
	var errors = gl.getShaderInfoLog(shader).trim();

	if (status && errors == '') return '';

	var errorMatches = /ERROR: 0:(\d+)/.exec(errors);
	if (errorMatches) {
		// --enable-privileged-webgl-extension
		// console.log('**' + type + '**', gl.getExtension('WEBGL_debug_shaders').getTranslatedShaderSource(shader));

		var errorLine = Std.parseInt(errorMatches[1]);
		return type.toUpperCase() + '\n\n' + errors + '\n\n' + handleSource(gl.getShaderSource(shader), errorLine);

	} else {
		return errors;
	}
}

function getTexelEncodingFunction(functionName:String, colorSpace:Dynamic):String {
	var components = getEncodingComponents(colorSpace);
	return 'vec4 ' + functionName + '( vec4 value ) { return ' + components[0] + '( ' + components[1] + '( value ) ); }';
}

function getToneMappingFunction(functionName:String, toneMapping:Dynamic):String {
	var toneMappingName;

	switch (toneMapping) {
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
			trace('THREE.WebGLProgram: Unsupported toneMapping:', toneMapping);
			toneMappingName = 'Linear';
	}

	return 'vec3 ' + functionName + '( vec3 color ) { return ' + toneMappingName + 'ToneMapping( color ); }';
}

function generateVertexExtensions(parameters:Dynamic):String {
	var chunks = [];

	if (parameters.extensionClipCullDistance) {
		chunks.push('#extension GL_ANGLE_clip_cull_distance : require');
	}

	if (parameters.extensionMultiDraw) {
		chunks.push('#extension GL_ANGLE_multi_draw : require');
	}

	return chunks.filter(filterEmptyLine).join('\n');
}

function generateDefines(defines:Dynamic):String {
	var chunks = [];

	for (var name in defines) {
		var value = defines[name];

		if (value == false) continue;

		chunks.push('#define ' + name + ' ' + value);
	}

	return chunks.join('\n');
}

function fetchAttributeLocations(gl:Dynamic, program:Dynamic):Dynamic {
	var attributes = {};

	var n = gl.getProgramParameter(program, gl.ACTIVE_ATTRIBUTES);

	for (var i = 0; i < n; i++) {
		var info = gl.getActiveAttrib(program, i);
		var name = info.name;

		var locationSize = 1;
		if (info.type == gl.FLOAT_MAT2) locationSize = 2;
		if (info.type == gl.FLOAT_MAT3) locationSize = 3;
		if (info.type == gl.FLOAT_MAT4) locationSize = 4;

		// console.log('THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i);

		attributes[name] = {
			type: info.type,
			location: gl.getAttribLocation(program, name),
			locationSize: locationSize
		};
	}

	return attributes;
}

function filterEmptyLine(string:String):Bool {
	return string != '';
}

function replaceLightNums(string:String, parameters:Dynamic):String {
	return string
		.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights)
		.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights)
		.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps)
		.replace(/NUM_SPOT_LIGHT_COORDS/g, parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps)
		.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights)
		.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights)
		.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights)
		.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows)
		.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps)
		.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows)
		.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows);
}

function replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
	return string
		.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes)
		.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection));
}

// Resolve Includes

var includePattern = /^[ \t]*#include +<([\w\d./]+)>/gm;

function resolveIncludes(string:String):String {
	return string.replace(includePattern, includeReplacer);
}

var shaderChunkMap = new Map();

function includeReplacer(match:Dynamic, include:String):String {
	var string = ShaderChunk[include];

	if (string == null) {
		var newInclude = shaderChunkMap.get(include);

		if (newInclude != null) {
			string = ShaderChunk[newInclude];
			trace('THREE.WebGLRenderer: Shader chunk "%s" has been deprecated. Use "%s" instead.', include, newInclude);
		} else {
			throw new Error('Can not resolve #include <' + include + '>');
		}
	}

	return resolveIncludes(string);
}

// Unroll Loops

var unrollLoopPattern = /#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end/g;

function unrollLoops(string:String):String {
	return string.replace(unrollLoopPattern, loopReplacer);
}

function loopReplacer(match:Dynamic, start:Dynamic, end:Dynamic, snippet:String):String {
	var string = '';

	for (var i = Std.parseInt(start); i < Std.parseInt(end); i++) {
		string += snippet
			.replace(/\[s\*i\*\]/g, '[ ' + i + ' ]')
			.replace(/UNROLLED_LOOP_INDEX/g, i);
	}

	return string;
}

//

function generatePrecision(parameters:Dynamic):String {
	var precisionstring = `precision ${parameters.precision} float;
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

	if (parameters.precision == 'highp') {
		precisionstring += '\n#define HIGH_PRECISION';
	} else if (parameters.precision == 'mediump') {
		precisionstring += '\n#define MEDIUM_PRECISION';
	} else if (parameters.precision == 'lowp') {
		precisionstring += '\n#define LOW_PRECISION';
	}

	return precisionstring;
}

function generateShadowMapTypeDefine(parameters:Dynamic):String {
	var shadowMapTypeDefine = 'SHADOWMAP_TYPE_BASIC';

	if (parameters.shadowMapType == PCFShadowMap) {
		shadowMapTypeDefine = 'SHADOWMAP_TYPE_PCF';
	} else if (parameters.shadowMapType == PCFSoftShadowMap) {
		shadowMapTypeDefine = 'SHADOWMAP_TYPE_PCF_SOFT';
	} else if (parameters.shadowMapType == VSMShadowMap) {
		shadowMapTypeDefine = 'SHADOWMAP_TYPE_VSM';
	}

	return shadowMapTypeDefine;
}

function generateEnvMapTypeDefine(parameters:Dynamic):String {
	var envMapTypeDefine = 'ENVMAP_TYPE_CUBE';

	if (parameters.envMap) {
		switch (parameters.envMapMode) {
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

function generateEnvMapModeDefine(parameters:Dynamic):String {
	var envMapModeDefine = 'ENVMAP_MODE_REFLECTION';

	if (parameters.envMap) {
		switch (parameters.envMapMode) {
			case CubeRefractionMapping:
				envMapModeDefine = 'ENVMAP_MODE_REFRACTION';
				break;
		}
	}

	return envMapModeDefine;
}

function generateEnvMapBlendingDefine(parameters:Dynamic):String {
	var envMapBlendingDefine = 'ENVMAP_BLENDING_NONE';

	if (parameters.envMap) {
		switch (parameters.combine) {
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

function generateCubeUVSize(parameters:Dynamic):Dynamic {
	var imageHeight = parameters.envMapCubeUVHeight;

	if (imageHeight == null) return null;

	var maxMip = Math.log2(imageHeight) - 2;

	var texelHeight = 1.0 / imageHeight;

	var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

	return {
		texelWidth: texelWidth,
		texelHeight: texelHeight,
		maxMip: maxMip
	};
}

class WebGLProgram {
	constructor(renderer:Dynamic, cacheKey:Dynamic, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log('WebGLProgram', cacheKey);

		var gl = renderer.getContext();

		var defines = parameters.defines;

		var vertexShader = parameters.vertexShader;
		var fragmentShader = parameters.fragmentShader;

		var shadowMapTypeDefine = generateShadowMapTypeDefine(parameters);
		var envMapTypeDefine = generateEnvMapTypeDefine(parameters);
		var envMapModeDefine = generateEnvMapModeDefine(parameters);
		var envMapBlendingDefine = generateEnvMapBlendingDefine(parameters);
		var envMapCubeUVSize = generateCubeUVSize(parameters);

		var customVertexExtensions = generateVertexExtensions(parameters);

		var customDefines = generateDefines(defines);

		var program = gl.createProgram();

		var prefixVertex, prefixFragment;
		var versionString = parameters.glslVersion ? '#version ' + parameters.glslVersion + '\n' : '';

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [
				'#define SHADER_TYPE ' + parameters.shaderType,
				'#define SHADER_NAME ' + parameters.shaderName,
				customDefines
			].filter(filterEmptyLine).join('\n');

			if (prefixVertex.length > 0) {
				prefixVertex += '\n';
			}

			prefixFragment = [
				'#define SHADER_TYPE ' + parameters.shaderType,
				'#define SHADER_NAME ' + parameters.shaderName,
				customDefines
			].filter(filterEmptyLine).join('\n');

			if (prefixFragment.length > 0) {
				prefixFragment += '\n';
			}

		} else {
			prefixVertex = [
				generatePrecision(parameters),
				'#define SHADER_TYPE ' + parameters.shaderType,
				'#define SHADER_NAME ' + parameters.shaderName,
				customDefines,
				parameters.extensionClipCullDistance ?