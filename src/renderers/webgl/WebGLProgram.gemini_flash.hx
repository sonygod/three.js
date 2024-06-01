import three.constants.ColorManagement;
import three.constants.NoToneMapping;
import three.constants.AddOperation;
import three.constants.MixOperation;
import three.constants.MultiplyOperation;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.CubeReflectionMapping;
import three.constants.PCFSoftShadowMap;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.AgXToneMapping;
import three.constants.ACESFilmicToneMapping;
import three.constants.NeutralToneMapping;
import three.constants.CineonToneMapping;
import three.constants.CustomToneMapping;
import three.constants.ReinhardToneMapping;
import three.constants.LinearToneMapping;
import three.constants.GLSL3;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.P3Primaries;
import three.constants.Rec709Primaries;
import three.shaders.ShaderChunk;
import three.webgl.WebGLShader;
import three.webgl.WebGLUniforms;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

class WebGLProgram {

	static programIdCount:Int = 0;

	static handleSource(string:String, errorLine:Int):String {
		var lines = string.split("\n");
		var lines2 = new Array<String>();

		var from = Math.max(errorLine - 6, 0);
		var to = Math.min(errorLine + 6, lines.length);

		for (var i in from...to) {
			var line = i + 1;
			lines2.push(line == errorLine ? "> " : "  " + line + ": " + lines[i]);
		}

		return lines2.join("\n");
	}

	static getEncodingComponents(colorSpace:Int):Array<String> {
		var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
		var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

		var gamutMapping:String;

		if (workingPrimaries == encodingPrimaries) {
			gamutMapping = "";
		} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
			gamutMapping = "LinearDisplayP3ToLinearSRGB";
		} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
			gamutMapping = "LinearSRGBToLinearDisplayP3";
		}

		switch (colorSpace) {
			case LinearSRGBColorSpace:
			case LinearDisplayP3ColorSpace:
				return [gamutMapping, "LinearTransferOETF"];
			case SRGBColorSpace:
			case DisplayP3ColorSpace:
				return [gamutMapping, "sRGBTransferOETF"];
			default:
				Sys.println("THREE.WebGLProgram: Unsupported color space:", colorSpace);
				return [gamutMapping, "LinearTransferOETF"];
		}
	}

	static getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
		var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		var errors = gl.getShaderInfoLog(shader).trim();

		if (status && errors == "") return "";

		var errorMatches = errors.match(/ERROR: 0:(\d+)/);
		if (errorMatches != null) {
			// --enable-privileged-webgl-extension
			// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

			var errorLine = Std.parseInt(errorMatches[1]);
			return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
		} else {
			return errors;
		}
	}

	static getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
		var components = getEncodingComponents(colorSpace);
		return "vec4 " + functionName + "( vec4 value ) { return " + components[0] + "( " + components[1] + "( value ) ); }";
	}

	static getToneMappingFunction(functionName:String, toneMapping:Int):String {
		var toneMappingName:String;

		switch (toneMapping) {
			case LinearToneMapping:
				toneMappingName = "Linear";
				break;
			case ReinhardToneMapping:
				toneMappingName = "Reinhard";
				break;
			case CineonToneMapping:
				toneMappingName = "OptimizedCineon";
				break;
			case ACESFilmicToneMapping:
				toneMappingName = "ACESFilmic";
				break;
			case AgXToneMapping:
				toneMappingName = "AgX";
				break;
			case NeutralToneMapping:
				toneMappingName = "Neutral";
				break;
			case CustomToneMapping:
				toneMappingName = "Custom";
				break;
			default:
				Sys.println("THREE.WebGLProgram: Unsupported toneMapping:", toneMapping);
				toneMappingName = "Linear";
		}

		return "vec3 " + functionName + "( vec3 color ) { return " + toneMappingName + "ToneMapping( color ); }";
	}

	static generateVertexExtensions(parameters:Dynamic):String {
		var chunks = new Array<String>();

		chunks.push(parameters.extensionClipCullDistance ? "#extension GL_ANGLE_clip_cull_distance : require" : "");
		chunks.push(parameters.extensionMultiDraw ? "#extension GL_ANGLE_multi_draw : require" : "");

		return chunks.filter(filterEmptyLine).join("\n");
	}

	static generateDefines(defines:Dynamic):String {
		var chunks = new Array<String>();

		for (var name in defines) {
			var value = defines[name];

			if (value == false) continue;

			chunks.push("#define " + name + " " + value);
		}

		return chunks.join("\n");
	}

	static fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):Dynamic {
		var attributes = new Dynamic();

		var n = gl.getProgramParameter(program.program, gl.ACTIVE_ATTRIBUTES);

		for (var i in 0...n) {
			var info = gl.getActiveAttrib(program.program, i);
			var name = info.name;

			var locationSize = 1;
			if (info.type == gl.FLOAT_MAT2) locationSize = 2;
			if (info.type == gl.FLOAT_MAT3) locationSize = 3;
			if (info.type == gl.FLOAT_MAT4) locationSize = 4;

			// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

			attributes[name] = {
				type: info.type,
				location: gl.getAttribLocation(program.program, name),
				locationSize: locationSize
			};
		}

		return attributes;
	}

	static filterEmptyLine(string:String):Bool {
		return string != "";
	}

	static replaceLightNums(string:String, parameters:Dynamic):String {
		var numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		return string
			.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights.toString())
			.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights.toString())
			.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps.toString())
			.replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords.toString())
			.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights.toString())
			.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights.toString())
			.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights.toString())
			.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows.toString())
			.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows.toString());
	}

	static replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
		return string
			.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes.toString())
			.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection).toString());
	}

	// Resolve Includes

	static includePattern = ~r"^[ \t]*#include +<([\w\d./]+)>";

	static resolveIncludes(string:String):String {
		return string.replace(includePattern, includeReplacer);
	}

	static shaderChunkMap = new Map<String, String>();

	static includeReplacer(match:String, include:String):String {
		var string = ShaderChunk[include];

		if (string == null) {
			var newInclude = shaderChunkMap.get(include);

			if (newInclude != null) {
				string = ShaderChunk[newInclude];
				Sys.println("THREE.WebGLRenderer: Shader chunk \"" + include + "\" has been deprecated. Use \"" + newInclude + "\" instead.");
			} else {
				throw new Error("Can not resolve #include <" + include + ">");
			}
		}

		return resolveIncludes(string);
	}

	// Unroll Loops

	static unrollLoopPattern = ~r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end";

	static unrollLoops(string:String):String {
		return string.replace(unrollLoopPattern, loopReplacer);
	}

	static loopReplacer(match:String, start:String, end:String, snippet:String):String {
		var string = "";

		for (var i in Std.parseInt(start)...Std.parseInt(end)) {
			string += snippet
				.replace(/\[\s*i\s*\]/g, "[ " + i + " ]")
				.replace(/UNROLLED_LOOP_INDEX/g, i.toString());
		}

		return string;
	}

	//

	static generatePrecision(parameters:Dynamic):String {
		var precisionstring = "precision " + parameters.precision + " float;\n" +
			"precision " + parameters.precision + " int;\n" +
			"precision " + parameters.precision + " sampler2D;\n" +
			"precision " + parameters.precision + " samplerCube;\n" +
			"precision " + parameters.precision + " sampler3D;\n" +
			"precision " + parameters.precision + " sampler2DArray;\n" +
			"precision " + parameters.precision + " sampler2DShadow;\n" +
			"precision " + parameters.precision + " samplerCubeShadow;\n" +
			"precision " + parameters.precision + " sampler2DArrayShadow;\n" +
			"precision " + parameters.precision + " isampler2D;\n" +
			"precision " + parameters.precision + " isampler3D;\n" +
			"precision " + parameters.precision + " isamplerCube;\n" +
			"precision " + parameters.precision + " isampler2DArray;\n" +
			"precision " + parameters.precision + " usampler2D;\n" +
			"precision " + parameters.precision + " usampler3D;\n" +
			"precision " + parameters.precision + " usamplerCube;\n" +
			"precision " + parameters.precision + " usampler2DArray;\n";

		if (parameters.precision == "highp") {
			precisionstring += "\n#define HIGH_PRECISION";
		} else if (parameters.precision == "mediump") {
			precisionstring += "\n#define MEDIUM_PRECISION";
		} else if (parameters.precision == "lowp") {
			precisionstring += "\n#define LOW_PRECISION";
		}

		return precisionstring;
	}

	static generateShadowMapTypeDefine(parameters:Dynamic):String {
		var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

		if (parameters.shadowMapType == PCFShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
		} else if (parameters.shadowMapType == PCFSoftShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
		} else if (parameters.shadowMapType == VSMShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_VSM";
		}

		return shadowMapTypeDefine;
	}

	static generateEnvMapTypeDefine(parameters:Dynamic):String {
		var envMapTypeDefine = "ENVMAP_TYPE_CUBE";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeReflectionMapping:
				case CubeRefractionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE";
					break;
				case CubeUVReflectionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE_UV";
					break;
			}
		}

		return envMapTypeDefine;
	}

	static generateEnvMapModeDefine(parameters:Dynamic):String {
		var envMapModeDefine = "ENVMAP_MODE_REFLECTION";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeRefractionMapping:
					envMapModeDefine = "ENVMAP_MODE_REFRACTION";
					break;
			}
		}

		return envMapModeDefine;
	}

	static generateEnvMapBlendingDefine(parameters:Dynamic):String {
		var envMapBlendingDefine = "ENVMAP_BLENDING_NONE";

		if (parameters.envMap != null) {
			switch (parameters.combine) {
				case MultiplyOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MULTIPLY";
					break;
				case MixOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MIX";
					break;
				case AddOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_ADD";
					break;
			}
		}

		return envMapBlendingDefine;
	}

	static generateCubeUVSize(parameters:Dynamic):Dynamic {
		var imageHeight = parameters.envMapCubeUVHeight;

		if (imageHeight == null) return null;

		var maxMip = Math.log2(imageHeight) - 2;

		var texelHeight = 1.0 / imageHeight;

		var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

		return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
	}

	program:WebGLProgram;
	vertexShader:WebGLShader;
	fragmentShader:WebGLShader;
	type:String;
	name:String;
	id:Int;
	cacheKey:String;
	usedTimes:Int;
	cachedUniforms:WebGLUniforms;
	cachedAttributes:Dynamic;
	diagnostics:Dynamic;
	isReady:Bool;

	function new(renderer:Dynamic, cacheKey:String, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

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

		this.program = gl.createProgram();

		var prefixVertex:String;
		var prefixFragment:String;
		var versionString:String = parameters.glslVersion != null ? "#version " + parameters.glslVersion + "\n" : "";

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixVertex.length > 0) {
				prefixVertex += "\n";
			}

			prefixFragment = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixFragment.length > 0) {
				prefixFragment += "\n";
			}
		} else {
			prefixVertex = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.extensionClipCullDistance ? "#define USE_CLIP_DISTANCE" : "",
				parameters.batching ? "#define USE_BATCHING" : "",
				parameters.batchingColor ? "#define USE_BATCHING_COLOR" : "",
				parameters.instancing ? "#define USE_INSTANCING" : "",
				parameters.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
				parameters.instancingMorph ? "#define USE_INSTANCING_MORPH" : "",

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.map ? "#define USE_MAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",
				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				//

				parameters.mapUv ? "#define MAP_UV " + parameters.mapUv : "",
				parameters.alphaMapUv ? "#define ALPHAMAP_UV " + parameters.alphaMapUv : "",
				parameters.lightMapUv ? "#define LIGHTMAP_UV " + parameters.lightMapUv : "",
				parameters.aoMapUv ? "#define AOMAP_UV " + parameters.aoMapUv : "",
				parameters.emissiveMapUv ? "#define EMISSIVEMAP_UV " + parameters.emissiveMapUv : "",
				parameters.bumpMapUv ? "#define BUMPMAP_UV " + parameters.bumpMapUv : "",
				parameters.normalMapUv ? "#define NORMALMAP_UV " + parameters.normalMapUv : "",
				parameters.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + parameters.displacementMapUv : "",

				parameters.metalnessMapUv ? "#define METALNESSMAP_UV " + parameters.metalnessMapUv : "",
				parameters.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + parameters.roughnessMapUv : "",

				parameters.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + parameters.anisotropyMapUv : "",

				parameters.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + parameters.clearcoatMapUv : "",
				parameters.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + parameters.clearcoatNormalMapUv : "",
				parameters.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + parameters.clearcoatRoughnessMapUv : "",

				parameters.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + parameters.iridescenceMapUv : "",
				parameters.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + parameters.iridescenceThicknessMapUv : "",

				parameters.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + parameters.sheenColorMapUv : "",
				parameters.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + parameters.sheenRoughnessMapUv : "",

				parameters.specularMapUv ? "#define SPECULARMAP_UV " + parameters.specularMapUv : "",
				parameters.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + parameters.specularColorMapUv : "",
				parameters.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + parameters.specularIntensityMapUv : "",

				parameters.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + parameters.transmissionMapUv : "",
				parameters.thicknessMapUv ? "#define THICKNESSMAP_UV " + parameters.thicknessMapUv : "",

				//

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.skinning ? "#define USE_SKINNING" : "",

				parameters.morphTargets ? "#define USE_MORPHTARGETS" : "",
				parameters.morphNormals && parameters.flatShading == false ? "#define USE_MORPHNORMALS" : "",
				(parameters.morphColors) ? "#define USE_MORPHCOLORS" : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_TEXTURE_STRIDE " + parameters.morphTextureStride : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_COUNT " + parameters.morphTargetsCount : "",
				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 modelMatrix;",
				"uniform mat4 modelViewMatrix;",
				"uniform mat4 projectionMatrix;",
				"uniform mat4 viewMatrix;",
				"uniform mat3 normalMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				"#ifdef USE_INSTANCING",

				"	attribute mat4 instanceMatrix;",

				"#endif",

				"#ifdef USE_INSTANCING_COLOR",

				"	attribute vec3 instanceColor;",

				"#endif",

				"#ifdef USE_INSTANCING_MORPH",

				"	uniform sampler2D morphTexture;",

				"#endif",

				"attribute vec3 position;",
				"attribute vec3 normal;",
				"attribute vec2 uv;",

				"#ifdef USE_UV1",

				"	attribute vec2 uv1;",

				"#endif",

				"#ifdef USE_UV2",

				"	attribute vec2 uv2;",

				"#endif",

				"#ifdef USE_UV3",

				"	attribute vec2 uv3;",

				"#endif",

				"#ifdef USE_TANGENT",

				"	attribute vec4 tangent;",

				"#endif",

				"#if defined( USE_COLOR_ALPHA )",

				"	attribute vec4 color;",

				"#elif defined( USE_COLOR )",

				"	attribute vec3 color;",

				"#endif",

				"#ifdef USE_SKINNING",

				"	attribute vec4 skinIndex;",
				"	attribute vec4 skinWeight;",

				"#endif",

				"\n"

			].filter(filterEmptyLine).join("\n");

			prefixFragment = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.alphaToCoverage ? "#define ALPHA_TO_COVERAGE" : "",
				parameters.map ? "#define USE_MAP" : "",
				parameters.matcap ? "#define USE_MATCAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapTypeDefine : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.envMap ? "#define " + envMapBlendingDefine : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_WIDTH " + envMapCubeUVSize.texelWidth : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_HEIGHT " + envMapCubeUVSize.texelHeight : "",
				envMapCubeUVSize != null ? "#define CUBEUV_MAX_MIP " + envMapCubeUVSize.maxMip + ".0" : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoat ? "#define USE_CLEARCOAT" : "",
				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.dispersion ? "#define USE_DISPERSION" : "",

				parameters.iridescence ? "#define USE_IRIDESCENCE" : "",
				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",

				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaTest ? "#define USE_ALPHATEST" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.sheen ? "#define USE_SHEEN" : "",
				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.gradientMap ? "#define USE_GRADIENTMAP" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 viewMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				(parameters.toneMapping != NoToneMapping) ? "#define TONE_MAPPING" : "",
				(parameters.toneMapping != NoToneMapping) ? ShaderChunk["tonemapping_pars_fragment"] : "", // this code is required here because it is used by the toneMapping() function defined below
				(parameters.toneMapping != NoToneMapping) ? getToneMappingFunction("toneMapping", parameters.toneMapping) : "",

				parameters.dithering ? "#define DITHERING" : "",
				parameters.opaque ? "#define OPAQUE" : "",

				ShaderChunk["colorspace_pars_fragment"], // this code is required here because it is used by the various encoding/decoding function defined below
				getTexelEncodingFunction("linearToOutputTexel", parameters.outputColorSpace),

				parameters.useDepthPacking ? "#define DEPTH_PACKING " + parameters.depthPacking : "",

				"\n"

			].filter(filterEmptyLine).join("\n");
		}

		vertexShader = resolveIncludes(vertexShader);
		vertexShader = replaceLightNums(vertexShader, parameters);
		vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

		fragmentShader = resolveIncludes(fragmentShader);
		fragmentShader = replaceLightNums(fragmentShader, parameters);
		fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

		vertexShader = unrollLoops(vertexShader);
		fragmentShader = unrollLoops(fragmentShader);

		if (parameters.isRawShaderMaterial != true) {
			// GLSL 3.0 conversion for built-in materials and ShaderMaterial

			versionString = "#version 300 es\n";

			prefixVertex = [
				customVertexExtensions,
				"#define attribute in",
				"#define varying out",
				"#define texture2D texture"
			].join("\n") + "\n" + prefixVertex;

			prefixFragment = [
				"#define varying in",
				(parameters.glslVersion == GLSL3) ? "" : "layout(location = 0) out high
import three.constants.ColorManagement;
import three.constants.NoToneMapping;
import three.constants.AddOperation;
import three.constants.MixOperation;
import three.constants.MultiplyOperation;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.CubeReflectionMapping;
import three.constants.PCFSoftShadowMap;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.AgXToneMapping;
import three.constants.ACESFilmicToneMapping;
import three.constants.NeutralToneMapping;
import three.constants.CineonToneMapping;
import three.constants.CustomToneMapping;
import three.constants.ReinhardToneMapping;
import three.constants.LinearToneMapping;
import three.constants.GLSL3;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.P3Primaries;
import three.constants.Rec709Primaries;
import three.shaders.ShaderChunk;
import three.webgl.WebGLShader;
import three.webgl.WebGLUniforms;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

class WebGLProgram {

	static programIdCount:Int = 0;

	static handleSource(string:String, errorLine:Int):String {
		var lines = string.split("\n");
		var lines2 = new Array<String>();

		var from = Math.max(errorLine - 6, 0);
		var to = Math.min(errorLine + 6, lines.length);

		for (var i in from...to) {
			var line = i + 1;
			lines2.push(line == errorLine ? "> " : "  " + line + ": " + lines[i]);
		}

		return lines2.join("\n");
	}

	static getEncodingComponents(colorSpace:Int):Array<String> {
		var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
		var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

		var gamutMapping:String;

		if (workingPrimaries == encodingPrimaries) {
			gamutMapping = "";
		} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
			gamutMapping = "LinearDisplayP3ToLinearSRGB";
		} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
			gamutMapping = "LinearSRGBToLinearDisplayP3";
		}

		switch (colorSpace) {
			case LinearSRGBColorSpace:
			case LinearDisplayP3ColorSpace:
				return [gamutMapping, "LinearTransferOETF"];
			case SRGBColorSpace:
			case DisplayP3ColorSpace:
				return [gamutMapping, "sRGBTransferOETF"];
			default:
				Sys.println("THREE.WebGLProgram: Unsupported color space:", colorSpace);
				return [gamutMapping, "LinearTransferOETF"];
		}
	}

	static getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
		var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		var errors = gl.getShaderInfoLog(shader).trim();

		if (status && errors == "") return "";

		var errorMatches = errors.match(/ERROR: 0:(\d+)/);
		if (errorMatches != null) {
			// --enable-privileged-webgl-extension
			// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

			var errorLine = Std.parseInt(errorMatches[1]);
			return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
		} else {
			return errors;
		}
	}

	static getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
		var components = getEncodingComponents(colorSpace);
		return "vec4 " + functionName + "( vec4 value ) { return " + components[0] + "( " + components[1] + "( value ) ); }";
	}

	static getToneMappingFunction(functionName:String, toneMapping:Int):String {
		var toneMappingName:String;

		switch (toneMapping) {
			case LinearToneMapping:
				toneMappingName = "Linear";
				break;
			case ReinhardToneMapping:
				toneMappingName = "Reinhard";
				break;
			case CineonToneMapping:
				toneMappingName = "OptimizedCineon";
				break;
			case ACESFilmicToneMapping:
				toneMappingName = "ACESFilmic";
				break;
			case AgXToneMapping:
				toneMappingName = "AgX";
				break;
			case NeutralToneMapping:
				toneMappingName = "Neutral";
				break;
			case CustomToneMapping:
				toneMappingName = "Custom";
				break;
			default:
				Sys.println("THREE.WebGLProgram: Unsupported toneMapping:", toneMapping);
				toneMappingName = "Linear";
		}

		return "vec3 " + functionName + "( vec3 color ) { return " + toneMappingName + "ToneMapping( color ); }";
	}

	static generateVertexExtensions(parameters:Dynamic):String {
		var chunks = new Array<String>();

		chunks.push(parameters.extensionClipCullDistance ? "#extension GL_ANGLE_clip_cull_distance : require" : "");
		chunks.push(parameters.extensionMultiDraw ? "#extension GL_ANGLE_multi_draw : require" : "");

		return chunks.filter(filterEmptyLine).join("\n");
	}

	static generateDefines(defines:Dynamic):String {
		var chunks = new Array<String>();

		for (var name in defines) {
			var value = defines[name];

			if (value == false) continue;

			chunks.push("#define " + name + " " + value);
		}

		return chunks.join("\n");
	}

	static fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):Dynamic {
		var attributes = new Dynamic();

		var n = gl.getProgramParameter(program.program, gl.ACTIVE_ATTRIBUTES);

		for (var i in 0...n) {
			var info = gl.getActiveAttrib(program.program, i);
			var name = info.name;

			var locationSize = 1;
			if (info.type == gl.FLOAT_MAT2) locationSize = 2;
			if (info.type == gl.FLOAT_MAT3) locationSize = 3;
			if (info.type == gl.FLOAT_MAT4) locationSize = 4;

			// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

			attributes[name] = {
				type: info.type,
				location: gl.getAttribLocation(program.program, name),
				locationSize: locationSize
			};
		}

		return attributes;
	}

	static filterEmptyLine(string:String):Bool {
		return string != "";
	}

	static replaceLightNums(string:String, parameters:Dynamic):String {
		var numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		return string
			.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights.toString())
			.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights.toString())
			.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps.toString())
			.replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords.toString())
			.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights.toString())
			.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights.toString())
			.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights.toString())
			.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows.toString())
			.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows.toString());
	}

	static replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
		return string
			.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes.toString())
			.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection).toString());
	}

	// Resolve Includes

	static includePattern = ~r"^[ \t]*#include +<([\w\d./]+)>";

	static resolveIncludes(string:String):String {
		return string.replace(includePattern, includeReplacer);
	}

	static shaderChunkMap = new Map<String, String>();

	static includeReplacer(match:String, include:String):String {
		var string = ShaderChunk[include];

		if (string == null) {
			var newInclude = shaderChunkMap.get(include);

			if (newInclude != null) {
				string = ShaderChunk[newInclude];
				Sys.println("THREE.WebGLRenderer: Shader chunk \"" + include + "\" has been deprecated. Use \"" + newInclude + "\" instead.");
			} else {
				throw new Error("Can not resolve #include <" + include + ">");
			}
		}

		return resolveIncludes(string);
	}

	// Unroll Loops

	static unrollLoopPattern = ~r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end";

	static unrollLoops(string:String):String {
		return string.replace(unrollLoopPattern, loopReplacer);
	}

	static loopReplacer(match:String, start:String, end:String, snippet:String):String {
		var string = "";

		for (var i in Std.parseInt(start)...Std.parseInt(end)) {
			string += snippet
				.replace(/\[\s*i\s*\]/g, "[ " + i + " ]")
				.replace(/UNROLLED_LOOP_INDEX/g, i.toString());
		}

		return string;
	}

	//

	static generatePrecision(parameters:Dynamic):String {
		var precisionstring = "precision " + parameters.precision + " float;\n" +
			"precision " + parameters.precision + " int;\n" +
			"precision " + parameters.precision + " sampler2D;\n" +
			"precision " + parameters.precision + " samplerCube;\n" +
			"precision " + parameters.precision + " sampler3D;\n" +
			"precision " + parameters.precision + " sampler2DArray;\n" +
			"precision " + parameters.precision + " sampler2DShadow;\n" +
			"precision " + parameters.precision + " samplerCubeShadow;\n" +
			"precision " + parameters.precision + " sampler2DArrayShadow;\n" +
			"precision " + parameters.precision + " isampler2D;\n" +
			"precision " + parameters.precision + " isampler3D;\n" +
			"precision " + parameters.precision + " isamplerCube;\n" +
			"precision " + parameters.precision + " isampler2DArray;\n" +
			"precision " + parameters.precision + " usampler2D;\n" +
			"precision " + parameters.precision + " usampler3D;\n" +
			"precision " + parameters.precision + " usamplerCube;\n" +
			"precision " + parameters.precision + " usampler2DArray;\n";

		if (parameters.precision == "highp") {
			precisionstring += "\n#define HIGH_PRECISION";
		} else if (parameters.precision == "mediump") {
			precisionstring += "\n#define MEDIUM_PRECISION";
		} else if (parameters.precision == "lowp") {
			precisionstring += "\n#define LOW_PRECISION";
		}

		return precisionstring;
	}

	static generateShadowMapTypeDefine(parameters:Dynamic):String {
		var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

		if (parameters.shadowMapType == PCFShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
		} else if (parameters.shadowMapType == PCFSoftShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
		} else if (parameters.shadowMapType == VSMShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_VSM";
		}

		return shadowMapTypeDefine;
	}

	static generateEnvMapTypeDefine(parameters:Dynamic):String {
		var envMapTypeDefine = "ENVMAP_TYPE_CUBE";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeReflectionMapping:
				case CubeRefractionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE";
					break;
				case CubeUVReflectionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE_UV";
					break;
			}
		}

		return envMapTypeDefine;
	}

	static generateEnvMapModeDefine(parameters:Dynamic):String {
		var envMapModeDefine = "ENVMAP_MODE_REFLECTION";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeRefractionMapping:
					envMapModeDefine = "ENVMAP_MODE_REFRACTION";
					break;
			}
		}

		return envMapModeDefine;
	}

	static generateEnvMapBlendingDefine(parameters:Dynamic):String {
		var envMapBlendingDefine = "ENVMAP_BLENDING_NONE";

		if (parameters.envMap != null) {
			switch (parameters.combine) {
				case MultiplyOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MULTIPLY";
					break;
				case MixOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MIX";
					break;
				case AddOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_ADD";
					break;
			}
		}

		return envMapBlendingDefine;
	}

	static generateCubeUVSize(parameters:Dynamic):Dynamic {
		var imageHeight = parameters.envMapCubeUVHeight;

		if (imageHeight == null) return null;

		var maxMip = Math.log2(imageHeight) - 2;

		var texelHeight = 1.0 / imageHeight;

		var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

		return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
	}

	program:WebGLProgram;
	vertexShader:WebGLShader;
	fragmentShader:WebGLShader;
	type:String;
	name:String;
	id:Int;
	cacheKey:String;
	usedTimes:Int;
	cachedUniforms:WebGLUniforms;
	cachedAttributes:Dynamic;
	diagnostics:Dynamic;
	isReady:Bool;

	function new(renderer:Dynamic, cacheKey:String, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

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

		this.program = gl.createProgram();

		var prefixVertex:String;
		var prefixFragment:String;
		var versionString:String = parameters.glslVersion != null ? "#version " + parameters.glslVersion + "\n" : "";

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixVertex.length > 0) {
				prefixVertex += "\n";
			}

			prefixFragment = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixFragment.length > 0) {
				prefixFragment += "\n";
			}
		} else {
			prefixVertex = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.extensionClipCullDistance ? "#define USE_CLIP_DISTANCE" : "",
				parameters.batching ? "#define USE_BATCHING" : "",
				parameters.batchingColor ? "#define USE_BATCHING_COLOR" : "",
				parameters.instancing ? "#define USE_INSTANCING" : "",
				parameters.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
				parameters.instancingMorph ? "#define USE_INSTANCING_MORPH" : "",

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.map ? "#define USE_MAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",
				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				//

				parameters.mapUv ? "#define MAP_UV " + parameters.mapUv : "",
				parameters.alphaMapUv ? "#define ALPHAMAP_UV " + parameters.alphaMapUv : "",
				parameters.lightMapUv ? "#define LIGHTMAP_UV " + parameters.lightMapUv : "",
				parameters.aoMapUv ? "#define AOMAP_UV " + parameters.aoMapUv : "",
				parameters.emissiveMapUv ? "#define EMISSIVEMAP_UV " + parameters.emissiveMapUv : "",
				parameters.bumpMapUv ? "#define BUMPMAP_UV " + parameters.bumpMapUv : "",
				parameters.normalMapUv ? "#define NORMALMAP_UV " + parameters.normalMapUv : "",
				parameters.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + parameters.displacementMapUv : "",

				parameters.metalnessMapUv ? "#define METALNESSMAP_UV " + parameters.metalnessMapUv : "",
				parameters.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + parameters.roughnessMapUv : "",

				parameters.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + parameters.anisotropyMapUv : "",

				parameters.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + parameters.clearcoatMapUv : "",
				parameters.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + parameters.clearcoatNormalMapUv : "",
				parameters.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + parameters.clearcoatRoughnessMapUv : "",

				parameters.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + parameters.iridescenceMapUv : "",
				parameters.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + parameters.iridescenceThicknessMapUv : "",

				parameters.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + parameters.sheenColorMapUv : "",
				parameters.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + parameters.sheenRoughnessMapUv : "",

				parameters.specularMapUv ? "#define SPECULARMAP_UV " + parameters.specularMapUv : "",
				parameters.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + parameters.specularColorMapUv : "",
				parameters.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + parameters.specularIntensityMapUv : "",

				parameters.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + parameters.transmissionMapUv : "",
				parameters.thicknessMapUv ? "#define THICKNESSMAP_UV " + parameters.thicknessMapUv : "",

				//

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.skinning ? "#define USE_SKINNING" : "",

				parameters.morphTargets ? "#define USE_MORPHTARGETS" : "",
				parameters.morphNormals && parameters.flatShading == false ? "#define USE_MORPHNORMALS" : "",
				(parameters.morphColors) ? "#define USE_MORPHCOLORS" : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_TEXTURE_STRIDE " + parameters.morphTextureStride : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_COUNT " + parameters.morphTargetsCount : "",
				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 modelMatrix;",
				"uniform mat4 modelViewMatrix;",
				"uniform mat4 projectionMatrix;",
				"uniform mat4 viewMatrix;",
				"uniform mat3 normalMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				"#ifdef USE_INSTANCING",

				"	attribute mat4 instanceMatrix;",

				"#endif",

				"#ifdef USE_INSTANCING_COLOR",

				"	attribute vec3 instanceColor;",

				"#endif",

				"#ifdef USE_INSTANCING_MORPH",

				"	uniform sampler2D morphTexture;",

				"#endif",

				"attribute vec3 position;",
				"attribute vec3 normal;",
				"attribute vec2 uv;",

				"#ifdef USE_UV1",

				"	attribute vec2 uv1;",

				"#endif",

				"#ifdef USE_UV2",

				"	attribute vec2 uv2;",

				"#endif",

				"#ifdef USE_UV3",

				"	attribute vec2 uv3;",

				"#endif",

				"#ifdef USE_TANGENT",

				"	attribute vec4 tangent;",

				"#endif",

				"#if defined( USE_COLOR_ALPHA )",

				"	attribute vec4 color;",

				"#elif defined( USE_COLOR )",

				"	attribute vec3 color;",

				"#endif",

				"#ifdef USE_SKINNING",

				"	attribute vec4 skinIndex;",
				"	attribute vec4 skinWeight;",

				"#endif",

				"\n"

			].filter(filterEmptyLine).join("\n");

			prefixFragment = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.alphaToCoverage ? "#define ALPHA_TO_COVERAGE" : "",
				parameters.map ? "#define USE_MAP" : "",
				parameters.matcap ? "#define USE_MATCAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapTypeDefine : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.envMap ? "#define " + envMapBlendingDefine : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_WIDTH " + envMapCubeUVSize.texelWidth : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_HEIGHT " + envMapCubeUVSize.texelHeight : "",
				envMapCubeUVSize != null ? "#define CUBEUV_MAX_MIP " + envMapCubeUVSize.maxMip + ".0" : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoat ? "#define USE_CLEARCOAT" : "",
				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.dispersion ? "#define USE_DISPERSION" : "",

				parameters.iridescence ? "#define USE_IRIDESCENCE" : "",
				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",

				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaTest ? "#define USE_ALPHATEST" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.sheen ? "#define USE_SHEEN" : "",
				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.gradientMap ? "#define USE_GRADIENTMAP" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 viewMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				(parameters.toneMapping != NoToneMapping) ? "#define TONE_MAPPING" : "",
				(parameters.toneMapping != NoToneMapping) ? ShaderChunk["tonemapping_pars_fragment"] : "", // this code is required here because it is used by the toneMapping() function defined below
				(parameters.toneMapping != NoToneMapping) ? getToneMappingFunction("toneMapping", parameters.toneMapping) : "",

				parameters.dithering ? "#define DITHERING" : "",
				parameters.opaque ? "#define OPAQUE" : "",

				ShaderChunk["colorspace_pars_fragment"], // this code is required here because it is used by the various encoding/decoding function defined below
				getTexelEncodingFunction("linearToOutputTexel", parameters.outputColorSpace),

				parameters.useDepthPacking ? "#define DEPTH_PACKING " + parameters.depthPacking : "",

				"\n"

			].filter(filterEmptyLine).join("\n");
		}

		vertexShader = resolveIncludes(vertexShader);
		vertexShader = replaceLightNums(vertexShader, parameters);
		vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

		fragmentShader = resolveIncludes(fragmentShader);
		fragmentShader = replaceLightNums(fragmentShader, parameters);
		fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

		vertexShader = unrollLoops(vertexShader);
		fragmentShader = unrollLoops(fragmentShader);

		if (parameters.isRawShaderMaterial != true) {
			// GLSL 3.0 conversion for built-in materials and ShaderMaterial

			versionString = "#version 300 es\n";

			prefixVertex = [
				customVertexExtensions,
				"#define attribute in",
				"#define varying out",
				"#define texture2D texture"
			].join("\n") + "\n" + prefixVertex;

			prefixFragment = [
				"#define varying in",
				(parameters.glslVersion == GLSL3) ? "" : "layout(location = 0) out high
import three.constants.ColorManagement;
import three.constants.NoToneMapping;
import three.constants.AddOperation;
import three.constants.MixOperation;
import three.constants.MultiplyOperation;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.CubeReflectionMapping;
import three.constants.PCFSoftShadowMap;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.AgXToneMapping;
import three.constants.ACESFilmicToneMapping;
import three.constants.NeutralToneMapping;
import three.constants.CineonToneMapping;
import three.constants.CustomToneMapping;
import three.constants.ReinhardToneMapping;
import three.constants.LinearToneMapping;
import three.constants.GLSL3;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.P3Primaries;
import three.constants.Rec709Primaries;
import three.shaders.ShaderChunk;
import three.webgl.WebGLShader;
import three.webgl.WebGLUniforms;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

class WebGLProgram {

	static programIdCount:Int = 0;

	static handleSource(string:String, errorLine:Int):String {
		var lines = string.split("\n");
		var lines2 = new Array<String>();

		var from = Math.max(errorLine - 6, 0);
		var to = Math.min(errorLine + 6, lines.length);

		for (var i in from...to) {
			var line = i + 1;
			lines2.push(line == errorLine ? "> " : "  " + line + ": " + lines[i]);
		}

		return lines2.join("\n");
	}

	static getEncodingComponents(colorSpace:Int):Array<String> {
		var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
		var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

		var gamutMapping:String;

		if (workingPrimaries == encodingPrimaries) {
			gamutMapping = "";
		} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
			gamutMapping = "LinearDisplayP3ToLinearSRGB";
		} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
			gamutMapping = "LinearSRGBToLinearDisplayP3";
		}

		switch (colorSpace) {
			case LinearSRGBColorSpace:
			case LinearDisplayP3ColorSpace:
				return [gamutMapping, "LinearTransferOETF"];
			case SRGBColorSpace:
			case DisplayP3ColorSpace:
				return [gamutMapping, "sRGBTransferOETF"];
			default:
				Sys.println("THREE.WebGLProgram: Unsupported color space:", colorSpace);
				return [gamutMapping, "LinearTransferOETF"];
		}
	}

	static getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
		var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		var errors = gl.getShaderInfoLog(shader).trim();

		if (status && errors == "") return "";

		var errorMatches = errors.match(/ERROR: 0:(\d+)/);
		if (errorMatches != null) {
			// --enable-privileged-webgl-extension
			// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

			var errorLine = Std.parseInt(errorMatches[1]);
			return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
		} else {
			return errors;
		}
	}

	static getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
		var components = getEncodingComponents(colorSpace);
		return "vec4 " + functionName + "( vec4 value ) { return " + components[0] + "( " + components[1] + "( value ) ); }";
	}

	static getToneMappingFunction(functionName:String, toneMapping:Int):String {
		var toneMappingName:String;

		switch (toneMapping) {
			case LinearToneMapping:
				toneMappingName = "Linear";
				break;
			case ReinhardToneMapping:
				toneMappingName = "Reinhard";
				break;
			case CineonToneMapping:
				toneMappingName = "OptimizedCineon";
				break;
			case ACESFilmicToneMapping:
				toneMappingName = "ACESFilmic";
				break;
			case AgXToneMapping:
				toneMappingName = "AgX";
				break;
			case NeutralToneMapping:
				toneMappingName = "Neutral";
				break;
			case CustomToneMapping:
				toneMappingName = "Custom";
				break;
			default:
				Sys.println("THREE.WebGLProgram: Unsupported toneMapping:", toneMapping);
				toneMappingName = "Linear";
		}

		return "vec3 " + functionName + "( vec3 color ) { return " + toneMappingName + "ToneMapping( color ); }";
	}

	static generateVertexExtensions(parameters:Dynamic):String {
		var chunks = new Array<String>();

		chunks.push(parameters.extensionClipCullDistance ? "#extension GL_ANGLE_clip_cull_distance : require" : "");
		chunks.push(parameters.extensionMultiDraw ? "#extension GL_ANGLE_multi_draw : require" : "");

		return chunks.filter(filterEmptyLine).join("\n");
	}

	static generateDefines(defines:Dynamic):String {
		var chunks = new Array<String>();

		for (var name in defines) {
			var value = defines[name];

			if (value == false) continue;

			chunks.push("#define " + name + " " + value);
		}

		return chunks.join("\n");
	}

	static fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):Dynamic {
		var attributes = new Dynamic();

		var n = gl.getProgramParameter(program.program, gl.ACTIVE_ATTRIBUTES);

		for (var i in 0...n) {
			var info = gl.getActiveAttrib(program.program, i);
			var name = info.name;

			var locationSize = 1;
			if (info.type == gl.FLOAT_MAT2) locationSize = 2;
			if (info.type == gl.FLOAT_MAT3) locationSize = 3;
			if (info.type == gl.FLOAT_MAT4) locationSize = 4;

			// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

			attributes[name] = {
				type: info.type,
				location: gl.getAttribLocation(program.program, name),
				locationSize: locationSize
			};
		}

		return attributes;
	}

	static filterEmptyLine(string:String):Bool {
		return string != "";
	}

	static replaceLightNums(string:String, parameters:Dynamic):String {
		var numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		return string
			.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights.toString())
			.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights.toString())
			.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps.toString())
			.replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords.toString())
			.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights.toString())
			.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights.toString())
			.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights.toString())
			.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows.toString())
			.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows.toString());
	}

	static replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
		return string
			.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes.toString())
			.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection).toString());
	}

	// Resolve Includes

	static includePattern = ~r"^[ \t]*#include +<([\w\d./]+)>";

	static resolveIncludes(string:String):String {
		return string.replace(includePattern, includeReplacer);
	}

	static shaderChunkMap = new Map<String, String>();

	static includeReplacer(match:String, include:String):String {
		var string = ShaderChunk[include];

		if (string == null) {
			var newInclude = shaderChunkMap.get(include);

			if (newInclude != null) {
				string = ShaderChunk[newInclude];
				Sys.println("THREE.WebGLRenderer: Shader chunk \"" + include + "\" has been deprecated. Use \"" + newInclude + "\" instead.");
			} else {
				throw new Error("Can not resolve #include <" + include + ">");
			}
		}

		return resolveIncludes(string);
	}

	// Unroll Loops

	static unrollLoopPattern = ~r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end";

	static unrollLoops(string:String):String {
		return string.replace(unrollLoopPattern, loopReplacer);
	}

	static loopReplacer(match:String, start:String, end:String, snippet:String):String {
		var string = "";

		for (var i in Std.parseInt(start)...Std.parseInt(end)) {
			string += snippet
				.replace(/\[\s*i\s*\]/g, "[ " + i + " ]")
				.replace(/UNROLLED_LOOP_INDEX/g, i.toString());
		}

		return string;
	}

	//

	static generatePrecision(parameters:Dynamic):String {
		var precisionstring = "precision " + parameters.precision + " float;\n" +
			"precision " + parameters.precision + " int;\n" +
			"precision " + parameters.precision + " sampler2D;\n" +
			"precision " + parameters.precision + " samplerCube;\n" +
			"precision " + parameters.precision + " sampler3D;\n" +
			"precision " + parameters.precision + " sampler2DArray;\n" +
			"precision " + parameters.precision + " sampler2DShadow;\n" +
			"precision " + parameters.precision + " samplerCubeShadow;\n" +
			"precision " + parameters.precision + " sampler2DArrayShadow;\n" +
			"precision " + parameters.precision + " isampler2D;\n" +
			"precision " + parameters.precision + " isampler3D;\n" +
			"precision " + parameters.precision + " isamplerCube;\n" +
			"precision " + parameters.precision + " isampler2DArray;\n" +
			"precision " + parameters.precision + " usampler2D;\n" +
			"precision " + parameters.precision + " usampler3D;\n" +
			"precision " + parameters.precision + " usamplerCube;\n" +
			"precision " + parameters.precision + " usampler2DArray;\n";

		if (parameters.precision == "highp") {
			precisionstring += "\n#define HIGH_PRECISION";
		} else if (parameters.precision == "mediump") {
			precisionstring += "\n#define MEDIUM_PRECISION";
		} else if (parameters.precision == "lowp") {
			precisionstring += "\n#define LOW_PRECISION";
		}

		return precisionstring;
	}

	static generateShadowMapTypeDefine(parameters:Dynamic):String {
		var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

		if (parameters.shadowMapType == PCFShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
		} else if (parameters.shadowMapType == PCFSoftShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
		} else if (parameters.shadowMapType == VSMShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_VSM";
		}

		return shadowMapTypeDefine;
	}

	static generateEnvMapTypeDefine(parameters:Dynamic):String {
		var envMapTypeDefine = "ENVMAP_TYPE_CUBE";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeReflectionMapping:
				case CubeRefractionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE";
					break;
				case CubeUVReflectionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE_UV";
					break;
			}
		}

		return envMapTypeDefine;
	}

	static generateEnvMapModeDefine(parameters:Dynamic):String {
		var envMapModeDefine = "ENVMAP_MODE_REFLECTION";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeRefractionMapping:
					envMapModeDefine = "ENVMAP_MODE_REFRACTION";
					break;
			}
		}

		return envMapModeDefine;
	}

	static generateEnvMapBlendingDefine(parameters:Dynamic):String {
		var envMapBlendingDefine = "ENVMAP_BLENDING_NONE";

		if (parameters.envMap != null) {
			switch (parameters.combine) {
				case MultiplyOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MULTIPLY";
					break;
				case MixOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MIX";
					break;
				case AddOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_ADD";
					break;
			}
		}

		return envMapBlendingDefine;
	}

	static generateCubeUVSize(parameters:Dynamic):Dynamic {
		var imageHeight = parameters.envMapCubeUVHeight;

		if (imageHeight == null) return null;

		var maxMip = Math.log2(imageHeight) - 2;

		var texelHeight = 1.0 / imageHeight;

		var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

		return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
	}

	program:WebGLProgram;
	vertexShader:WebGLShader;
	fragmentShader:WebGLShader;
	type:String;
	name:String;
	id:Int;
	cacheKey:String;
	usedTimes:Int;
	cachedUniforms:WebGLUniforms;
	cachedAttributes:Dynamic;
	diagnostics:Dynamic;
	isReady:Bool;

	function new(renderer:Dynamic, cacheKey:String, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

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

		this.program = gl.createProgram();

		var prefixVertex:String;
		var prefixFragment:String;
		var versionString:String = parameters.glslVersion != null ? "#version " + parameters.glslVersion + "\n" : "";

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixVertex.length > 0) {
				prefixVertex += "\n";
			}

			prefixFragment = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixFragment.length > 0) {
				prefixFragment += "\n";
			}
		} else {
			prefixVertex = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.extensionClipCullDistance ? "#define USE_CLIP_DISTANCE" : "",
				parameters.batching ? "#define USE_BATCHING" : "",
				parameters.batchingColor ? "#define USE_BATCHING_COLOR" : "",
				parameters.instancing ? "#define USE_INSTANCING" : "",
				parameters.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
				parameters.instancingMorph ? "#define USE_INSTANCING_MORPH" : "",

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.map ? "#define USE_MAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",
				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				//

				parameters.mapUv ? "#define MAP_UV " + parameters.mapUv : "",
				parameters.alphaMapUv ? "#define ALPHAMAP_UV " + parameters.alphaMapUv : "",
				parameters.lightMapUv ? "#define LIGHTMAP_UV " + parameters.lightMapUv : "",
				parameters.aoMapUv ? "#define AOMAP_UV " + parameters.aoMapUv : "",
				parameters.emissiveMapUv ? "#define EMISSIVEMAP_UV " + parameters.emissiveMapUv : "",
				parameters.bumpMapUv ? "#define BUMPMAP_UV " + parameters.bumpMapUv : "",
				parameters.normalMapUv ? "#define NORMALMAP_UV " + parameters.normalMapUv : "",
				parameters.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + parameters.displacementMapUv : "",

				parameters.metalnessMapUv ? "#define METALNESSMAP_UV " + parameters.metalnessMapUv : "",
				parameters.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + parameters.roughnessMapUv : "",

				parameters.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + parameters.anisotropyMapUv : "",

				parameters.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + parameters.clearcoatMapUv : "",
				parameters.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + parameters.clearcoatNormalMapUv : "",
				parameters.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + parameters.clearcoatRoughnessMapUv : "",

				parameters.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + parameters.iridescenceMapUv : "",
				parameters.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + parameters.iridescenceThicknessMapUv : "",

				parameters.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + parameters.sheenColorMapUv : "",
				parameters.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + parameters.sheenRoughnessMapUv : "",

				parameters.specularMapUv ? "#define SPECULARMAP_UV " + parameters.specularMapUv : "",
				parameters.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + parameters.specularColorMapUv : "",
				parameters.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + parameters.specularIntensityMapUv : "",

				parameters.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + parameters.transmissionMapUv : "",
				parameters.thicknessMapUv ? "#define THICKNESSMAP_UV " + parameters.thicknessMapUv : "",

				//

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.skinning ? "#define USE_SKINNING" : "",

				parameters.morphTargets ? "#define USE_MORPHTARGETS" : "",
				parameters.morphNormals && parameters.flatShading == false ? "#define USE_MORPHNORMALS" : "",
				(parameters.morphColors) ? "#define USE_MORPHCOLORS" : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_TEXTURE_STRIDE " + parameters.morphTextureStride : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_COUNT " + parameters.morphTargetsCount : "",
				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 modelMatrix;",
				"uniform mat4 modelViewMatrix;",
				"uniform mat4 projectionMatrix;",
				"uniform mat4 viewMatrix;",
				"uniform mat3 normalMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				"#ifdef USE_INSTANCING",

				"	attribute mat4 instanceMatrix;",

				"#endif",

				"#ifdef USE_INSTANCING_COLOR",

				"	attribute vec3 instanceColor;",

				"#endif",

				"#ifdef USE_INSTANCING_MORPH",

				"	uniform sampler2D morphTexture;",

				"#endif",

				"attribute vec3 position;",
				"attribute vec3 normal;",
				"attribute vec2 uv;",

				"#ifdef USE_UV1",

				"	attribute vec2 uv1;",

				"#endif",

				"#ifdef USE_UV2",

				"	attribute vec2 uv2;",

				"#endif",

				"#ifdef USE_UV3",

				"	attribute vec2 uv3;",

				"#endif",

				"#ifdef USE_TANGENT",

				"	attribute vec4 tangent;",

				"#endif",

				"#if defined( USE_COLOR_ALPHA )",

				"	attribute vec4 color;",

				"#elif defined( USE_COLOR )",

				"	attribute vec3 color;",

				"#endif",

				"#ifdef USE_SKINNING",

				"	attribute vec4 skinIndex;",
				"	attribute vec4 skinWeight;",

				"#endif",

				"\n"

			].filter(filterEmptyLine).join("\n");

			prefixFragment = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.alphaToCoverage ? "#define ALPHA_TO_COVERAGE" : "",
				parameters.map ? "#define USE_MAP" : "",
				parameters.matcap ? "#define USE_MATCAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapTypeDefine : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.envMap ? "#define " + envMapBlendingDefine : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_WIDTH " + envMapCubeUVSize.texelWidth : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_HEIGHT " + envMapCubeUVSize.texelHeight : "",
				envMapCubeUVSize != null ? "#define CUBEUV_MAX_MIP " + envMapCubeUVSize.maxMip + ".0" : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoat ? "#define USE_CLEARCOAT" : "",
				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.dispersion ? "#define USE_DISPERSION" : "",

				parameters.iridescence ? "#define USE_IRIDESCENCE" : "",
				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",

				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaTest ? "#define USE_ALPHATEST" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.sheen ? "#define USE_SHEEN" : "",
				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.gradientMap ? "#define USE_GRADIENTMAP" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 viewMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				(parameters.toneMapping != NoToneMapping) ? "#define TONE_MAPPING" : "",
				(parameters.toneMapping != NoToneMapping) ? ShaderChunk["tonemapping_pars_fragment"] : "", // this code is required here because it is used by the toneMapping() function defined below
				(parameters.toneMapping != NoToneMapping) ? getToneMappingFunction("toneMapping", parameters.toneMapping) : "",

				parameters.dithering ? "#define DITHERING" : "",
				parameters.opaque ? "#define OPAQUE" : "",

				ShaderChunk["colorspace_pars_fragment"], // this code is required here because it is used by the various encoding/decoding function defined below
				getTexelEncodingFunction("linearToOutputTexel", parameters.outputColorSpace),

				parameters.useDepthPacking ? "#define DEPTH_PACKING " + parameters.depthPacking : "",

				"\n"

			].filter(filterEmptyLine).join("\n");
		}

		vertexShader = resolveIncludes(vertexShader);
		vertexShader = replaceLightNums(vertexShader, parameters);
		vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

		fragmentShader = resolveIncludes(fragmentShader);
		fragmentShader = replaceLightNums(fragmentShader, parameters);
		fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

		vertexShader = unrollLoops(vertexShader);
		fragmentShader = unrollLoops(fragmentShader);

		if (parameters.isRawShaderMaterial != true) {
			// GLSL 3.0 conversion for built-in materials and ShaderMaterial

			versionString = "#version 300 es\n";

			prefixVertex = [
				customVertexExtensions,
				"#define attribute in",
				"#define varying out",
				"#define texture2D texture"
			].join("\n") + "\n" + prefixVertex;

			prefixFragment = [
				"#define varying in",
				(parameters.glslVersion == GLSL3) ? "" : "layout(location = 0) out high
import three.constants.ColorManagement;
import three.constants.NoToneMapping;
import three.constants.AddOperation;
import three.constants.MixOperation;
import three.constants.MultiplyOperation;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.CubeReflectionMapping;
import three.constants.PCFSoftShadowMap;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.AgXToneMapping;
import three.constants.ACESFilmicToneMapping;
import three.constants.NeutralToneMapping;
import three.constants.CineonToneMapping;
import three.constants.CustomToneMapping;
import three.constants.ReinhardToneMapping;
import three.constants.LinearToneMapping;
import three.constants.GLSL3;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.P3Primaries;
import three.constants.Rec709Primaries;
import three.shaders.ShaderChunk;
import three.webgl.WebGLShader;
import three.webgl.WebGLUniforms;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

class WebGLProgram {

	static programIdCount:Int = 0;

	static handleSource(string:String, errorLine:Int):String {
		var lines = string.split("\n");
		var lines2 = new Array<String>();

		var from = Math.max(errorLine - 6, 0);
		var to = Math.min(errorLine + 6, lines.length);

		for (var i in from...to) {
			var line = i + 1;
			lines2.push(line == errorLine ? "> " : "  " + line + ": " + lines[i]);
		}

		return lines2.join("\n");
	}

	static getEncodingComponents(colorSpace:Int):Array<String> {
		var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
		var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

		var gamutMapping:String;

		if (workingPrimaries == encodingPrimaries) {
			gamutMapping = "";
		} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
			gamutMapping = "LinearDisplayP3ToLinearSRGB";
		} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
			gamutMapping = "LinearSRGBToLinearDisplayP3";
		}

		switch (colorSpace) {
			case LinearSRGBColorSpace:
			case LinearDisplayP3ColorSpace:
				return [gamutMapping, "LinearTransferOETF"];
			case SRGBColorSpace:
			case DisplayP3ColorSpace:
				return [gamutMapping, "sRGBTransferOETF"];
			default:
				Sys.println("THREE.WebGLProgram: Unsupported color space:", colorSpace);
				return [gamutMapping, "LinearTransferOETF"];
		}
	}

	static getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
		var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		var errors = gl.getShaderInfoLog(shader).trim();

		if (status && errors == "") return "";

		var errorMatches = errors.match(/ERROR: 0:(\d+)/);
		if (errorMatches != null) {
			// --enable-privileged-webgl-extension
			// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

			var errorLine = Std.parseInt(errorMatches[1]);
			return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
		} else {
			return errors;
		}
	}

	static getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
		var components = getEncodingComponents(colorSpace);
		return "vec4 " + functionName + "( vec4 value ) { return " + components[0] + "( " + components[1] + "( value ) ); }";
	}

	static getToneMappingFunction(functionName:String, toneMapping:Int):String {
		var toneMappingName:String;

		switch (toneMapping) {
			case LinearToneMapping:
				toneMappingName = "Linear";
				break;
			case ReinhardToneMapping:
				toneMappingName = "Reinhard";
				break;
			case CineonToneMapping:
				toneMappingName = "OptimizedCineon";
				break;
			case ACESFilmicToneMapping:
				toneMappingName = "ACESFilmic";
				break;
			case AgXToneMapping:
				toneMappingName = "AgX";
				break;
			case NeutralToneMapping:
				toneMappingName = "Neutral";
				break;
			case CustomToneMapping:
				toneMappingName = "Custom";
				break;
			default:
				Sys.println("THREE.WebGLProgram: Unsupported toneMapping:", toneMapping);
				toneMappingName = "Linear";
		}

		return "vec3 " + functionName + "( vec3 color ) { return " + toneMappingName + "ToneMapping( color ); }";
	}

	static generateVertexExtensions(parameters:Dynamic):String {
		var chunks = new Array<String>();

		chunks.push(parameters.extensionClipCullDistance ? "#extension GL_ANGLE_clip_cull_distance : require" : "");
		chunks.push(parameters.extensionMultiDraw ? "#extension GL_ANGLE_multi_draw : require" : "");

		return chunks.filter(filterEmptyLine).join("\n");
	}

	static generateDefines(defines:Dynamic):String {
		var chunks = new Array<String>();

		for (var name in defines) {
			var value = defines[name];

			if (value == false) continue;

			chunks.push("#define " + name + " " + value);
		}

		return chunks.join("\n");
	}

	static fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):Dynamic {
		var attributes = new Dynamic();

		var n = gl.getProgramParameter(program.program, gl.ACTIVE_ATTRIBUTES);

		for (var i in 0...n) {
			var info = gl.getActiveAttrib(program.program, i);
			var name = info.name;

			var locationSize = 1;
			if (info.type == gl.FLOAT_MAT2) locationSize = 2;
			if (info.type == gl.FLOAT_MAT3) locationSize = 3;
			if (info.type == gl.FLOAT_MAT4) locationSize = 4;

			// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

			attributes[name] = {
				type: info.type,
				location: gl.getAttribLocation(program.program, name),
				locationSize: locationSize
			};
		}

		return attributes;
	}

	static filterEmptyLine(string:String):Bool {
		return string != "";
	}

	static replaceLightNums(string:String, parameters:Dynamic):String {
		var numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		return string
			.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights.toString())
			.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights.toString())
			.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps.toString())
			.replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords.toString())
			.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights.toString())
			.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights.toString())
			.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights.toString())
			.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows.toString())
			.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows.toString());
	}

	static replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
		return string
			.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes.toString())
			.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection).toString());
	}

	// Resolve Includes

	static includePattern = ~r"^[ \t]*#include +<([\w\d./]+)>";

	static resolveIncludes(string:String):String {
		return string.replace(includePattern, includeReplacer);
	}

	static shaderChunkMap = new Map<String, String>();

	static includeReplacer(match:String, include:String):String {
		var string = ShaderChunk[include];

		if (string == null) {
			var newInclude = shaderChunkMap.get(include);

			if (newInclude != null) {
				string = ShaderChunk[newInclude];
				Sys.println("THREE.WebGLRenderer: Shader chunk \"" + include + "\" has been deprecated. Use \"" + newInclude + "\" instead.");
			} else {
				throw new Error("Can not resolve #include <" + include + ">");
			}
		}

		return resolveIncludes(string);
	}

	// Unroll Loops

	static unrollLoopPattern = ~r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end";

	static unrollLoops(string:String):String {
		return string.replace(unrollLoopPattern, loopReplacer);
	}

	static loopReplacer(match:String, start:String, end:String, snippet:String):String {
		var string = "";

		for (var i in Std.parseInt(start)...Std.parseInt(end)) {
			string += snippet
				.replace(/\[\s*i\s*\]/g, "[ " + i + " ]")
				.replace(/UNROLLED_LOOP_INDEX/g, i.toString());
		}

		return string;
	}

	//

	static generatePrecision(parameters:Dynamic):String {
		var precisionstring = "precision " + parameters.precision + " float;\n" +
			"precision " + parameters.precision + " int;\n" +
			"precision " + parameters.precision + " sampler2D;\n" +
			"precision " + parameters.precision + " samplerCube;\n" +
			"precision " + parameters.precision + " sampler3D;\n" +
			"precision " + parameters.precision + " sampler2DArray;\n" +
			"precision " + parameters.precision + " sampler2DShadow;\n" +
			"precision " + parameters.precision + " samplerCubeShadow;\n" +
			"precision " + parameters.precision + " sampler2DArrayShadow;\n" +
			"precision " + parameters.precision + " isampler2D;\n" +
			"precision " + parameters.precision + " isampler3D;\n" +
			"precision " + parameters.precision + " isamplerCube;\n" +
			"precision " + parameters.precision + " isampler2DArray;\n" +
			"precision " + parameters.precision + " usampler2D;\n" +
			"precision " + parameters.precision + " usampler3D;\n" +
			"precision " + parameters.precision + " usamplerCube;\n" +
			"precision " + parameters.precision + " usampler2DArray;\n";

		if (parameters.precision == "highp") {
			precisionstring += "\n#define HIGH_PRECISION";
		} else if (parameters.precision == "mediump") {
			precisionstring += "\n#define MEDIUM_PRECISION";
		} else if (parameters.precision == "lowp") {
			precisionstring += "\n#define LOW_PRECISION";
		}

		return precisionstring;
	}

	static generateShadowMapTypeDefine(parameters:Dynamic):String {
		var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

		if (parameters.shadowMapType == PCFShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
		} else if (parameters.shadowMapType == PCFSoftShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
		} else if (parameters.shadowMapType == VSMShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_VSM";
		}

		return shadowMapTypeDefine;
	}

	static generateEnvMapTypeDefine(parameters:Dynamic):String {
		var envMapTypeDefine = "ENVMAP_TYPE_CUBE";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeReflectionMapping:
				case CubeRefractionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE";
					break;
				case CubeUVReflectionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE_UV";
					break;
			}
		}

		return envMapTypeDefine;
	}

	static generateEnvMapModeDefine(parameters:Dynamic):String {
		var envMapModeDefine = "ENVMAP_MODE_REFLECTION";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeRefractionMapping:
					envMapModeDefine = "ENVMAP_MODE_REFRACTION";
					break;
			}
		}

		return envMapModeDefine;
	}

	static generateEnvMapBlendingDefine(parameters:Dynamic):String {
		var envMapBlendingDefine = "ENVMAP_BLENDING_NONE";

		if (parameters.envMap != null) {
			switch (parameters.combine) {
				case MultiplyOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MULTIPLY";
					break;
				case MixOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MIX";
					break;
				case AddOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_ADD";
					break;
			}
		}

		return envMapBlendingDefine;
	}

	static generateCubeUVSize(parameters:Dynamic):Dynamic {
		var imageHeight = parameters.envMapCubeUVHeight;

		if (imageHeight == null) return null;

		var maxMip = Math.log2(imageHeight) - 2;

		var texelHeight = 1.0 / imageHeight;

		var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

		return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
	}

	program:WebGLProgram;
	vertexShader:WebGLShader;
	fragmentShader:WebGLShader;
	type:String;
	name:String;
	id:Int;
	cacheKey:String;
	usedTimes:Int;
	cachedUniforms:WebGLUniforms;
	cachedAttributes:Dynamic;
	diagnostics:Dynamic;
	isReady:Bool;

	function new(renderer:Dynamic, cacheKey:String, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

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

		this.program = gl.createProgram();

		var prefixVertex:String;
		var prefixFragment:String;
		var versionString:String = parameters.glslVersion != null ? "#version " + parameters.glslVersion + "\n" : "";

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixVertex.length > 0) {
				prefixVertex += "\n";
			}

			prefixFragment = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixFragment.length > 0) {
				prefixFragment += "\n";
			}
		} else {
			prefixVertex = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.extensionClipCullDistance ? "#define USE_CLIP_DISTANCE" : "",
				parameters.batching ? "#define USE_BATCHING" : "",
				parameters.batchingColor ? "#define USE_BATCHING_COLOR" : "",
				parameters.instancing ? "#define USE_INSTANCING" : "",
				parameters.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
				parameters.instancingMorph ? "#define USE_INSTANCING_MORPH" : "",

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.map ? "#define USE_MAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",
				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				//

				parameters.mapUv ? "#define MAP_UV " + parameters.mapUv : "",
				parameters.alphaMapUv ? "#define ALPHAMAP_UV " + parameters.alphaMapUv : "",
				parameters.lightMapUv ? "#define LIGHTMAP_UV " + parameters.lightMapUv : "",
				parameters.aoMapUv ? "#define AOMAP_UV " + parameters.aoMapUv : "",
				parameters.emissiveMapUv ? "#define EMISSIVEMAP_UV " + parameters.emissiveMapUv : "",
				parameters.bumpMapUv ? "#define BUMPMAP_UV " + parameters.bumpMapUv : "",
				parameters.normalMapUv ? "#define NORMALMAP_UV " + parameters.normalMapUv : "",
				parameters.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + parameters.displacementMapUv : "",

				parameters.metalnessMapUv ? "#define METALNESSMAP_UV " + parameters.metalnessMapUv : "",
				parameters.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + parameters.roughnessMapUv : "",

				parameters.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + parameters.anisotropyMapUv : "",

				parameters.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + parameters.clearcoatMapUv : "",
				parameters.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + parameters.clearcoatNormalMapUv : "",
				parameters.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + parameters.clearcoatRoughnessMapUv : "",

				parameters.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + parameters.iridescenceMapUv : "",
				parameters.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + parameters.iridescenceThicknessMapUv : "",

				parameters.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + parameters.sheenColorMapUv : "",
				parameters.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + parameters.sheenRoughnessMapUv : "",

				parameters.specularMapUv ? "#define SPECULARMAP_UV " + parameters.specularMapUv : "",
				parameters.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + parameters.specularColorMapUv : "",
				parameters.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + parameters.specularIntensityMapUv : "",

				parameters.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + parameters.transmissionMapUv : "",
				parameters.thicknessMapUv ? "#define THICKNESSMAP_UV " + parameters.thicknessMapUv : "",

				//

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.skinning ? "#define USE_SKINNING" : "",

				parameters.morphTargets ? "#define USE_MORPHTARGETS" : "",
				parameters.morphNormals && parameters.flatShading == false ? "#define USE_MORPHNORMALS" : "",
				(parameters.morphColors) ? "#define USE_MORPHCOLORS" : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_TEXTURE_STRIDE " + parameters.morphTextureStride : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_COUNT " + parameters.morphTargetsCount : "",
				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 modelMatrix;",
				"uniform mat4 modelViewMatrix;",
				"uniform mat4 projectionMatrix;",
				"uniform mat4 viewMatrix;",
				"uniform mat3 normalMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				"#ifdef USE_INSTANCING",

				"	attribute mat4 instanceMatrix;",

				"#endif",

				"#ifdef USE_INSTANCING_COLOR",

				"	attribute vec3 instanceColor;",

				"#endif",

				"#ifdef USE_INSTANCING_MORPH",

				"	uniform sampler2D morphTexture;",

				"#endif",

				"attribute vec3 position;",
				"attribute vec3 normal;",
				"attribute vec2 uv;",

				"#ifdef USE_UV1",

				"	attribute vec2 uv1;",

				"#endif",

				"#ifdef USE_UV2",

				"	attribute vec2 uv2;",

				"#endif",

				"#ifdef USE_UV3",

				"	attribute vec2 uv3;",

				"#endif",

				"#ifdef USE_TANGENT",

				"	attribute vec4 tangent;",

				"#endif",

				"#if defined( USE_COLOR_ALPHA )",

				"	attribute vec4 color;",

				"#elif defined( USE_COLOR )",

				"	attribute vec3 color;",

				"#endif",

				"#ifdef USE_SKINNING",

				"	attribute vec4 skinIndex;",
				"	attribute vec4 skinWeight;",

				"#endif",

				"\n"

			].filter(filterEmptyLine).join("\n");

			prefixFragment = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.alphaToCoverage ? "#define ALPHA_TO_COVERAGE" : "",
				parameters.map ? "#define USE_MAP" : "",
				parameters.matcap ? "#define USE_MATCAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapTypeDefine : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.envMap ? "#define " + envMapBlendingDefine : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_WIDTH " + envMapCubeUVSize.texelWidth : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_HEIGHT " + envMapCubeUVSize.texelHeight : "",
				envMapCubeUVSize != null ? "#define CUBEUV_MAX_MIP " + envMapCubeUVSize.maxMip + ".0" : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoat ? "#define USE_CLEARCOAT" : "",
				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.dispersion ? "#define USE_DISPERSION" : "",

				parameters.iridescence ? "#define USE_IRIDESCENCE" : "",
				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",

				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaTest ? "#define USE_ALPHATEST" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.sheen ? "#define USE_SHEEN" : "",
				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.gradientMap ? "#define USE_GRADIENTMAP" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 viewMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				(parameters.toneMapping != NoToneMapping) ? "#define TONE_MAPPING" : "",
				(parameters.toneMapping != NoToneMapping) ? ShaderChunk["tonemapping_pars_fragment"] : "", // this code is required here because it is used by the toneMapping() function defined below
				(parameters.toneMapping != NoToneMapping) ? getToneMappingFunction("toneMapping", parameters.toneMapping) : "",

				parameters.dithering ? "#define DITHERING" : "",
				parameters.opaque ? "#define OPAQUE" : "",

				ShaderChunk["colorspace_pars_fragment"], // this code is required here because it is used by the various encoding/decoding function defined below
				getTexelEncodingFunction("linearToOutputTexel", parameters.outputColorSpace),

				parameters.useDepthPacking ? "#define DEPTH_PACKING " + parameters.depthPacking : "",

				"\n"

			].filter(filterEmptyLine).join("\n");
		}

		vertexShader = resolveIncludes(vertexShader);
		vertexShader = replaceLightNums(vertexShader, parameters);
		vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

		fragmentShader = resolveIncludes(fragmentShader);
		fragmentShader = replaceLightNums(fragmentShader, parameters);
		fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

		vertexShader = unrollLoops(vertexShader);
		fragmentShader = unrollLoops(fragmentShader);

		if (parameters.isRawShaderMaterial != true) {
			// GLSL 3.0 conversion for built-in materials and ShaderMaterial

			versionString = "#version 300 es\n";

			prefixVertex = [
				customVertexExtensions,
				"#define attribute in",
				"#define varying out",
				"#define texture2D texture"
			].join("\n") + "\n" + prefixVertex;

			prefixFragment = [
				"#define varying in",
				(parameters.glslVersion == GLSL3) ? "" : "layout(location = 0) out high
import three.constants.ColorManagement;
import three.constants.NoToneMapping;
import three.constants.AddOperation;
import three.constants.MixOperation;
import three.constants.MultiplyOperation;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.CubeReflectionMapping;
import three.constants.PCFSoftShadowMap;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.AgXToneMapping;
import three.constants.ACESFilmicToneMapping;
import three.constants.NeutralToneMapping;
import three.constants.CineonToneMapping;
import three.constants.CustomToneMapping;
import three.constants.ReinhardToneMapping;
import three.constants.LinearToneMapping;
import three.constants.GLSL3;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.P3Primaries;
import three.constants.Rec709Primaries;
import three.shaders.ShaderChunk;
import three.webgl.WebGLShader;
import three.webgl.WebGLUniforms;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

class WebGLProgram {

	static programIdCount:Int = 0;

	static handleSource(string:String, errorLine:Int):String {
		var lines = string.split("\n");
		var lines2 = new Array<String>();

		var from = Math.max(errorLine - 6, 0);
		var to = Math.min(errorLine + 6, lines.length);

		for (var i in from...to) {
			var line = i + 1;
			lines2.push(line == errorLine ? "> " : "  " + line + ": " + lines[i]);
		}

		return lines2.join("\n");
	}

	static getEncodingComponents(colorSpace:Int):Array<String> {
		var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
		var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

		var gamutMapping:String;

		if (workingPrimaries == encodingPrimaries) {
			gamutMapping = "";
		} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
			gamutMapping = "LinearDisplayP3ToLinearSRGB";
		} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
			gamutMapping = "LinearSRGBToLinearDisplayP3";
		}

		switch (colorSpace) {
			case LinearSRGBColorSpace:
			case LinearDisplayP3ColorSpace:
				return [gamutMapping, "LinearTransferOETF"];
			case SRGBColorSpace:
			case DisplayP3ColorSpace:
				return [gamutMapping, "sRGBTransferOETF"];
			default:
				Sys.println("THREE.WebGLProgram: Unsupported color space:", colorSpace);
				return [gamutMapping, "LinearTransferOETF"];
		}
	}

	static getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
		var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		var errors = gl.getShaderInfoLog(shader).trim();

		if (status && errors == "") return "";

		var errorMatches = errors.match(/ERROR: 0:(\d+)/);
		if (errorMatches != null) {
			// --enable-privileged-webgl-extension
			// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

			var errorLine = Std.parseInt(errorMatches[1]);
			return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
		} else {
			return errors;
		}
	}

	static getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
		var components = getEncodingComponents(colorSpace);
		return "vec4 " + functionName + "( vec4 value ) { return " + components[0] + "( " + components[1] + "( value ) ); }";
	}

	static getToneMappingFunction(functionName:String, toneMapping:Int):String {
		var toneMappingName:String;

		switch (toneMapping) {
			case LinearToneMapping:
				toneMappingName = "Linear";
				break;
			case ReinhardToneMapping:
				toneMappingName = "Reinhard";
				break;
			case CineonToneMapping:
				toneMappingName = "OptimizedCineon";
				break;
			case ACESFilmicToneMapping:
				toneMappingName = "ACESFilmic";
				break;
			case AgXToneMapping:
				toneMappingName = "AgX";
				break;
			case NeutralToneMapping:
				toneMappingName = "Neutral";
				break;
			case CustomToneMapping:
				toneMappingName = "Custom";
				break;
			default:
				Sys.println("THREE.WebGLProgram: Unsupported toneMapping:", toneMapping);
				toneMappingName = "Linear";
		}

		return "vec3 " + functionName + "( vec3 color ) { return " + toneMappingName + "ToneMapping( color ); }";
	}

	static generateVertexExtensions(parameters:Dynamic):String {
		var chunks = new Array<String>();

		chunks.push(parameters.extensionClipCullDistance ? "#extension GL_ANGLE_clip_cull_distance : require" : "");
		chunks.push(parameters.extensionMultiDraw ? "#extension GL_ANGLE_multi_draw : require" : "");

		return chunks.filter(filterEmptyLine).join("\n");
	}

	static generateDefines(defines:Dynamic):String {
		var chunks = new Array<String>();

		for (var name in defines) {
			var value = defines[name];

			if (value == false) continue;

			chunks.push("#define " + name + " " + value);
		}

		return chunks.join("\n");
	}

	static fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):Dynamic {
		var attributes = new Dynamic();

		var n = gl.getProgramParameter(program.program, gl.ACTIVE_ATTRIBUTES);

		for (var i in 0...n) {
			var info = gl.getActiveAttrib(program.program, i);
			var name = info.name;

			var locationSize = 1;
			if (info.type == gl.FLOAT_MAT2) locationSize = 2;
			if (info.type == gl.FLOAT_MAT3) locationSize = 3;
			if (info.type == gl.FLOAT_MAT4) locationSize = 4;

			// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

			attributes[name] = {
				type: info.type,
				location: gl.getAttribLocation(program.program, name),
				locationSize: locationSize
			};
		}

		return attributes;
	}

	static filterEmptyLine(string:String):Bool {
		return string != "";
	}

	static replaceLightNums(string:String, parameters:Dynamic):String {
		var numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		return string
			.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights.toString())
			.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights.toString())
			.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps.toString())
			.replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords.toString())
			.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights.toString())
			.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights.toString())
			.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights.toString())
			.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows.toString())
			.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows.toString());
	}

	static replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
		return string
			.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes.toString())
			.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection).toString());
	}

	// Resolve Includes

	static includePattern = ~r"^[ \t]*#include +<([\w\d./]+)>";

	static resolveIncludes(string:String):String {
		return string.replace(includePattern, includeReplacer);
	}

	static shaderChunkMap = new Map<String, String>();

	static includeReplacer(match:String, include:String):String {
		var string = ShaderChunk[include];

		if (string == null) {
			var newInclude = shaderChunkMap.get(include);

			if (newInclude != null) {
				string = ShaderChunk[newInclude];
				Sys.println("THREE.WebGLRenderer: Shader chunk \"" + include + "\" has been deprecated. Use \"" + newInclude + "\" instead.");
			} else {
				throw new Error("Can not resolve #include <" + include + ">");
			}
		}

		return resolveIncludes(string);
	}

	// Unroll Loops

	static unrollLoopPattern = ~r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end";

	static unrollLoops(string:String):String {
		return string.replace(unrollLoopPattern, loopReplacer);
	}

	static loopReplacer(match:String, start:String, end:String, snippet:String):String {
		var string = "";

		for (var i in Std.parseInt(start)...Std.parseInt(end)) {
			string += snippet
				.replace(/\[\s*i\s*\]/g, "[ " + i + " ]")
				.replace(/UNROLLED_LOOP_INDEX/g, i.toString());
		}

		return string;
	}

	//

	static generatePrecision(parameters:Dynamic):String {
		var precisionstring = "precision " + parameters.precision + " float;\n" +
			"precision " + parameters.precision + " int;\n" +
			"precision " + parameters.precision + " sampler2D;\n" +
			"precision " + parameters.precision + " samplerCube;\n" +
			"precision " + parameters.precision + " sampler3D;\n" +
			"precision " + parameters.precision + " sampler2DArray;\n" +
			"precision " + parameters.precision + " sampler2DShadow;\n" +
			"precision " + parameters.precision + " samplerCubeShadow;\n" +
			"precision " + parameters.precision + " sampler2DArrayShadow;\n" +
			"precision " + parameters.precision + " isampler2D;\n" +
			"precision " + parameters.precision + " isampler3D;\n" +
			"precision " + parameters.precision + " isamplerCube;\n" +
			"precision " + parameters.precision + " isampler2DArray;\n" +
			"precision " + parameters.precision + " usampler2D;\n" +
			"precision " + parameters.precision + " usampler3D;\n" +
			"precision " + parameters.precision + " usamplerCube;\n" +
			"precision " + parameters.precision + " usampler2DArray;\n";

		if (parameters.precision == "highp") {
			precisionstring += "\n#define HIGH_PRECISION";
		} else if (parameters.precision == "mediump") {
			precisionstring += "\n#define MEDIUM_PRECISION";
		} else if (parameters.precision == "lowp") {
			precisionstring += "\n#define LOW_PRECISION";
		}

		return precisionstring;
	}

	static generateShadowMapTypeDefine(parameters:Dynamic):String {
		var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

		if (parameters.shadowMapType == PCFShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
		} else if (parameters.shadowMapType == PCFSoftShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
		} else if (parameters.shadowMapType == VSMShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_VSM";
		}

		return shadowMapTypeDefine;
	}

	static generateEnvMapTypeDefine(parameters:Dynamic):String {
		var envMapTypeDefine = "ENVMAP_TYPE_CUBE";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeReflectionMapping:
				case CubeRefractionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE";
					break;
				case CubeUVReflectionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE_UV";
					break;
			}
		}

		return envMapTypeDefine;
	}

	static generateEnvMapModeDefine(parameters:Dynamic):String {
		var envMapModeDefine = "ENVMAP_MODE_REFLECTION";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeRefractionMapping:
					envMapModeDefine = "ENVMAP_MODE_REFRACTION";
					break;
			}
		}

		return envMapModeDefine;
	}

	static generateEnvMapBlendingDefine(parameters:Dynamic):String {
		var envMapBlendingDefine = "ENVMAP_BLENDING_NONE";

		if (parameters.envMap != null) {
			switch (parameters.combine) {
				case MultiplyOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MULTIPLY";
					break;
				case MixOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MIX";
					break;
				case AddOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_ADD";
					break;
			}
		}

		return envMapBlendingDefine;
	}

	static generateCubeUVSize(parameters:Dynamic):Dynamic {
		var imageHeight = parameters.envMapCubeUVHeight;

		if (imageHeight == null) return null;

		var maxMip = Math.log2(imageHeight) - 2;

		var texelHeight = 1.0 / imageHeight;

		var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

		return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
	}

	program:WebGLProgram;
	vertexShader:WebGLShader;
	fragmentShader:WebGLShader;
	type:String;
	name:String;
	id:Int;
	cacheKey:String;
	usedTimes:Int;
	cachedUniforms:WebGLUniforms;
	cachedAttributes:Dynamic;
	diagnostics:Dynamic;
	isReady:Bool;

	function new(renderer:Dynamic, cacheKey:String, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

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

		this.program = gl.createProgram();

		var prefixVertex:String;
		var prefixFragment:String;
		var versionString:String = parameters.glslVersion != null ? "#version " + parameters.glslVersion + "\n" : "";

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixVertex.length > 0) {
				prefixVertex += "\n";
			}

			prefixFragment = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixFragment.length > 0) {
				prefixFragment += "\n";
			}
		} else {
			prefixVertex = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.extensionClipCullDistance ? "#define USE_CLIP_DISTANCE" : "",
				parameters.batching ? "#define USE_BATCHING" : "",
				parameters.batchingColor ? "#define USE_BATCHING_COLOR" : "",
				parameters.instancing ? "#define USE_INSTANCING" : "",
				parameters.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
				parameters.instancingMorph ? "#define USE_INSTANCING_MORPH" : "",

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.map ? "#define USE_MAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",
				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				//

				parameters.mapUv ? "#define MAP_UV " + parameters.mapUv : "",
				parameters.alphaMapUv ? "#define ALPHAMAP_UV " + parameters.alphaMapUv : "",
				parameters.lightMapUv ? "#define LIGHTMAP_UV " + parameters.lightMapUv : "",
				parameters.aoMapUv ? "#define AOMAP_UV " + parameters.aoMapUv : "",
				parameters.emissiveMapUv ? "#define EMISSIVEMAP_UV " + parameters.emissiveMapUv : "",
				parameters.bumpMapUv ? "#define BUMPMAP_UV " + parameters.bumpMapUv : "",
				parameters.normalMapUv ? "#define NORMALMAP_UV " + parameters.normalMapUv : "",
				parameters.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + parameters.displacementMapUv : "",

				parameters.metalnessMapUv ? "#define METALNESSMAP_UV " + parameters.metalnessMapUv : "",
				parameters.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + parameters.roughnessMapUv : "",

				parameters.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + parameters.anisotropyMapUv : "",

				parameters.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + parameters.clearcoatMapUv : "",
				parameters.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + parameters.clearcoatNormalMapUv : "",
				parameters.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + parameters.clearcoatRoughnessMapUv : "",

				parameters.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + parameters.iridescenceMapUv : "",
				parameters.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + parameters.iridescenceThicknessMapUv : "",

				parameters.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + parameters.sheenColorMapUv : "",
				parameters.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + parameters.sheenRoughnessMapUv : "",

				parameters.specularMapUv ? "#define SPECULARMAP_UV " + parameters.specularMapUv : "",
				parameters.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + parameters.specularColorMapUv : "",
				parameters.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + parameters.specularIntensityMapUv : "",

				parameters.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + parameters.transmissionMapUv : "",
				parameters.thicknessMapUv ? "#define THICKNESSMAP_UV " + parameters.thicknessMapUv : "",

				//

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.skinning ? "#define USE_SKINNING" : "",

				parameters.morphTargets ? "#define USE_MORPHTARGETS" : "",
				parameters.morphNormals && parameters.flatShading == false ? "#define USE_MORPHNORMALS" : "",
				(parameters.morphColors) ? "#define USE_MORPHCOLORS" : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_TEXTURE_STRIDE " + parameters.morphTextureStride : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_COUNT " + parameters.morphTargetsCount : "",
				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 modelMatrix;",
				"uniform mat4 modelViewMatrix;",
				"uniform mat4 projectionMatrix;",
				"uniform mat4 viewMatrix;",
				"uniform mat3 normalMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				"#ifdef USE_INSTANCING",

				"	attribute mat4 instanceMatrix;",

				"#endif",

				"#ifdef USE_INSTANCING_COLOR",

				"	attribute vec3 instanceColor;",

				"#endif",

				"#ifdef USE_INSTANCING_MORPH",

				"	uniform sampler2D morphTexture;",

				"#endif",

				"attribute vec3 position;",
				"attribute vec3 normal;",
				"attribute vec2 uv;",

				"#ifdef USE_UV1",

				"	attribute vec2 uv1;",

				"#endif",

				"#ifdef USE_UV2",

				"	attribute vec2 uv2;",

				"#endif",

				"#ifdef USE_UV3",

				"	attribute vec2 uv3;",

				"#endif",

				"#ifdef USE_TANGENT",

				"	attribute vec4 tangent;",

				"#endif",

				"#if defined( USE_COLOR_ALPHA )",

				"	attribute vec4 color;",

				"#elif defined( USE_COLOR )",

				"	attribute vec3 color;",

				"#endif",

				"#ifdef USE_SKINNING",

				"	attribute vec4 skinIndex;",
				"	attribute vec4 skinWeight;",

				"#endif",

				"\n"

			].filter(filterEmptyLine).join("\n");

			prefixFragment = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.alphaToCoverage ? "#define ALPHA_TO_COVERAGE" : "",
				parameters.map ? "#define USE_MAP" : "",
				parameters.matcap ? "#define USE_MATCAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapTypeDefine : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.envMap ? "#define " + envMapBlendingDefine : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_WIDTH " + envMapCubeUVSize.texelWidth : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_HEIGHT " + envMapCubeUVSize.texelHeight : "",
				envMapCubeUVSize != null ? "#define CUBEUV_MAX_MIP " + envMapCubeUVSize.maxMip + ".0" : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoat ? "#define USE_CLEARCOAT" : "",
				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.dispersion ? "#define USE_DISPERSION" : "",

				parameters.iridescence ? "#define USE_IRIDESCENCE" : "",
				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",

				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaTest ? "#define USE_ALPHATEST" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.sheen ? "#define USE_SHEEN" : "",
				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.gradientMap ? "#define USE_GRADIENTMAP" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 viewMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				(parameters.toneMapping != NoToneMapping) ? "#define TONE_MAPPING" : "",
				(parameters.toneMapping != NoToneMapping) ? ShaderChunk["tonemapping_pars_fragment"] : "", // this code is required here because it is used by the toneMapping() function defined below
				(parameters.toneMapping != NoToneMapping) ? getToneMappingFunction("toneMapping", parameters.toneMapping) : "",

				parameters.dithering ? "#define DITHERING" : "",
				parameters.opaque ? "#define OPAQUE" : "",

				ShaderChunk["colorspace_pars_fragment"], // this code is required here because it is used by the various encoding/decoding function defined below
				getTexelEncodingFunction("linearToOutputTexel", parameters.outputColorSpace),

				parameters.useDepthPacking ? "#define DEPTH_PACKING " + parameters.depthPacking : "",

				"\n"

			].filter(filterEmptyLine).join("\n");
		}

		vertexShader = resolveIncludes(vertexShader);
		vertexShader = replaceLightNums(vertexShader, parameters);
		vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

		fragmentShader = resolveIncludes(fragmentShader);
		fragmentShader = replaceLightNums(fragmentShader, parameters);
		fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

		vertexShader = unrollLoops(vertexShader);
		fragmentShader = unrollLoops(fragmentShader);

		if (parameters.isRawShaderMaterial != true) {
			// GLSL 3.0 conversion for built-in materials and ShaderMaterial

			versionString = "#version 300 es\n";

			prefixVertex = [
				customVertexExtensions,
				"#define attribute in",
				"#define varying out",
				"#define texture2D texture"
			].join("\n") + "\n" + prefixVertex;

			prefixFragment = [
				"#define varying in",
				(parameters.glslVersion == GLSL3) ? "" : "layout(location = 0) out high
import three.constants.ColorManagement;
import three.constants.NoToneMapping;
import three.constants.AddOperation;
import three.constants.MixOperation;
import three.constants.MultiplyOperation;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.CubeReflectionMapping;
import three.constants.PCFSoftShadowMap;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.AgXToneMapping;
import three.constants.ACESFilmicToneMapping;
import three.constants.NeutralToneMapping;
import three.constants.CineonToneMapping;
import three.constants.CustomToneMapping;
import three.constants.ReinhardToneMapping;
import three.constants.LinearToneMapping;
import three.constants.GLSL3;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.P3Primaries;
import three.constants.Rec709Primaries;
import three.shaders.ShaderChunk;
import three.webgl.WebGLShader;
import three.webgl.WebGLUniforms;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

class WebGLProgram {

	static programIdCount:Int = 0;

	static handleSource(string:String, errorLine:Int):String {
		var lines = string.split("\n");
		var lines2 = new Array<String>();

		var from = Math.max(errorLine - 6, 0);
		var to = Math.min(errorLine + 6, lines.length);

		for (var i in from...to) {
			var line = i + 1;
			lines2.push(line == errorLine ? "> " : "  " + line + ": " + lines[i]);
		}

		return lines2.join("\n");
	}

	static getEncodingComponents(colorSpace:Int):Array<String> {
		var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
		var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

		var gamutMapping:String;

		if (workingPrimaries == encodingPrimaries) {
			gamutMapping = "";
		} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
			gamutMapping = "LinearDisplayP3ToLinearSRGB";
		} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
			gamutMapping = "LinearSRGBToLinearDisplayP3";
		}

		switch (colorSpace) {
			case LinearSRGBColorSpace:
			case LinearDisplayP3ColorSpace:
				return [gamutMapping, "LinearTransferOETF"];
			case SRGBColorSpace:
			case DisplayP3ColorSpace:
				return [gamutMapping, "sRGBTransferOETF"];
			default:
				Sys.println("THREE.WebGLProgram: Unsupported color space:", colorSpace);
				return [gamutMapping, "LinearTransferOETF"];
		}
	}

	static getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
		var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		var errors = gl.getShaderInfoLog(shader).trim();

		if (status && errors == "") return "";

		var errorMatches = errors.match(/ERROR: 0:(\d+)/);
		if (errorMatches != null) {
			// --enable-privileged-webgl-extension
			// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

			var errorLine = Std.parseInt(errorMatches[1]);
			return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
		} else {
			return errors;
		}
	}

	static getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
		var components = getEncodingComponents(colorSpace);
		return "vec4 " + functionName + "( vec4 value ) { return " + components[0] + "( " + components[1] + "( value ) ); }";
	}

	static getToneMappingFunction(functionName:String, toneMapping:Int):String {
		var toneMappingName:String;

		switch (toneMapping) {
			case LinearToneMapping:
				toneMappingName = "Linear";
				break;
			case ReinhardToneMapping:
				toneMappingName = "Reinhard";
				break;
			case CineonToneMapping:
				toneMappingName = "OptimizedCineon";
				break;
			case ACESFilmicToneMapping:
				toneMappingName = "ACESFilmic";
				break;
			case AgXToneMapping:
				toneMappingName = "AgX";
				break;
			case NeutralToneMapping:
				toneMappingName = "Neutral";
				break;
			case CustomToneMapping:
				toneMappingName = "Custom";
				break;
			default:
				Sys.println("THREE.WebGLProgram: Unsupported toneMapping:", toneMapping);
				toneMappingName = "Linear";
		}

		return "vec3 " + functionName + "( vec3 color ) { return " + toneMappingName + "ToneMapping( color ); }";
	}

	static generateVertexExtensions(parameters:Dynamic):String {
		var chunks = new Array<String>();

		chunks.push(parameters.extensionClipCullDistance ? "#extension GL_ANGLE_clip_cull_distance : require" : "");
		chunks.push(parameters.extensionMultiDraw ? "#extension GL_ANGLE_multi_draw : require" : "");

		return chunks.filter(filterEmptyLine).join("\n");
	}

	static generateDefines(defines:Dynamic):String {
		var chunks = new Array<String>();

		for (var name in defines) {
			var value = defines[name];

			if (value == false) continue;

			chunks.push("#define " + name + " " + value);
		}

		return chunks.join("\n");
	}

	static fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):Dynamic {
		var attributes = new Dynamic();

		var n = gl.getProgramParameter(program.program, gl.ACTIVE_ATTRIBUTES);

		for (var i in 0...n) {
			var info = gl.getActiveAttrib(program.program, i);
			var name = info.name;

			var locationSize = 1;
			if (info.type == gl.FLOAT_MAT2) locationSize = 2;
			if (info.type == gl.FLOAT_MAT3) locationSize = 3;
			if (info.type == gl.FLOAT_MAT4) locationSize = 4;

			// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

			attributes[name] = {
				type: info.type,
				location: gl.getAttribLocation(program.program, name),
				locationSize: locationSize
			};
		}

		return attributes;
	}

	static filterEmptyLine(string:String):Bool {
		return string != "";
	}

	static replaceLightNums(string:String, parameters:Dynamic):String {
		var numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		return string
			.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights.toString())
			.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights.toString())
			.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps.toString())
			.replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords.toString())
			.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights.toString())
			.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights.toString())
			.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights.toString())
			.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows.toString())
			.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows.toString());
	}

	static replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
		return string
			.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes.toString())
			.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection).toString());
	}

	// Resolve Includes

	static includePattern = ~r"^[ \t]*#include +<([\w\d./]+)>";

	static resolveIncludes(string:String):String {
		return string.replace(includePattern, includeReplacer);
	}

	static shaderChunkMap = new Map<String, String>();

	static includeReplacer(match:String, include:String):String {
		var string = ShaderChunk[include];

		if (string == null) {
			var newInclude = shaderChunkMap.get(include);

			if (newInclude != null) {
				string = ShaderChunk[newInclude];
				Sys.println("THREE.WebGLRenderer: Shader chunk \"" + include + "\" has been deprecated. Use \"" + newInclude + "\" instead.");
			} else {
				throw new Error("Can not resolve #include <" + include + ">");
			}
		}

		return resolveIncludes(string);
	}

	// Unroll Loops

	static unrollLoopPattern = ~r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end";

	static unrollLoops(string:String):String {
		return string.replace(unrollLoopPattern, loopReplacer);
	}

	static loopReplacer(match:String, start:String, end:String, snippet:String):String {
		var string = "";

		for (var i in Std.parseInt(start)...Std.parseInt(end)) {
			string += snippet
				.replace(/\[\s*i\s*\]/g, "[ " + i + " ]")
				.replace(/UNROLLED_LOOP_INDEX/g, i.toString());
		}

		return string;
	}

	//

	static generatePrecision(parameters:Dynamic):String {
		var precisionstring = "precision " + parameters.precision + " float;\n" +
			"precision " + parameters.precision + " int;\n" +
			"precision " + parameters.precision + " sampler2D;\n" +
			"precision " + parameters.precision + " samplerCube;\n" +
			"precision " + parameters.precision + " sampler3D;\n" +
			"precision " + parameters.precision + " sampler2DArray;\n" +
			"precision " + parameters.precision + " sampler2DShadow;\n" +
			"precision " + parameters.precision + " samplerCubeShadow;\n" +
			"precision " + parameters.precision + " sampler2DArrayShadow;\n" +
			"precision " + parameters.precision + " isampler2D;\n" +
			"precision " + parameters.precision + " isampler3D;\n" +
			"precision " + parameters.precision + " isamplerCube;\n" +
			"precision " + parameters.precision + " isampler2DArray;\n" +
			"precision " + parameters.precision + " usampler2D;\n" +
			"precision " + parameters.precision + " usampler3D;\n" +
			"precision " + parameters.precision + " usamplerCube;\n" +
			"precision " + parameters.precision + " usampler2DArray;\n";

		if (parameters.precision == "highp") {
			precisionstring += "\n#define HIGH_PRECISION";
		} else if (parameters.precision == "mediump") {
			precisionstring += "\n#define MEDIUM_PRECISION";
		} else if (parameters.precision == "lowp") {
			precisionstring += "\n#define LOW_PRECISION";
		}

		return precisionstring;
	}

	static generateShadowMapTypeDefine(parameters:Dynamic):String {
		var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

		if (parameters.shadowMapType == PCFShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
		} else if (parameters.shadowMapType == PCFSoftShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
		} else if (parameters.shadowMapType == VSMShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_VSM";
		}

		return shadowMapTypeDefine;
	}

	static generateEnvMapTypeDefine(parameters:Dynamic):String {
		var envMapTypeDefine = "ENVMAP_TYPE_CUBE";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeReflectionMapping:
				case CubeRefractionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE";
					break;
				case CubeUVReflectionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE_UV";
					break;
			}
		}

		return envMapTypeDefine;
	}

	static generateEnvMapModeDefine(parameters:Dynamic):String {
		var envMapModeDefine = "ENVMAP_MODE_REFLECTION";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeRefractionMapping:
					envMapModeDefine = "ENVMAP_MODE_REFRACTION";
					break;
			}
		}

		return envMapModeDefine;
	}

	static generateEnvMapBlendingDefine(parameters:Dynamic):String {
		var envMapBlendingDefine = "ENVMAP_BLENDING_NONE";

		if (parameters.envMap != null) {
			switch (parameters.combine) {
				case MultiplyOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MULTIPLY";
					break;
				case MixOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MIX";
					break;
				case AddOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_ADD";
					break;
			}
		}

		return envMapBlendingDefine;
	}

	static generateCubeUVSize(parameters:Dynamic):Dynamic {
		var imageHeight = parameters.envMapCubeUVHeight;

		if (imageHeight == null) return null;

		var maxMip = Math.log2(imageHeight) - 2;

		var texelHeight = 1.0 / imageHeight;

		var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

		return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
	}

	program:WebGLProgram;
	vertexShader:WebGLShader;
	fragmentShader:WebGLShader;
	type:String;
	name:String;
	id:Int;
	cacheKey:String;
	usedTimes:Int;
	cachedUniforms:WebGLUniforms;
	cachedAttributes:Dynamic;
	diagnostics:Dynamic;
	isReady:Bool;

	function new(renderer:Dynamic, cacheKey:String, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

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

		this.program = gl.createProgram();

		var prefixVertex:String;
		var prefixFragment:String;
		var versionString:String = parameters.glslVersion != null ? "#version " + parameters.glslVersion + "\n" : "";

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixVertex.length > 0) {
				prefixVertex += "\n";
			}

			prefixFragment = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixFragment.length > 0) {
				prefixFragment += "\n";
			}
		} else {
			prefixVertex = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.extensionClipCullDistance ? "#define USE_CLIP_DISTANCE" : "",
				parameters.batching ? "#define USE_BATCHING" : "",
				parameters.batchingColor ? "#define USE_BATCHING_COLOR" : "",
				parameters.instancing ? "#define USE_INSTANCING" : "",
				parameters.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
				parameters.instancingMorph ? "#define USE_INSTANCING_MORPH" : "",

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.map ? "#define USE_MAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",
				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				//

				parameters.mapUv ? "#define MAP_UV " + parameters.mapUv : "",
				parameters.alphaMapUv ? "#define ALPHAMAP_UV " + parameters.alphaMapUv : "",
				parameters.lightMapUv ? "#define LIGHTMAP_UV " + parameters.lightMapUv : "",
				parameters.aoMapUv ? "#define AOMAP_UV " + parameters.aoMapUv : "",
				parameters.emissiveMapUv ? "#define EMISSIVEMAP_UV " + parameters.emissiveMapUv : "",
				parameters.bumpMapUv ? "#define BUMPMAP_UV " + parameters.bumpMapUv : "",
				parameters.normalMapUv ? "#define NORMALMAP_UV " + parameters.normalMapUv : "",
				parameters.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + parameters.displacementMapUv : "",

				parameters.metalnessMapUv ? "#define METALNESSMAP_UV " + parameters.metalnessMapUv : "",
				parameters.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + parameters.roughnessMapUv : "",

				parameters.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + parameters.anisotropyMapUv : "",

				parameters.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + parameters.clearcoatMapUv : "",
				parameters.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + parameters.clearcoatNormalMapUv : "",
				parameters.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + parameters.clearcoatRoughnessMapUv : "",

				parameters.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + parameters.iridescenceMapUv : "",
				parameters.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + parameters.iridescenceThicknessMapUv : "",

				parameters.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + parameters.sheenColorMapUv : "",
				parameters.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + parameters.sheenRoughnessMapUv : "",

				parameters.specularMapUv ? "#define SPECULARMAP_UV " + parameters.specularMapUv : "",
				parameters.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + parameters.specularColorMapUv : "",
				parameters.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + parameters.specularIntensityMapUv : "",

				parameters.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + parameters.transmissionMapUv : "",
				parameters.thicknessMapUv ? "#define THICKNESSMAP_UV " + parameters.thicknessMapUv : "",

				//

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.skinning ? "#define USE_SKINNING" : "",

				parameters.morphTargets ? "#define USE_MORPHTARGETS" : "",
				parameters.morphNormals && parameters.flatShading == false ? "#define USE_MORPHNORMALS" : "",
				(parameters.morphColors) ? "#define USE_MORPHCOLORS" : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_TEXTURE_STRIDE " + parameters.morphTextureStride : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_COUNT " + parameters.morphTargetsCount : "",
				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 modelMatrix;",
				"uniform mat4 modelViewMatrix;",
				"uniform mat4 projectionMatrix;",
				"uniform mat4 viewMatrix;",
				"uniform mat3 normalMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				"#ifdef USE_INSTANCING",

				"	attribute mat4 instanceMatrix;",

				"#endif",

				"#ifdef USE_INSTANCING_COLOR",

				"	attribute vec3 instanceColor;",

				"#endif",

				"#ifdef USE_INSTANCING_MORPH",

				"	uniform sampler2D morphTexture;",

				"#endif",

				"attribute vec3 position;",
				"attribute vec3 normal;",
				"attribute vec2 uv;",

				"#ifdef USE_UV1",

				"	attribute vec2 uv1;",

				"#endif",

				"#ifdef USE_UV2",

				"	attribute vec2 uv2;",

				"#endif",

				"#ifdef USE_UV3",

				"	attribute vec2 uv3;",

				"#endif",

				"#ifdef USE_TANGENT",

				"	attribute vec4 tangent;",

				"#endif",

				"#if defined( USE_COLOR_ALPHA )",

				"	attribute vec4 color;",

				"#elif defined( USE_COLOR )",

				"	attribute vec3 color;",

				"#endif",

				"#ifdef USE_SKINNING",

				"	attribute vec4 skinIndex;",
				"	attribute vec4 skinWeight;",

				"#endif",

				"\n"

			].filter(filterEmptyLine).join("\n");

			prefixFragment = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.alphaToCoverage ? "#define ALPHA_TO_COVERAGE" : "",
				parameters.map ? "#define USE_MAP" : "",
				parameters.matcap ? "#define USE_MATCAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapTypeDefine : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.envMap ? "#define " + envMapBlendingDefine : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_WIDTH " + envMapCubeUVSize.texelWidth : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_HEIGHT " + envMapCubeUVSize.texelHeight : "",
				envMapCubeUVSize != null ? "#define CUBEUV_MAX_MIP " + envMapCubeUVSize.maxMip + ".0" : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoat ? "#define USE_CLEARCOAT" : "",
				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.dispersion ? "#define USE_DISPERSION" : "",

				parameters.iridescence ? "#define USE_IRIDESCENCE" : "",
				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",

				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaTest ? "#define USE_ALPHATEST" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.sheen ? "#define USE_SHEEN" : "",
				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.gradientMap ? "#define USE_GRADIENTMAP" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 viewMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				(parameters.toneMapping != NoToneMapping) ? "#define TONE_MAPPING" : "",
				(parameters.toneMapping != NoToneMapping) ? ShaderChunk["tonemapping_pars_fragment"] : "", // this code is required here because it is used by the toneMapping() function defined below
				(parameters.toneMapping != NoToneMapping) ? getToneMappingFunction("toneMapping", parameters.toneMapping) : "",

				parameters.dithering ? "#define DITHERING" : "",
				parameters.opaque ? "#define OPAQUE" : "",

				ShaderChunk["colorspace_pars_fragment"], // this code is required here because it is used by the various encoding/decoding function defined below
				getTexelEncodingFunction("linearToOutputTexel", parameters.outputColorSpace),

				parameters.useDepthPacking ? "#define DEPTH_PACKING " + parameters.depthPacking : "",

				"\n"

			].filter(filterEmptyLine).join("\n");
		}

		vertexShader = resolveIncludes(vertexShader);
		vertexShader = replaceLightNums(vertexShader, parameters);
		vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

		fragmentShader = resolveIncludes(fragmentShader);
		fragmentShader = replaceLightNums(fragmentShader, parameters);
		fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

		vertexShader = unrollLoops(vertexShader);
		fragmentShader = unrollLoops(fragmentShader);

		if (parameters.isRawShaderMaterial != true) {
			// GLSL 3.0 conversion for built-in materials and ShaderMaterial

			versionString = "#version 300 es\n";

			prefixVertex = [
				customVertexExtensions,
				"#define attribute in",
				"#define varying out",
				"#define texture2D texture"
			].join("\n") + "\n" + prefixVertex;

			prefixFragment = [
				"#define varying in",
				(parameters.glslVersion == GLSL3) ? "" : "layout(location = 0) out high
import three.constants.ColorManagement;
import three.constants.NoToneMapping;
import three.constants.AddOperation;
import three.constants.MixOperation;
import three.constants.MultiplyOperation;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.CubeReflectionMapping;
import three.constants.PCFSoftShadowMap;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.AgXToneMapping;
import three.constants.ACESFilmicToneMapping;
import three.constants.NeutralToneMapping;
import three.constants.CineonToneMapping;
import three.constants.CustomToneMapping;
import three.constants.ReinhardToneMapping;
import three.constants.LinearToneMapping;
import three.constants.GLSL3;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.P3Primaries;
import three.constants.Rec709Primaries;
import three.shaders.ShaderChunk;
import three.webgl.WebGLShader;
import three.webgl.WebGLUniforms;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

class WebGLProgram {

	static programIdCount:Int = 0;

	static handleSource(string:String, errorLine:Int):String {
		var lines = string.split("\n");
		var lines2 = new Array<String>();

		var from = Math.max(errorLine - 6, 0);
		var to = Math.min(errorLine + 6, lines.length);

		for (var i in from...to) {
			var line = i + 1;
			lines2.push(line == errorLine ? "> " : "  " + line + ": " + lines[i]);
		}

		return lines2.join("\n");
	}

	static getEncodingComponents(colorSpace:Int):Array<String> {
		var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
		var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

		var gamutMapping:String;

		if (workingPrimaries == encodingPrimaries) {
			gamutMapping = "";
		} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
			gamutMapping = "LinearDisplayP3ToLinearSRGB";
		} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
			gamutMapping = "LinearSRGBToLinearDisplayP3";
		}

		switch (colorSpace) {
			case LinearSRGBColorSpace:
			case LinearDisplayP3ColorSpace:
				return [gamutMapping, "LinearTransferOETF"];
			case SRGBColorSpace:
			case DisplayP3ColorSpace:
				return [gamutMapping, "sRGBTransferOETF"];
			default:
				Sys.println("THREE.WebGLProgram: Unsupported color space:", colorSpace);
				return [gamutMapping, "LinearTransferOETF"];
		}
	}

	static getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
		var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		var errors = gl.getShaderInfoLog(shader).trim();

		if (status && errors == "") return "";

		var errorMatches = errors.match(/ERROR: 0:(\d+)/);
		if (errorMatches != null) {
			// --enable-privileged-webgl-extension
			// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

			var errorLine = Std.parseInt(errorMatches[1]);
			return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
		} else {
			return errors;
		}
	}

	static getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
		var components = getEncodingComponents(colorSpace);
		return "vec4 " + functionName + "( vec4 value ) { return " + components[0] + "( " + components[1] + "( value ) ); }";
	}

	static getToneMappingFunction(functionName:String, toneMapping:Int):String {
		var toneMappingName:String;

		switch (toneMapping) {
			case LinearToneMapping:
				toneMappingName = "Linear";
				break;
			case ReinhardToneMapping:
				toneMappingName = "Reinhard";
				break;
			case CineonToneMapping:
				toneMappingName = "OptimizedCineon";
				break;
			case ACESFilmicToneMapping:
				toneMappingName = "ACESFilmic";
				break;
			case AgXToneMapping:
				toneMappingName = "AgX";
				break;
			case NeutralToneMapping:
				toneMappingName = "Neutral";
				break;
			case CustomToneMapping:
				toneMappingName = "Custom";
				break;
			default:
				Sys.println("THREE.WebGLProgram: Unsupported toneMapping:", toneMapping);
				toneMappingName = "Linear";
		}

		return "vec3 " + functionName + "( vec3 color ) { return " + toneMappingName + "ToneMapping( color ); }";
	}

	static generateVertexExtensions(parameters:Dynamic):String {
		var chunks = new Array<String>();

		chunks.push(parameters.extensionClipCullDistance ? "#extension GL_ANGLE_clip_cull_distance : require" : "");
		chunks.push(parameters.extensionMultiDraw ? "#extension GL_ANGLE_multi_draw : require" : "");

		return chunks.filter(filterEmptyLine).join("\n");
	}

	static generateDefines(defines:Dynamic):String {
		var chunks = new Array<String>();

		for (var name in defines) {
			var value = defines[name];

			if (value == false) continue;

			chunks.push("#define " + name + " " + value);
		}

		return chunks.join("\n");
	}

	static fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):Dynamic {
		var attributes = new Dynamic();

		var n = gl.getProgramParameter(program.program, gl.ACTIVE_ATTRIBUTES);

		for (var i in 0...n) {
			var info = gl.getActiveAttrib(program.program, i);
			var name = info.name;

			var locationSize = 1;
			if (info.type == gl.FLOAT_MAT2) locationSize = 2;
			if (info.type == gl.FLOAT_MAT3) locationSize = 3;
			if (info.type == gl.FLOAT_MAT4) locationSize = 4;

			// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

			attributes[name] = {
				type: info.type,
				location: gl.getAttribLocation(program.program, name),
				locationSize: locationSize
			};
		}

		return attributes;
	}

	static filterEmptyLine(string:String):Bool {
		return string != "";
	}

	static replaceLightNums(string:String, parameters:Dynamic):String {
		var numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		return string
			.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights.toString())
			.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights.toString())
			.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps.toString())
			.replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords.toString())
			.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights.toString())
			.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights.toString())
			.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights.toString())
			.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows.toString())
			.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows.toString());
	}

	static replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
		return string
			.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes.toString())
			.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection).toString());
	}

	// Resolve Includes

	static includePattern = ~r"^[ \t]*#include +<([\w\d./]+)>";

	static resolveIncludes(string:String):String {
		return string.replace(includePattern, includeReplacer);
	}

	static shaderChunkMap = new Map<String, String>();

	static includeReplacer(match:String, include:String):String {
		var string = ShaderChunk[include];

		if (string == null) {
			var newInclude = shaderChunkMap.get(include);

			if (newInclude != null) {
				string = ShaderChunk[newInclude];
				Sys.println("THREE.WebGLRenderer: Shader chunk \"" + include + "\" has been deprecated. Use \"" + newInclude + "\" instead.");
			} else {
				throw new Error("Can not resolve #include <" + include + ">");
			}
		}

		return resolveIncludes(string);
	}

	// Unroll Loops

	static unrollLoopPattern = ~r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end";

	static unrollLoops(string:String):String {
		return string.replace(unrollLoopPattern, loopReplacer);
	}

	static loopReplacer(match:String, start:String, end:String, snippet:String):String {
		var string = "";

		for (var i in Std.parseInt(start)...Std.parseInt(end)) {
			string += snippet
				.replace(/\[\s*i\s*\]/g, "[ " + i + " ]")
				.replace(/UNROLLED_LOOP_INDEX/g, i.toString());
		}

		return string;
	}

	//

	static generatePrecision(parameters:Dynamic):String {
		var precisionstring = "precision " + parameters.precision + " float;\n" +
			"precision " + parameters.precision + " int;\n" +
			"precision " + parameters.precision + " sampler2D;\n" +
			"precision " + parameters.precision + " samplerCube;\n" +
			"precision " + parameters.precision + " sampler3D;\n" +
			"precision " + parameters.precision + " sampler2DArray;\n" +
			"precision " + parameters.precision + " sampler2DShadow;\n" +
			"precision " + parameters.precision + " samplerCubeShadow;\n" +
			"precision " + parameters.precision + " sampler2DArrayShadow;\n" +
			"precision " + parameters.precision + " isampler2D;\n" +
			"precision " + parameters.precision + " isampler3D;\n" +
			"precision " + parameters.precision + " isamplerCube;\n" +
			"precision " + parameters.precision + " isampler2DArray;\n" +
			"precision " + parameters.precision + " usampler2D;\n" +
			"precision " + parameters.precision + " usampler3D;\n" +
			"precision " + parameters.precision + " usamplerCube;\n" +
			"precision " + parameters.precision + " usampler2DArray;\n";

		if (parameters.precision == "highp") {
			precisionstring += "\n#define HIGH_PRECISION";
		} else if (parameters.precision == "mediump") {
			precisionstring += "\n#define MEDIUM_PRECISION";
		} else if (parameters.precision == "lowp") {
			precisionstring += "\n#define LOW_PRECISION";
		}

		return precisionstring;
	}

	static generateShadowMapTypeDefine(parameters:Dynamic):String {
		var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

		if (parameters.shadowMapType == PCFShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
		} else if (parameters.shadowMapType == PCFSoftShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
		} else if (parameters.shadowMapType == VSMShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_VSM";
		}

		return shadowMapTypeDefine;
	}

	static generateEnvMapTypeDefine(parameters:Dynamic):String {
		var envMapTypeDefine = "ENVMAP_TYPE_CUBE";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeReflectionMapping:
				case CubeRefractionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE";
					break;
				case CubeUVReflectionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE_UV";
					break;
			}
		}

		return envMapTypeDefine;
	}

	static generateEnvMapModeDefine(parameters:Dynamic):String {
		var envMapModeDefine = "ENVMAP_MODE_REFLECTION";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeRefractionMapping:
					envMapModeDefine = "ENVMAP_MODE_REFRACTION";
					break;
			}
		}

		return envMapModeDefine;
	}

	static generateEnvMapBlendingDefine(parameters:Dynamic):String {
		var envMapBlendingDefine = "ENVMAP_BLENDING_NONE";

		if (parameters.envMap != null) {
			switch (parameters.combine) {
				case MultiplyOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MULTIPLY";
					break;
				case MixOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MIX";
					break;
				case AddOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_ADD";
					break;
			}
		}

		return envMapBlendingDefine;
	}

	static generateCubeUVSize(parameters:Dynamic):Dynamic {
		var imageHeight = parameters.envMapCubeUVHeight;

		if (imageHeight == null) return null;

		var maxMip = Math.log2(imageHeight) - 2;

		var texelHeight = 1.0 / imageHeight;

		var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

		return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
	}

	program:WebGLProgram;
	vertexShader:WebGLShader;
	fragmentShader:WebGLShader;
	type:String;
	name:String;
	id:Int;
	cacheKey:String;
	usedTimes:Int;
	cachedUniforms:WebGLUniforms;
	cachedAttributes:Dynamic;
	diagnostics:Dynamic;
	isReady:Bool;

	function new(renderer:Dynamic, cacheKey:String, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

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

		this.program = gl.createProgram();

		var prefixVertex:String;
		var prefixFragment:String;
		var versionString:String = parameters.glslVersion != null ? "#version " + parameters.glslVersion + "\n" : "";

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixVertex.length > 0) {
				prefixVertex += "\n";
			}

			prefixFragment = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixFragment.length > 0) {
				prefixFragment += "\n";
			}
		} else {
			prefixVertex = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.extensionClipCullDistance ? "#define USE_CLIP_DISTANCE" : "",
				parameters.batching ? "#define USE_BATCHING" : "",
				parameters.batchingColor ? "#define USE_BATCHING_COLOR" : "",
				parameters.instancing ? "#define USE_INSTANCING" : "",
				parameters.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
				parameters.instancingMorph ? "#define USE_INSTANCING_MORPH" : "",

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.map ? "#define USE_MAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",
				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				//

				parameters.mapUv ? "#define MAP_UV " + parameters.mapUv : "",
				parameters.alphaMapUv ? "#define ALPHAMAP_UV " + parameters.alphaMapUv : "",
				parameters.lightMapUv ? "#define LIGHTMAP_UV " + parameters.lightMapUv : "",
				parameters.aoMapUv ? "#define AOMAP_UV " + parameters.aoMapUv : "",
				parameters.emissiveMapUv ? "#define EMISSIVEMAP_UV " + parameters.emissiveMapUv : "",
				parameters.bumpMapUv ? "#define BUMPMAP_UV " + parameters.bumpMapUv : "",
				parameters.normalMapUv ? "#define NORMALMAP_UV " + parameters.normalMapUv : "",
				parameters.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + parameters.displacementMapUv : "",

				parameters.metalnessMapUv ? "#define METALNESSMAP_UV " + parameters.metalnessMapUv : "",
				parameters.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + parameters.roughnessMapUv : "",

				parameters.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + parameters.anisotropyMapUv : "",

				parameters.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + parameters.clearcoatMapUv : "",
				parameters.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + parameters.clearcoatNormalMapUv : "",
				parameters.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + parameters.clearcoatRoughnessMapUv : "",

				parameters.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + parameters.iridescenceMapUv : "",
				parameters.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + parameters.iridescenceThicknessMapUv : "",

				parameters.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + parameters.sheenColorMapUv : "",
				parameters.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + parameters.sheenRoughnessMapUv : "",

				parameters.specularMapUv ? "#define SPECULARMAP_UV " + parameters.specularMapUv : "",
				parameters.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + parameters.specularColorMapUv : "",
				parameters.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + parameters.specularIntensityMapUv : "",

				parameters.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + parameters.transmissionMapUv : "",
				parameters.thicknessMapUv ? "#define THICKNESSMAP_UV " + parameters.thicknessMapUv : "",

				//

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.skinning ? "#define USE_SKINNING" : "",

				parameters.morphTargets ? "#define USE_MORPHTARGETS" : "",
				parameters.morphNormals && parameters.flatShading == false ? "#define USE_MORPHNORMALS" : "",
				(parameters.morphColors) ? "#define USE_MORPHCOLORS" : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_TEXTURE_STRIDE " + parameters.morphTextureStride : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_COUNT " + parameters.morphTargetsCount : "",
				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 modelMatrix;",
				"uniform mat4 modelViewMatrix;",
				"uniform mat4 projectionMatrix;",
				"uniform mat4 viewMatrix;",
				"uniform mat3 normalMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				"#ifdef USE_INSTANCING",

				"	attribute mat4 instanceMatrix;",

				"#endif",

				"#ifdef USE_INSTANCING_COLOR",

				"	attribute vec3 instanceColor;",

				"#endif",

				"#ifdef USE_INSTANCING_MORPH",

				"	uniform sampler2D morphTexture;",

				"#endif",

				"attribute vec3 position;",
				"attribute vec3 normal;",
				"attribute vec2 uv;",

				"#ifdef USE_UV1",

				"	attribute vec2 uv1;",

				"#endif",

				"#ifdef USE_UV2",

				"	attribute vec2 uv2;",

				"#endif",

				"#ifdef USE_UV3",

				"	attribute vec2 uv3;",

				"#endif",

				"#ifdef USE_TANGENT",

				"	attribute vec4 tangent;",

				"#endif",

				"#if defined( USE_COLOR_ALPHA )",

				"	attribute vec4 color;",

				"#elif defined( USE_COLOR )",

				"	attribute vec3 color;",

				"#endif",

				"#ifdef USE_SKINNING",

				"	attribute vec4 skinIndex;",
				"	attribute vec4 skinWeight;",

				"#endif",

				"\n"

			].filter(filterEmptyLine).join("\n");

			prefixFragment = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.alphaToCoverage ? "#define ALPHA_TO_COVERAGE" : "",
				parameters.map ? "#define USE_MAP" : "",
				parameters.matcap ? "#define USE_MATCAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapTypeDefine : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.envMap ? "#define " + envMapBlendingDefine : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_WIDTH " + envMapCubeUVSize.texelWidth : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_HEIGHT " + envMapCubeUVSize.texelHeight : "",
				envMapCubeUVSize != null ? "#define CUBEUV_MAX_MIP " + envMapCubeUVSize.maxMip + ".0" : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoat ? "#define USE_CLEARCOAT" : "",
				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.dispersion ? "#define USE_DISPERSION" : "",

				parameters.iridescence ? "#define USE_IRIDESCENCE" : "",
				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",

				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaTest ? "#define USE_ALPHATEST" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.sheen ? "#define USE_SHEEN" : "",
				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.gradientMap ? "#define USE_GRADIENTMAP" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 viewMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				(parameters.toneMapping != NoToneMapping) ? "#define TONE_MAPPING" : "",
				(parameters.toneMapping != NoToneMapping) ? ShaderChunk["tonemapping_pars_fragment"] : "", // this code is required here because it is used by the toneMapping() function defined below
				(parameters.toneMapping != NoToneMapping) ? getToneMappingFunction("toneMapping", parameters.toneMapping) : "",

				parameters.dithering ? "#define DITHERING" : "",
				parameters.opaque ? "#define OPAQUE" : "",

				ShaderChunk["colorspace_pars_fragment"], // this code is required here because it is used by the various encoding/decoding function defined below
				getTexelEncodingFunction("linearToOutputTexel", parameters.outputColorSpace),

				parameters.useDepthPacking ? "#define DEPTH_PACKING " + parameters.depthPacking : "",

				"\n"

			].filter(filterEmptyLine).join("\n");
		}

		vertexShader = resolveIncludes(vertexShader);
		vertexShader = replaceLightNums(vertexShader, parameters);
		vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

		fragmentShader = resolveIncludes(fragmentShader);
		fragmentShader = replaceLightNums(fragmentShader, parameters);
		fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

		vertexShader = unrollLoops(vertexShader);
		fragmentShader = unrollLoops(fragmentShader);

		if (parameters.isRawShaderMaterial != true) {
			// GLSL 3.0 conversion for built-in materials and ShaderMaterial

			versionString = "#version 300 es\n";

			prefixVertex = [
				customVertexExtensions,
				"#define attribute in",
				"#define varying out",
				"#define texture2D texture"
			].join("\n") + "\n" + prefixVertex;

			prefixFragment = [
				"#define varying in",
				(parameters.glslVersion == GLSL3) ? "" : "layout(location = 0) out high
import three.constants.ColorManagement;
import three.constants.NoToneMapping;
import three.constants.AddOperation;
import three.constants.MixOperation;
import three.constants.MultiplyOperation;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.CubeReflectionMapping;
import three.constants.PCFSoftShadowMap;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.AgXToneMapping;
import three.constants.ACESFilmicToneMapping;
import three.constants.NeutralToneMapping;
import three.constants.CineonToneMapping;
import three.constants.CustomToneMapping;
import three.constants.ReinhardToneMapping;
import three.constants.LinearToneMapping;
import three.constants.GLSL3;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.P3Primaries;
import three.constants.Rec709Primaries;
import three.shaders.ShaderChunk;
import three.webgl.WebGLShader;
import three.webgl.WebGLUniforms;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

class WebGLProgram {

	static programIdCount:Int = 0;

	static handleSource(string:String, errorLine:Int):String {
		var lines = string.split("\n");
		var lines2 = new Array<String>();

		var from = Math.max(errorLine - 6, 0);
		var to = Math.min(errorLine + 6, lines.length);

		for (var i in from...to) {
			var line = i + 1;
			lines2.push(line == errorLine ? "> " : "  " + line + ": " + lines[i]);
		}

		return lines2.join("\n");
	}

	static getEncodingComponents(colorSpace:Int):Array<String> {
		var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
		var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

		var gamutMapping:String;

		if (workingPrimaries == encodingPrimaries) {
			gamutMapping = "";
		} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
			gamutMapping = "LinearDisplayP3ToLinearSRGB";
		} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
			gamutMapping = "LinearSRGBToLinearDisplayP3";
		}

		switch (colorSpace) {
			case LinearSRGBColorSpace:
			case LinearDisplayP3ColorSpace:
				return [gamutMapping, "LinearTransferOETF"];
			case SRGBColorSpace:
			case DisplayP3ColorSpace:
				return [gamutMapping, "sRGBTransferOETF"];
			default:
				Sys.println("THREE.WebGLProgram: Unsupported color space:", colorSpace);
				return [gamutMapping, "LinearTransferOETF"];
		}
	}

	static getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
		var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		var errors = gl.getShaderInfoLog(shader).trim();

		if (status && errors == "") return "";

		var errorMatches = errors.match(/ERROR: 0:(\d+)/);
		if (errorMatches != null) {
			// --enable-privileged-webgl-extension
			// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

			var errorLine = Std.parseInt(errorMatches[1]);
			return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
		} else {
			return errors;
		}
	}

	static getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
		var components = getEncodingComponents(colorSpace);
		return "vec4 " + functionName + "( vec4 value ) { return " + components[0] + "( " + components[1] + "( value ) ); }";
	}

	static getToneMappingFunction(functionName:String, toneMapping:Int):String {
		var toneMappingName:String;

		switch (toneMapping) {
			case LinearToneMapping:
				toneMappingName = "Linear";
				break;
			case ReinhardToneMapping:
				toneMappingName = "Reinhard";
				break;
			case CineonToneMapping:
				toneMappingName = "OptimizedCineon";
				break;
			case ACESFilmicToneMapping:
				toneMappingName = "ACESFilmic";
				break;
			case AgXToneMapping:
				toneMappingName = "AgX";
				break;
			case NeutralToneMapping:
				toneMappingName = "Neutral";
				break;
			case CustomToneMapping:
				toneMappingName = "Custom";
				break;
			default:
				Sys.println("THREE.WebGLProgram: Unsupported toneMapping:", toneMapping);
				toneMappingName = "Linear";
		}

		return "vec3 " + functionName + "( vec3 color ) { return " + toneMappingName + "ToneMapping( color ); }";
	}

	static generateVertexExtensions(parameters:Dynamic):String {
		var chunks = new Array<String>();

		chunks.push(parameters.extensionClipCullDistance ? "#extension GL_ANGLE_clip_cull_distance : require" : "");
		chunks.push(parameters.extensionMultiDraw ? "#extension GL_ANGLE_multi_draw : require" : "");

		return chunks.filter(filterEmptyLine).join("\n");
	}

	static generateDefines(defines:Dynamic):String {
		var chunks = new Array<String>();

		for (var name in defines) {
			var value = defines[name];

			if (value == false) continue;

			chunks.push("#define " + name + " " + value);
		}

		return chunks.join("\n");
	}

	static fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):Dynamic {
		var attributes = new Dynamic();

		var n = gl.getProgramParameter(program.program, gl.ACTIVE_ATTRIBUTES);

		for (var i in 0...n) {
			var info = gl.getActiveAttrib(program.program, i);
			var name = info.name;

			var locationSize = 1;
			if (info.type == gl.FLOAT_MAT2) locationSize = 2;
			if (info.type == gl.FLOAT_MAT3) locationSize = 3;
			if (info.type == gl.FLOAT_MAT4) locationSize = 4;

			// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

			attributes[name] = {
				type: info.type,
				location: gl.getAttribLocation(program.program, name),
				locationSize: locationSize
			};
		}

		return attributes;
	}

	static filterEmptyLine(string:String):Bool {
		return string != "";
	}

	static replaceLightNums(string:String, parameters:Dynamic):String {
		var numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		return string
			.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights.toString())
			.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights.toString())
			.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps.toString())
			.replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords.toString())
			.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights.toString())
			.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights.toString())
			.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights.toString())
			.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows.toString())
			.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows.toString());
	}

	static replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
		return string
			.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes.toString())
			.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection).toString());
	}

	// Resolve Includes

	static includePattern = ~r"^[ \t]*#include +<([\w\d./]+)>";

	static resolveIncludes(string:String):String {
		return string.replace(includePattern, includeReplacer);
	}

	static shaderChunkMap = new Map<String, String>();

	static includeReplacer(match:String, include:String):String {
		var string = ShaderChunk[include];

		if (string == null) {
			var newInclude = shaderChunkMap.get(include);

			if (newInclude != null) {
				string = ShaderChunk[newInclude];
				Sys.println("THREE.WebGLRenderer: Shader chunk \"" + include + "\" has been deprecated. Use \"" + newInclude + "\" instead.");
			} else {
				throw new Error("Can not resolve #include <" + include + ">");
			}
		}

		return resolveIncludes(string);
	}

	// Unroll Loops

	static unrollLoopPattern = ~r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end";

	static unrollLoops(string:String):String {
		return string.replace(unrollLoopPattern, loopReplacer);
	}

	static loopReplacer(match:String, start:String, end:String, snippet:String):String {
		var string = "";

		for (var i in Std.parseInt(start)...Std.parseInt(end)) {
			string += snippet
				.replace(/\[\s*i\s*\]/g, "[ " + i + " ]")
				.replace(/UNROLLED_LOOP_INDEX/g, i.toString());
		}

		return string;
	}

	//

	static generatePrecision(parameters:Dynamic):String {
		var precisionstring = "precision " + parameters.precision + " float;\n" +
			"precision " + parameters.precision + " int;\n" +
			"precision " + parameters.precision + " sampler2D;\n" +
			"precision " + parameters.precision + " samplerCube;\n" +
			"precision " + parameters.precision + " sampler3D;\n" +
			"precision " + parameters.precision + " sampler2DArray;\n" +
			"precision " + parameters.precision + " sampler2DShadow;\n" +
			"precision " + parameters.precision + " samplerCubeShadow;\n" +
			"precision " + parameters.precision + " sampler2DArrayShadow;\n" +
			"precision " + parameters.precision + " isampler2D;\n" +
			"precision " + parameters.precision + " isampler3D;\n" +
			"precision " + parameters.precision + " isamplerCube;\n" +
			"precision " + parameters.precision + " isampler2DArray;\n" +
			"precision " + parameters.precision + " usampler2D;\n" +
			"precision " + parameters.precision + " usampler3D;\n" +
			"precision " + parameters.precision + " usamplerCube;\n" +
			"precision " + parameters.precision + " usampler2DArray;\n";

		if (parameters.precision == "highp") {
			precisionstring += "\n#define HIGH_PRECISION";
		} else if (parameters.precision == "mediump") {
			precisionstring += "\n#define MEDIUM_PRECISION";
		} else if (parameters.precision == "lowp") {
			precisionstring += "\n#define LOW_PRECISION";
		}

		return precisionstring;
	}

	static generateShadowMapTypeDefine(parameters:Dynamic):String {
		var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

		if (parameters.shadowMapType == PCFShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
		} else if (parameters.shadowMapType == PCFSoftShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
		} else if (parameters.shadowMapType == VSMShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_VSM";
		}

		return shadowMapTypeDefine;
	}

	static generateEnvMapTypeDefine(parameters:Dynamic):String {
		var envMapTypeDefine = "ENVMAP_TYPE_CUBE";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeReflectionMapping:
				case CubeRefractionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE";
					break;
				case CubeUVReflectionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE_UV";
					break;
			}
		}

		return envMapTypeDefine;
	}

	static generateEnvMapModeDefine(parameters:Dynamic):String {
		var envMapModeDefine = "ENVMAP_MODE_REFLECTION";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeRefractionMapping:
					envMapModeDefine = "ENVMAP_MODE_REFRACTION";
					break;
			}
		}

		return envMapModeDefine;
	}

	static generateEnvMapBlendingDefine(parameters:Dynamic):String {
		var envMapBlendingDefine = "ENVMAP_BLENDING_NONE";

		if (parameters.envMap != null) {
			switch (parameters.combine) {
				case MultiplyOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MULTIPLY";
					break;
				case MixOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MIX";
					break;
				case AddOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_ADD";
					break;
			}
		}

		return envMapBlendingDefine;
	}

	static generateCubeUVSize(parameters:Dynamic):Dynamic {
		var imageHeight = parameters.envMapCubeUVHeight;

		if (imageHeight == null) return null;

		var maxMip = Math.log2(imageHeight) - 2;

		var texelHeight = 1.0 / imageHeight;

		var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

		return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
	}

	program:WebGLProgram;
	vertexShader:WebGLShader;
	fragmentShader:WebGLShader;
	type:String;
	name:String;
	id:Int;
	cacheKey:String;
	usedTimes:Int;
	cachedUniforms:WebGLUniforms;
	cachedAttributes:Dynamic;
	diagnostics:Dynamic;
	isReady:Bool;

	function new(renderer:Dynamic, cacheKey:String, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

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

		this.program = gl.createProgram();

		var prefixVertex:String;
		var prefixFragment:String;
		var versionString:String = parameters.glslVersion != null ? "#version " + parameters.glslVersion + "\n" : "";

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixVertex.length > 0) {
				prefixVertex += "\n";
			}

			prefixFragment = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixFragment.length > 0) {
				prefixFragment += "\n";
			}
		} else {
			prefixVertex = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.extensionClipCullDistance ? "#define USE_CLIP_DISTANCE" : "",
				parameters.batching ? "#define USE_BATCHING" : "",
				parameters.batchingColor ? "#define USE_BATCHING_COLOR" : "",
				parameters.instancing ? "#define USE_INSTANCING" : "",
				parameters.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
				parameters.instancingMorph ? "#define USE_INSTANCING_MORPH" : "",

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.map ? "#define USE_MAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",
				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				//

				parameters.mapUv ? "#define MAP_UV " + parameters.mapUv : "",
				parameters.alphaMapUv ? "#define ALPHAMAP_UV " + parameters.alphaMapUv : "",
				parameters.lightMapUv ? "#define LIGHTMAP_UV " + parameters.lightMapUv : "",
				parameters.aoMapUv ? "#define AOMAP_UV " + parameters.aoMapUv : "",
				parameters.emissiveMapUv ? "#define EMISSIVEMAP_UV " + parameters.emissiveMapUv : "",
				parameters.bumpMapUv ? "#define BUMPMAP_UV " + parameters.bumpMapUv : "",
				parameters.normalMapUv ? "#define NORMALMAP_UV " + parameters.normalMapUv : "",
				parameters.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + parameters.displacementMapUv : "",

				parameters.metalnessMapUv ? "#define METALNESSMAP_UV " + parameters.metalnessMapUv : "",
				parameters.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + parameters.roughnessMapUv : "",

				parameters.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + parameters.anisotropyMapUv : "",

				parameters.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + parameters.clearcoatMapUv : "",
				parameters.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + parameters.clearcoatNormalMapUv : "",
				parameters.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + parameters.clearcoatRoughnessMapUv : "",

				parameters.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + parameters.iridescenceMapUv : "",
				parameters.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + parameters.iridescenceThicknessMapUv : "",

				parameters.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + parameters.sheenColorMapUv : "",
				parameters.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + parameters.sheenRoughnessMapUv : "",

				parameters.specularMapUv ? "#define SPECULARMAP_UV " + parameters.specularMapUv : "",
				parameters.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + parameters.specularColorMapUv : "",
				parameters.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + parameters.specularIntensityMapUv : "",

				parameters.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + parameters.transmissionMapUv : "",
				parameters.thicknessMapUv ? "#define THICKNESSMAP_UV " + parameters.thicknessMapUv : "",

				//

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.skinning ? "#define USE_SKINNING" : "",

				parameters.morphTargets ? "#define USE_MORPHTARGETS" : "",
				parameters.morphNormals && parameters.flatShading == false ? "#define USE_MORPHNORMALS" : "",
				(parameters.morphColors) ? "#define USE_MORPHCOLORS" : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_TEXTURE_STRIDE " + parameters.morphTextureStride : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_COUNT " + parameters.morphTargetsCount : "",
				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 modelMatrix;",
				"uniform mat4 modelViewMatrix;",
				"uniform mat4 projectionMatrix;",
				"uniform mat4 viewMatrix;",
				"uniform mat3 normalMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				"#ifdef USE_INSTANCING",

				"	attribute mat4 instanceMatrix;",

				"#endif",

				"#ifdef USE_INSTANCING_COLOR",

				"	attribute vec3 instanceColor;",

				"#endif",

				"#ifdef USE_INSTANCING_MORPH",

				"	uniform sampler2D morphTexture;",

				"#endif",

				"attribute vec3 position;",
				"attribute vec3 normal;",
				"attribute vec2 uv;",

				"#ifdef USE_UV1",

				"	attribute vec2 uv1;",

				"#endif",

				"#ifdef USE_UV2",

				"	attribute vec2 uv2;",

				"#endif",

				"#ifdef USE_UV3",

				"	attribute vec2 uv3;",

				"#endif",

				"#ifdef USE_TANGENT",

				"	attribute vec4 tangent;",

				"#endif",

				"#if defined( USE_COLOR_ALPHA )",

				"	attribute vec4 color;",

				"#elif defined( USE_COLOR )",

				"	attribute vec3 color;",

				"#endif",

				"#ifdef USE_SKINNING",

				"	attribute vec4 skinIndex;",
				"	attribute vec4 skinWeight;",

				"#endif",

				"\n"

			].filter(filterEmptyLine).join("\n");

			prefixFragment = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.alphaToCoverage ? "#define ALPHA_TO_COVERAGE" : "",
				parameters.map ? "#define USE_MAP" : "",
				parameters.matcap ? "#define USE_MATCAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapTypeDefine : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.envMap ? "#define " + envMapBlendingDefine : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_WIDTH " + envMapCubeUVSize.texelWidth : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_HEIGHT " + envMapCubeUVSize.texelHeight : "",
				envMapCubeUVSize != null ? "#define CUBEUV_MAX_MIP " + envMapCubeUVSize.maxMip + ".0" : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoat ? "#define USE_CLEARCOAT" : "",
				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.dispersion ? "#define USE_DISPERSION" : "",

				parameters.iridescence ? "#define USE_IRIDESCENCE" : "",
				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",

				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaTest ? "#define USE_ALPHATEST" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.sheen ? "#define USE_SHEEN" : "",
				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.gradientMap ? "#define USE_GRADIENTMAP" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 viewMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				(parameters.toneMapping != NoToneMapping) ? "#define TONE_MAPPING" : "",
				(parameters.toneMapping != NoToneMapping) ? ShaderChunk["tonemapping_pars_fragment"] : "", // this code is required here because it is used by the toneMapping() function defined below
				(parameters.toneMapping != NoToneMapping) ? getToneMappingFunction("toneMapping", parameters.toneMapping) : "",

				parameters.dithering ? "#define DITHERING" : "",
				parameters.opaque ? "#define OPAQUE" : "",

				ShaderChunk["colorspace_pars_fragment"], // this code is required here because it is used by the various encoding/decoding function defined below
				getTexelEncodingFunction("linearToOutputTexel", parameters.outputColorSpace),

				parameters.useDepthPacking ? "#define DEPTH_PACKING " + parameters.depthPacking : "",

				"\n"

			].filter(filterEmptyLine).join("\n");
		}

		vertexShader = resolveIncludes(vertexShader);
		vertexShader = replaceLightNums(vertexShader, parameters);
		vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

		fragmentShader = resolveIncludes(fragmentShader);
		fragmentShader = replaceLightNums(fragmentShader, parameters);
		fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

		vertexShader = unrollLoops(vertexShader);
		fragmentShader = unrollLoops(fragmentShader);

		if (parameters.isRawShaderMaterial != true) {
			// GLSL 3.0 conversion for built-in materials and ShaderMaterial

			versionString = "#version 300 es\n";

			prefixVertex = [
				customVertexExtensions,
				"#define attribute in",
				"#define varying out",
				"#define texture2D texture"
			].join("\n") + "\n" + prefixVertex;

			prefixFragment = [
				"#define varying in",
				(parameters.glslVersion == GLSL3) ? "" : "layout(location = 0) out high
import three.constants.ColorManagement;
import three.constants.NoToneMapping;
import three.constants.AddOperation;
import three.constants.MixOperation;
import three.constants.MultiplyOperation;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.CubeReflectionMapping;
import three.constants.PCFSoftShadowMap;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.AgXToneMapping;
import three.constants.ACESFilmicToneMapping;
import three.constants.NeutralToneMapping;
import three.constants.CineonToneMapping;
import three.constants.CustomToneMapping;
import three.constants.ReinhardToneMapping;
import three.constants.LinearToneMapping;
import three.constants.GLSL3;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.P3Primaries;
import three.constants.Rec709Primaries;
import three.shaders.ShaderChunk;
import three.webgl.WebGLShader;
import three.webgl.WebGLUniforms;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

class WebGLProgram {

	static programIdCount:Int = 0;

	static handleSource(string:String, errorLine:Int):String {
		var lines = string.split("\n");
		var lines2 = new Array<String>();

		var from = Math.max(errorLine - 6, 0);
		var to = Math.min(errorLine + 6, lines.length);

		for (var i in from...to) {
			var line = i + 1;
			lines2.push(line == errorLine ? "> " : "  " + line + ": " + lines[i]);
		}

		return lines2.join("\n");
	}

	static getEncodingComponents(colorSpace:Int):Array<String> {
		var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
		var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

		var gamutMapping:String;

		if (workingPrimaries == encodingPrimaries) {
			gamutMapping = "";
		} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
			gamutMapping = "LinearDisplayP3ToLinearSRGB";
		} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
			gamutMapping = "LinearSRGBToLinearDisplayP3";
		}

		switch (colorSpace) {
			case LinearSRGBColorSpace:
			case LinearDisplayP3ColorSpace:
				return [gamutMapping, "LinearTransferOETF"];
			case SRGBColorSpace:
			case DisplayP3ColorSpace:
				return [gamutMapping, "sRGBTransferOETF"];
			default:
				Sys.println("THREE.WebGLProgram: Unsupported color space:", colorSpace);
				return [gamutMapping, "LinearTransferOETF"];
		}
	}

	static getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
		var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		var errors = gl.getShaderInfoLog(shader).trim();

		if (status && errors == "") return "";

		var errorMatches = errors.match(/ERROR: 0:(\d+)/);
		if (errorMatches != null) {
			// --enable-privileged-webgl-extension
			// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

			var errorLine = Std.parseInt(errorMatches[1]);
			return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
		} else {
			return errors;
		}
	}

	static getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
		var components = getEncodingComponents(colorSpace);
		return "vec4 " + functionName + "( vec4 value ) { return " + components[0] + "( " + components[1] + "( value ) ); }";
	}

	static getToneMappingFunction(functionName:String, toneMapping:Int):String {
		var toneMappingName:String;

		switch (toneMapping) {
			case LinearToneMapping:
				toneMappingName = "Linear";
				break;
			case ReinhardToneMapping:
				toneMappingName = "Reinhard";
				break;
			case CineonToneMapping:
				toneMappingName = "OptimizedCineon";
				break;
			case ACESFilmicToneMapping:
				toneMappingName = "ACESFilmic";
				break;
			case AgXToneMapping:
				toneMappingName = "AgX";
				break;
			case NeutralToneMapping:
				toneMappingName = "Neutral";
				break;
			case CustomToneMapping:
				toneMappingName = "Custom";
				break;
			default:
				Sys.println("THREE.WebGLProgram: Unsupported toneMapping:", toneMapping);
				toneMappingName = "Linear";
		}

		return "vec3 " + functionName + "( vec3 color ) { return " + toneMappingName + "ToneMapping( color ); }";
	}

	static generateVertexExtensions(parameters:Dynamic):String {
		var chunks = new Array<String>();

		chunks.push(parameters.extensionClipCullDistance ? "#extension GL_ANGLE_clip_cull_distance : require" : "");
		chunks.push(parameters.extensionMultiDraw ? "#extension GL_ANGLE_multi_draw : require" : "");

		return chunks.filter(filterEmptyLine).join("\n");
	}

	static generateDefines(defines:Dynamic):String {
		var chunks = new Array<String>();

		for (var name in defines) {
			var value = defines[name];

			if (value == false) continue;

			chunks.push("#define " + name + " " + value);
		}

		return chunks.join("\n");
	}

	static fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):Dynamic {
		var attributes = new Dynamic();

		var n = gl.getProgramParameter(program.program, gl.ACTIVE_ATTRIBUTES);

		for (var i in 0...n) {
			var info = gl.getActiveAttrib(program.program, i);
			var name = info.name;

			var locationSize = 1;
			if (info.type == gl.FLOAT_MAT2) locationSize = 2;
			if (info.type == gl.FLOAT_MAT3) locationSize = 3;
			if (info.type == gl.FLOAT_MAT4) locationSize = 4;

			// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

			attributes[name] = {
				type: info.type,
				location: gl.getAttribLocation(program.program, name),
				locationSize: locationSize
			};
		}

		return attributes;
	}

	static filterEmptyLine(string:String):Bool {
		return string != "";
	}

	static replaceLightNums(string:String, parameters:Dynamic):String {
		var numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		return string
			.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights.toString())
			.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights.toString())
			.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps.toString())
			.replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords.toString())
			.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights.toString())
			.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights.toString())
			.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights.toString())
			.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows.toString())
			.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows.toString());
	}

	static replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
		return string
			.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes.toString())
			.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection).toString());
	}

	// Resolve Includes

	static includePattern = ~r"^[ \t]*#include +<([\w\d./]+)>";

	static resolveIncludes(string:String):String {
		return string.replace(includePattern, includeReplacer);
	}

	static shaderChunkMap = new Map<String, String>();

	static includeReplacer(match:String, include:String):String {
		var string = ShaderChunk[include];

		if (string == null) {
			var newInclude = shaderChunkMap.get(include);

			if (newInclude != null) {
				string = ShaderChunk[newInclude];
				Sys.println("THREE.WebGLRenderer: Shader chunk \"" + include + "\" has been deprecated. Use \"" + newInclude + "\" instead.");
			} else {
				throw new Error("Can not resolve #include <" + include + ">");
			}
		}

		return resolveIncludes(string);
	}

	// Unroll Loops

	static unrollLoopPattern = ~r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end";

	static unrollLoops(string:String):String {
		return string.replace(unrollLoopPattern, loopReplacer);
	}

	static loopReplacer(match:String, start:String, end:String, snippet:String):String {
		var string = "";

		for (var i in Std.parseInt(start)...Std.parseInt(end)) {
			string += snippet
				.replace(/\[\s*i\s*\]/g, "[ " + i + " ]")
				.replace(/UNROLLED_LOOP_INDEX/g, i.toString());
		}

		return string;
	}

	//

	static generatePrecision(parameters:Dynamic):String {
		var precisionstring = "precision " + parameters.precision + " float;\n" +
			"precision " + parameters.precision + " int;\n" +
			"precision " + parameters.precision + " sampler2D;\n" +
			"precision " + parameters.precision + " samplerCube;\n" +
			"precision " + parameters.precision + " sampler3D;\n" +
			"precision " + parameters.precision + " sampler2DArray;\n" +
			"precision " + parameters.precision + " sampler2DShadow;\n" +
			"precision " + parameters.precision + " samplerCubeShadow;\n" +
			"precision " + parameters.precision + " sampler2DArrayShadow;\n" +
			"precision " + parameters.precision + " isampler2D;\n" +
			"precision " + parameters.precision + " isampler3D;\n" +
			"precision " + parameters.precision + " isamplerCube;\n" +
			"precision " + parameters.precision + " isampler2DArray;\n" +
			"precision " + parameters.precision + " usampler2D;\n" +
			"precision " + parameters.precision + " usampler3D;\n" +
			"precision " + parameters.precision + " usamplerCube;\n" +
			"precision " + parameters.precision + " usampler2DArray;\n";

		if (parameters.precision == "highp") {
			precisionstring += "\n#define HIGH_PRECISION";
		} else if (parameters.precision == "mediump") {
			precisionstring += "\n#define MEDIUM_PRECISION";
		} else if (parameters.precision == "lowp") {
			precisionstring += "\n#define LOW_PRECISION";
		}

		return precisionstring;
	}

	static generateShadowMapTypeDefine(parameters:Dynamic):String {
		var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

		if (parameters.shadowMapType == PCFShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
		} else if (parameters.shadowMapType == PCFSoftShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
		} else if (parameters.shadowMapType == VSMShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_VSM";
		}

		return shadowMapTypeDefine;
	}

	static generateEnvMapTypeDefine(parameters:Dynamic):String {
		var envMapTypeDefine = "ENVMAP_TYPE_CUBE";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeReflectionMapping:
				case CubeRefractionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE";
					break;
				case CubeUVReflectionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE_UV";
					break;
			}
		}

		return envMapTypeDefine;
	}

	static generateEnvMapModeDefine(parameters:Dynamic):String {
		var envMapModeDefine = "ENVMAP_MODE_REFLECTION";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeRefractionMapping:
					envMapModeDefine = "ENVMAP_MODE_REFRACTION";
					break;
			}
		}

		return envMapModeDefine;
	}

	static generateEnvMapBlendingDefine(parameters:Dynamic):String {
		var envMapBlendingDefine = "ENVMAP_BLENDING_NONE";

		if (parameters.envMap != null) {
			switch (parameters.combine) {
				case MultiplyOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MULTIPLY";
					break;
				case MixOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MIX";
					break;
				case AddOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_ADD";
					break;
			}
		}

		return envMapBlendingDefine;
	}

	static generateCubeUVSize(parameters:Dynamic):Dynamic {
		var imageHeight = parameters.envMapCubeUVHeight;

		if (imageHeight == null) return null;

		var maxMip = Math.log2(imageHeight) - 2;

		var texelHeight = 1.0 / imageHeight;

		var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

		return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
	}

	program:WebGLProgram;
	vertexShader:WebGLShader;
	fragmentShader:WebGLShader;
	type:String;
	name:String;
	id:Int;
	cacheKey:String;
	usedTimes:Int;
	cachedUniforms:WebGLUniforms;
	cachedAttributes:Dynamic;
	diagnostics:Dynamic;
	isReady:Bool;

	function new(renderer:Dynamic, cacheKey:String, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

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

		this.program = gl.createProgram();

		var prefixVertex:String;
		var prefixFragment:String;
		var versionString:String = parameters.glslVersion != null ? "#version " + parameters.glslVersion + "\n" : "";

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixVertex.length > 0) {
				prefixVertex += "\n";
			}

			prefixFragment = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixFragment.length > 0) {
				prefixFragment += "\n";
			}
		} else {
			prefixVertex = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.extensionClipCullDistance ? "#define USE_CLIP_DISTANCE" : "",
				parameters.batching ? "#define USE_BATCHING" : "",
				parameters.batchingColor ? "#define USE_BATCHING_COLOR" : "",
				parameters.instancing ? "#define USE_INSTANCING" : "",
				parameters.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
				parameters.instancingMorph ? "#define USE_INSTANCING_MORPH" : "",

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.map ? "#define USE_MAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",
				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				//

				parameters.mapUv ? "#define MAP_UV " + parameters.mapUv : "",
				parameters.alphaMapUv ? "#define ALPHAMAP_UV " + parameters.alphaMapUv : "",
				parameters.lightMapUv ? "#define LIGHTMAP_UV " + parameters.lightMapUv : "",
				parameters.aoMapUv ? "#define AOMAP_UV " + parameters.aoMapUv : "",
				parameters.emissiveMapUv ? "#define EMISSIVEMAP_UV " + parameters.emissiveMapUv : "",
				parameters.bumpMapUv ? "#define BUMPMAP_UV " + parameters.bumpMapUv : "",
				parameters.normalMapUv ? "#define NORMALMAP_UV " + parameters.normalMapUv : "",
				parameters.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + parameters.displacementMapUv : "",

				parameters.metalnessMapUv ? "#define METALNESSMAP_UV " + parameters.metalnessMapUv : "",
				parameters.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + parameters.roughnessMapUv : "",

				parameters.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + parameters.anisotropyMapUv : "",

				parameters.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + parameters.clearcoatMapUv : "",
				parameters.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + parameters.clearcoatNormalMapUv : "",
				parameters.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + parameters.clearcoatRoughnessMapUv : "",

				parameters.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + parameters.iridescenceMapUv : "",
				parameters.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + parameters.iridescenceThicknessMapUv : "",

				parameters.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + parameters.sheenColorMapUv : "",
				parameters.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + parameters.sheenRoughnessMapUv : "",

				parameters.specularMapUv ? "#define SPECULARMAP_UV " + parameters.specularMapUv : "",
				parameters.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + parameters.specularColorMapUv : "",
				parameters.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + parameters.specularIntensityMapUv : "",

				parameters.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + parameters.transmissionMapUv : "",
				parameters.thicknessMapUv ? "#define THICKNESSMAP_UV " + parameters.thicknessMapUv : "",

				//

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.skinning ? "#define USE_SKINNING" : "",

				parameters.morphTargets ? "#define USE_MORPHTARGETS" : "",
				parameters.morphNormals && parameters.flatShading == false ? "#define USE_MORPHNORMALS" : "",
				(parameters.morphColors) ? "#define USE_MORPHCOLORS" : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_TEXTURE_STRIDE " + parameters.morphTextureStride : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_COUNT " + parameters.morphTargetsCount : "",
				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 modelMatrix;",
				"uniform mat4 modelViewMatrix;",
				"uniform mat4 projectionMatrix;",
				"uniform mat4 viewMatrix;",
				"uniform mat3 normalMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				"#ifdef USE_INSTANCING",

				"	attribute mat4 instanceMatrix;",

				"#endif",

				"#ifdef USE_INSTANCING_COLOR",

				"	attribute vec3 instanceColor;",

				"#endif",

				"#ifdef USE_INSTANCING_MORPH",

				"	uniform sampler2D morphTexture;",

				"#endif",

				"attribute vec3 position;",
				"attribute vec3 normal;",
				"attribute vec2 uv;",

				"#ifdef USE_UV1",

				"	attribute vec2 uv1;",

				"#endif",

				"#ifdef USE_UV2",

				"	attribute vec2 uv2;",

				"#endif",

				"#ifdef USE_UV3",

				"	attribute vec2 uv3;",

				"#endif",

				"#ifdef USE_TANGENT",

				"	attribute vec4 tangent;",

				"#endif",

				"#if defined( USE_COLOR_ALPHA )",

				"	attribute vec4 color;",

				"#elif defined( USE_COLOR )",

				"	attribute vec3 color;",

				"#endif",

				"#ifdef USE_SKINNING",

				"	attribute vec4 skinIndex;",
				"	attribute vec4 skinWeight;",

				"#endif",

				"\n"

			].filter(filterEmptyLine).join("\n");

			prefixFragment = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.alphaToCoverage ? "#define ALPHA_TO_COVERAGE" : "",
				parameters.map ? "#define USE_MAP" : "",
				parameters.matcap ? "#define USE_MATCAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapTypeDefine : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.envMap ? "#define " + envMapBlendingDefine : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_WIDTH " + envMapCubeUVSize.texelWidth : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_HEIGHT " + envMapCubeUVSize.texelHeight : "",
				envMapCubeUVSize != null ? "#define CUBEUV_MAX_MIP " + envMapCubeUVSize.maxMip + ".0" : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoat ? "#define USE_CLEARCOAT" : "",
				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.dispersion ? "#define USE_DISPERSION" : "",

				parameters.iridescence ? "#define USE_IRIDESCENCE" : "",
				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",

				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaTest ? "#define USE_ALPHATEST" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.sheen ? "#define USE_SHEEN" : "",
				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.gradientMap ? "#define USE_GRADIENTMAP" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 viewMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				(parameters.toneMapping != NoToneMapping) ? "#define TONE_MAPPING" : "",
				(parameters.toneMapping != NoToneMapping) ? ShaderChunk["tonemapping_pars_fragment"] : "", // this code is required here because it is used by the toneMapping() function defined below
				(parameters.toneMapping != NoToneMapping) ? getToneMappingFunction("toneMapping", parameters.toneMapping) : "",

				parameters.dithering ? "#define DITHERING" : "",
				parameters.opaque ? "#define OPAQUE" : "",

				ShaderChunk["colorspace_pars_fragment"], // this code is required here because it is used by the various encoding/decoding function defined below
				getTexelEncodingFunction("linearToOutputTexel", parameters.outputColorSpace),

				parameters.useDepthPacking ? "#define DEPTH_PACKING " + parameters.depthPacking : "",

				"\n"

			].filter(filterEmptyLine).join("\n");
		}

		vertexShader = resolveIncludes(vertexShader);
		vertexShader = replaceLightNums(vertexShader, parameters);
		vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

		fragmentShader = resolveIncludes(fragmentShader);
		fragmentShader = replaceLightNums(fragmentShader, parameters);
		fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

		vertexShader = unrollLoops(vertexShader);
		fragmentShader = unrollLoops(fragmentShader);

		if (parameters.isRawShaderMaterial != true) {
			// GLSL 3.0 conversion for built-in materials and ShaderMaterial

			versionString = "#version 300 es\n";

			prefixVertex = [
				customVertexExtensions,
				"#define attribute in",
				"#define varying out",
				"#define texture2D texture"
			].join("\n") + "\n" + prefixVertex;

			prefixFragment = [
				"#define varying in",
				(parameters.glslVersion == GLSL3) ? "" : "layout(location = 0) out high
import three.constants.ColorManagement;
import three.constants.NoToneMapping;
import three.constants.AddOperation;
import three.constants.MixOperation;
import three.constants.MultiplyOperation;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.CubeReflectionMapping;
import three.constants.PCFSoftShadowMap;
import three.constants.PCFShadowMap;
import three.constants.VSMShadowMap;
import three.constants.AgXToneMapping;
import three.constants.ACESFilmicToneMapping;
import three.constants.NeutralToneMapping;
import three.constants.CineonToneMapping;
import three.constants.CustomToneMapping;
import three.constants.ReinhardToneMapping;
import three.constants.LinearToneMapping;
import three.constants.GLSL3;
import three.constants.LinearSRGBColorSpace;
import three.constants.SRGBColorSpace;
import three.constants.LinearDisplayP3ColorSpace;
import three.constants.DisplayP3ColorSpace;
import three.constants.P3Primaries;
import three.constants.Rec709Primaries;
import three.shaders.ShaderChunk;
import three.webgl.WebGLShader;
import three.webgl.WebGLUniforms;

// From https://www.khronos.org/registry/webgl/extensions/KHR_parallel_shader_compile/
const COMPLETION_STATUS_KHR = 0x91B1;

class WebGLProgram {

	static programIdCount:Int = 0;

	static handleSource(string:String, errorLine:Int):String {
		var lines = string.split("\n");
		var lines2 = new Array<String>();

		var from = Math.max(errorLine - 6, 0);
		var to = Math.min(errorLine + 6, lines.length);

		for (var i in from...to) {
			var line = i + 1;
			lines2.push(line == errorLine ? "> " : "  " + line + ": " + lines[i]);
		}

		return lines2.join("\n");
	}

	static getEncodingComponents(colorSpace:Int):Array<String> {
		var workingPrimaries = ColorManagement.getPrimaries(ColorManagement.workingColorSpace);
		var encodingPrimaries = ColorManagement.getPrimaries(colorSpace);

		var gamutMapping:String;

		if (workingPrimaries == encodingPrimaries) {
			gamutMapping = "";
		} else if (workingPrimaries == P3Primaries && encodingPrimaries == Rec709Primaries) {
			gamutMapping = "LinearDisplayP3ToLinearSRGB";
		} else if (workingPrimaries == Rec709Primaries && encodingPrimaries == P3Primaries) {
			gamutMapping = "LinearSRGBToLinearDisplayP3";
		}

		switch (colorSpace) {
			case LinearSRGBColorSpace:
			case LinearDisplayP3ColorSpace:
				return [gamutMapping, "LinearTransferOETF"];
			case SRGBColorSpace:
			case DisplayP3ColorSpace:
				return [gamutMapping, "sRGBTransferOETF"];
			default:
				Sys.println("THREE.WebGLProgram: Unsupported color space:", colorSpace);
				return [gamutMapping, "LinearTransferOETF"];
		}
	}

	static getShaderErrors(gl:WebGLRenderingContext, shader:WebGLShader, type:String):String {
		var status = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		var errors = gl.getShaderInfoLog(shader).trim();

		if (status && errors == "") return "";

		var errorMatches = errors.match(/ERROR: 0:(\d+)/);
		if (errorMatches != null) {
			// --enable-privileged-webgl-extension
			// console.log( '**' + type + '**', gl.getExtension( 'WEBGL_debug_shaders' ).getTranslatedShaderSource( shader ) );

			var errorLine = Std.parseInt(errorMatches[1]);
			return type.toUpperCase() + "\n\n" + errors + "\n\n" + handleSource(gl.getShaderSource(shader), errorLine);
		} else {
			return errors;
		}
	}

	static getTexelEncodingFunction(functionName:String, colorSpace:Int):String {
		var components = getEncodingComponents(colorSpace);
		return "vec4 " + functionName + "( vec4 value ) { return " + components[0] + "( " + components[1] + "( value ) ); }";
	}

	static getToneMappingFunction(functionName:String, toneMapping:Int):String {
		var toneMappingName:String;

		switch (toneMapping) {
			case LinearToneMapping:
				toneMappingName = "Linear";
				break;
			case ReinhardToneMapping:
				toneMappingName = "Reinhard";
				break;
			case CineonToneMapping:
				toneMappingName = "OptimizedCineon";
				break;
			case ACESFilmicToneMapping:
				toneMappingName = "ACESFilmic";
				break;
			case AgXToneMapping:
				toneMappingName = "AgX";
				break;
			case NeutralToneMapping:
				toneMappingName = "Neutral";
				break;
			case CustomToneMapping:
				toneMappingName = "Custom";
				break;
			default:
				Sys.println("THREE.WebGLProgram: Unsupported toneMapping:", toneMapping);
				toneMappingName = "Linear";
		}

		return "vec3 " + functionName + "( vec3 color ) { return " + toneMappingName + "ToneMapping( color ); }";
	}

	static generateVertexExtensions(parameters:Dynamic):String {
		var chunks = new Array<String>();

		chunks.push(parameters.extensionClipCullDistance ? "#extension GL_ANGLE_clip_cull_distance : require" : "");
		chunks.push(parameters.extensionMultiDraw ? "#extension GL_ANGLE_multi_draw : require" : "");

		return chunks.filter(filterEmptyLine).join("\n");
	}

	static generateDefines(defines:Dynamic):String {
		var chunks = new Array<String>();

		for (var name in defines) {
			var value = defines[name];

			if (value == false) continue;

			chunks.push("#define " + name + " " + value);
		}

		return chunks.join("\n");
	}

	static fetchAttributeLocations(gl:WebGLRenderingContext, program:WebGLProgram):Dynamic {
		var attributes = new Dynamic();

		var n = gl.getProgramParameter(program.program, gl.ACTIVE_ATTRIBUTES);

		for (var i in 0...n) {
			var info = gl.getActiveAttrib(program.program, i);
			var name = info.name;

			var locationSize = 1;
			if (info.type == gl.FLOAT_MAT2) locationSize = 2;
			if (info.type == gl.FLOAT_MAT3) locationSize = 3;
			if (info.type == gl.FLOAT_MAT4) locationSize = 4;

			// console.log( 'THREE.WebGLProgram: ACTIVE VERTEX ATTRIBUTE:', name, i );

			attributes[name] = {
				type: info.type,
				location: gl.getAttribLocation(program.program, name),
				locationSize: locationSize
			};
		}

		return attributes;
	}

	static filterEmptyLine(string:String):Bool {
		return string != "";
	}

	static replaceLightNums(string:String, parameters:Dynamic):String {
		var numSpotLightCoords = parameters.numSpotLightShadows + parameters.numSpotLightMaps - parameters.numSpotLightShadowsWithMaps;

		return string
			.replace(/NUM_DIR_LIGHTS/g, parameters.numDirLights.toString())
			.replace(/NUM_SPOT_LIGHTS/g, parameters.numSpotLights.toString())
			.replace(/NUM_SPOT_LIGHT_MAPS/g, parameters.numSpotLightMaps.toString())
			.replace(/NUM_SPOT_LIGHT_COORDS/g, numSpotLightCoords.toString())
			.replace(/NUM_RECT_AREA_LIGHTS/g, parameters.numRectAreaLights.toString())
			.replace(/NUM_POINT_LIGHTS/g, parameters.numPointLights.toString())
			.replace(/NUM_HEMI_LIGHTS/g, parameters.numHemiLights.toString())
			.replace(/NUM_DIR_LIGHT_SHADOWS/g, parameters.numDirLightShadows.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g, parameters.numSpotLightShadowsWithMaps.toString())
			.replace(/NUM_SPOT_LIGHT_SHADOWS/g, parameters.numSpotLightShadows.toString())
			.replace(/NUM_POINT_LIGHT_SHADOWS/g, parameters.numPointLightShadows.toString());
	}

	static replaceClippingPlaneNums(string:String, parameters:Dynamic):String {
		return string
			.replace(/NUM_CLIPPING_PLANES/g, parameters.numClippingPlanes.toString())
			.replace(/UNION_CLIPPING_PLANES/g, (parameters.numClippingPlanes - parameters.numClipIntersection).toString());
	}

	// Resolve Includes

	static includePattern = ~r"^[ \t]*#include +<([\w\d./]+)>";

	static resolveIncludes(string:String):String {
		return string.replace(includePattern, includeReplacer);
	}

	static shaderChunkMap = new Map<String, String>();

	static includeReplacer(match:String, include:String):String {
		var string = ShaderChunk[include];

		if (string == null) {
			var newInclude = shaderChunkMap.get(include);

			if (newInclude != null) {
				string = ShaderChunk[newInclude];
				Sys.println("THREE.WebGLRenderer: Shader chunk \"" + include + "\" has been deprecated. Use \"" + newInclude + "\" instead.");
			} else {
				throw new Error("Can not resolve #include <" + include + ">");
			}
		}

		return resolveIncludes(string);
	}

	// Unroll Loops

	static unrollLoopPattern = ~r"#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end";

	static unrollLoops(string:String):String {
		return string.replace(unrollLoopPattern, loopReplacer);
	}

	static loopReplacer(match:String, start:String, end:String, snippet:String):String {
		var string = "";

		for (var i in Std.parseInt(start)...Std.parseInt(end)) {
			string += snippet
				.replace(/\[\s*i\s*\]/g, "[ " + i + " ]")
				.replace(/UNROLLED_LOOP_INDEX/g, i.toString());
		}

		return string;
	}

	//

	static generatePrecision(parameters:Dynamic):String {
		var precisionstring = "precision " + parameters.precision + " float;\n" +
			"precision " + parameters.precision + " int;\n" +
			"precision " + parameters.precision + " sampler2D;\n" +
			"precision " + parameters.precision + " samplerCube;\n" +
			"precision " + parameters.precision + " sampler3D;\n" +
			"precision " + parameters.precision + " sampler2DArray;\n" +
			"precision " + parameters.precision + " sampler2DShadow;\n" +
			"precision " + parameters.precision + " samplerCubeShadow;\n" +
			"precision " + parameters.precision + " sampler2DArrayShadow;\n" +
			"precision " + parameters.precision + " isampler2D;\n" +
			"precision " + parameters.precision + " isampler3D;\n" +
			"precision " + parameters.precision + " isamplerCube;\n" +
			"precision " + parameters.precision + " isampler2DArray;\n" +
			"precision " + parameters.precision + " usampler2D;\n" +
			"precision " + parameters.precision + " usampler3D;\n" +
			"precision " + parameters.precision + " usamplerCube;\n" +
			"precision " + parameters.precision + " usampler2DArray;\n";

		if (parameters.precision == "highp") {
			precisionstring += "\n#define HIGH_PRECISION";
		} else if (parameters.precision == "mediump") {
			precisionstring += "\n#define MEDIUM_PRECISION";
		} else if (parameters.precision == "lowp") {
			precisionstring += "\n#define LOW_PRECISION";
		}

		return precisionstring;
	}

	static generateShadowMapTypeDefine(parameters:Dynamic):String {
		var shadowMapTypeDefine = "SHADOWMAP_TYPE_BASIC";

		if (parameters.shadowMapType == PCFShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF";
		} else if (parameters.shadowMapType == PCFSoftShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_PCF_SOFT";
		} else if (parameters.shadowMapType == VSMShadowMap) {
			shadowMapTypeDefine = "SHADOWMAP_TYPE_VSM";
		}

		return shadowMapTypeDefine;
	}

	static generateEnvMapTypeDefine(parameters:Dynamic):String {
		var envMapTypeDefine = "ENVMAP_TYPE_CUBE";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeReflectionMapping:
				case CubeRefractionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE";
					break;
				case CubeUVReflectionMapping:
					envMapTypeDefine = "ENVMAP_TYPE_CUBE_UV";
					break;
			}
		}

		return envMapTypeDefine;
	}

	static generateEnvMapModeDefine(parameters:Dynamic):String {
		var envMapModeDefine = "ENVMAP_MODE_REFLECTION";

		if (parameters.envMap != null) {
			switch (parameters.envMapMode) {
				case CubeRefractionMapping:
					envMapModeDefine = "ENVMAP_MODE_REFRACTION";
					break;
			}
		}

		return envMapModeDefine;
	}

	static generateEnvMapBlendingDefine(parameters:Dynamic):String {
		var envMapBlendingDefine = "ENVMAP_BLENDING_NONE";

		if (parameters.envMap != null) {
			switch (parameters.combine) {
				case MultiplyOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MULTIPLY";
					break;
				case MixOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_MIX";
					break;
				case AddOperation:
					envMapBlendingDefine = "ENVMAP_BLENDING_ADD";
					break;
			}
		}

		return envMapBlendingDefine;
	}

	static generateCubeUVSize(parameters:Dynamic):Dynamic {
		var imageHeight = parameters.envMapCubeUVHeight;

		if (imageHeight == null) return null;

		var maxMip = Math.log2(imageHeight) - 2;

		var texelHeight = 1.0 / imageHeight;

		var texelWidth = 1.0 / (3 * Math.max(Math.pow(2, maxMip), 7 * 16));

		return {texelWidth: texelWidth, texelHeight: texelHeight, maxMip: maxMip};
	}

	program:WebGLProgram;
	vertexShader:WebGLShader;
	fragmentShader:WebGLShader;
	type:String;
	name:String;
	id:Int;
	cacheKey:String;
	usedTimes:Int;
	cachedUniforms:WebGLUniforms;
	cachedAttributes:Dynamic;
	diagnostics:Dynamic;
	isReady:Bool;

	function new(renderer:Dynamic, cacheKey:String, parameters:Dynamic, bindingStates:Dynamic) {
		// TODO Send this event to Three.js DevTools
		// console.log( 'WebGLProgram', cacheKey );

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

		this.program = gl.createProgram();

		var prefixVertex:String;
		var prefixFragment:String;
		var versionString:String = parameters.glslVersion != null ? "#version " + parameters.glslVersion + "\n" : "";

		if (parameters.isRawShaderMaterial) {
			prefixVertex = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixVertex.length > 0) {
				prefixVertex += "\n";
			}

			prefixFragment = [

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines

			].filter(filterEmptyLine).join("\n");

			if (prefixFragment.length > 0) {
				prefixFragment += "\n";
			}
		} else {
			prefixVertex = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.extensionClipCullDistance ? "#define USE_CLIP_DISTANCE" : "",
				parameters.batching ? "#define USE_BATCHING" : "",
				parameters.batchingColor ? "#define USE_BATCHING_COLOR" : "",
				parameters.instancing ? "#define USE_INSTANCING" : "",
				parameters.instancingColor ? "#define USE_INSTANCING_COLOR" : "",
				parameters.instancingMorph ? "#define USE_INSTANCING_MORPH" : "",

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.map ? "#define USE_MAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.displacementMap ? "#define USE_DISPLACEMENTMAP" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",
				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				//

				parameters.mapUv ? "#define MAP_UV " + parameters.mapUv : "",
				parameters.alphaMapUv ? "#define ALPHAMAP_UV " + parameters.alphaMapUv : "",
				parameters.lightMapUv ? "#define LIGHTMAP_UV " + parameters.lightMapUv : "",
				parameters.aoMapUv ? "#define AOMAP_UV " + parameters.aoMapUv : "",
				parameters.emissiveMapUv ? "#define EMISSIVEMAP_UV " + parameters.emissiveMapUv : "",
				parameters.bumpMapUv ? "#define BUMPMAP_UV " + parameters.bumpMapUv : "",
				parameters.normalMapUv ? "#define NORMALMAP_UV " + parameters.normalMapUv : "",
				parameters.displacementMapUv ? "#define DISPLACEMENTMAP_UV " + parameters.displacementMapUv : "",

				parameters.metalnessMapUv ? "#define METALNESSMAP_UV " + parameters.metalnessMapUv : "",
				parameters.roughnessMapUv ? "#define ROUGHNESSMAP_UV " + parameters.roughnessMapUv : "",

				parameters.anisotropyMapUv ? "#define ANISOTROPYMAP_UV " + parameters.anisotropyMapUv : "",

				parameters.clearcoatMapUv ? "#define CLEARCOATMAP_UV " + parameters.clearcoatMapUv : "",
				parameters.clearcoatNormalMapUv ? "#define CLEARCOAT_NORMALMAP_UV " + parameters.clearcoatNormalMapUv : "",
				parameters.clearcoatRoughnessMapUv ? "#define CLEARCOAT_ROUGHNESSMAP_UV " + parameters.clearcoatRoughnessMapUv : "",

				parameters.iridescenceMapUv ? "#define IRIDESCENCEMAP_UV " + parameters.iridescenceMapUv : "",
				parameters.iridescenceThicknessMapUv ? "#define IRIDESCENCE_THICKNESSMAP_UV " + parameters.iridescenceThicknessMapUv : "",

				parameters.sheenColorMapUv ? "#define SHEEN_COLORMAP_UV " + parameters.sheenColorMapUv : "",
				parameters.sheenRoughnessMapUv ? "#define SHEEN_ROUGHNESSMAP_UV " + parameters.sheenRoughnessMapUv : "",

				parameters.specularMapUv ? "#define SPECULARMAP_UV " + parameters.specularMapUv : "",
				parameters.specularColorMapUv ? "#define SPECULAR_COLORMAP_UV " + parameters.specularColorMapUv : "",
				parameters.specularIntensityMapUv ? "#define SPECULAR_INTENSITYMAP_UV " + parameters.specularIntensityMapUv : "",

				parameters.transmissionMapUv ? "#define TRANSMISSIONMAP_UV " + parameters.transmissionMapUv : "",
				parameters.thicknessMapUv ? "#define THICKNESSMAP_UV " + parameters.thicknessMapUv : "",

				//

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.skinning ? "#define USE_SKINNING" : "",

				parameters.morphTargets ? "#define USE_MORPHTARGETS" : "",
				parameters.morphNormals && parameters.flatShading == false ? "#define USE_MORPHNORMALS" : "",
				(parameters.morphColors) ? "#define USE_MORPHCOLORS" : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_TEXTURE_STRIDE " + parameters.morphTextureStride : "",
				(parameters.morphTargetsCount > 0) ? "#define MORPHTARGETS_COUNT " + parameters.morphTargetsCount : "",
				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.sizeAttenuation ? "#define USE_SIZEATTENUATION" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 modelMatrix;",
				"uniform mat4 modelViewMatrix;",
				"uniform mat4 projectionMatrix;",
				"uniform mat4 viewMatrix;",
				"uniform mat3 normalMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				"#ifdef USE_INSTANCING",

				"	attribute mat4 instanceMatrix;",

				"#endif",

				"#ifdef USE_INSTANCING_COLOR",

				"	attribute vec3 instanceColor;",

				"#endif",

				"#ifdef USE_INSTANCING_MORPH",

				"	uniform sampler2D morphTexture;",

				"#endif",

				"attribute vec3 position;",
				"attribute vec3 normal;",
				"attribute vec2 uv;",

				"#ifdef USE_UV1",

				"	attribute vec2 uv1;",

				"#endif",

				"#ifdef USE_UV2",

				"	attribute vec2 uv2;",

				"#endif",

				"#ifdef USE_UV3",

				"	attribute vec2 uv3;",

				"#endif",

				"#ifdef USE_TANGENT",

				"	attribute vec4 tangent;",

				"#endif",

				"#if defined( USE_COLOR_ALPHA )",

				"	attribute vec4 color;",

				"#elif defined( USE_COLOR )",

				"	attribute vec3 color;",

				"#endif",

				"#ifdef USE_SKINNING",

				"	attribute vec4 skinIndex;",
				"	attribute vec4 skinWeight;",

				"#endif",

				"\n"

			].filter(filterEmptyLine).join("\n");

			prefixFragment = [

				generatePrecision(parameters),

				"#define SHADER_TYPE " + parameters.shaderType,
				"#define SHADER_NAME " + parameters.shaderName,

				customDefines,

				parameters.useFog && parameters.fog ? "#define USE_FOG" : "",
				parameters.useFog && parameters.fogExp2 ? "#define FOG_EXP2" : "",

				parameters.alphaToCoverage ? "#define ALPHA_TO_COVERAGE" : "",
				parameters.map ? "#define USE_MAP" : "",
				parameters.matcap ? "#define USE_MATCAP" : "",
				parameters.envMap ? "#define USE_ENVMAP" : "",
				parameters.envMap ? "#define " + envMapTypeDefine : "",
				parameters.envMap ? "#define " + envMapModeDefine : "",
				parameters.envMap ? "#define " + envMapBlendingDefine : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_WIDTH " + envMapCubeUVSize.texelWidth : "",
				envMapCubeUVSize != null ? "#define CUBEUV_TEXEL_HEIGHT " + envMapCubeUVSize.texelHeight : "",
				envMapCubeUVSize != null ? "#define CUBEUV_MAX_MIP " + envMapCubeUVSize.maxMip + ".0" : "",
				parameters.lightMap ? "#define USE_LIGHTMAP" : "",
				parameters.aoMap ? "#define USE_AOMAP" : "",
				parameters.bumpMap ? "#define USE_BUMPMAP" : "",
				parameters.normalMap ? "#define USE_NORMALMAP" : "",
				parameters.normalMapObjectSpace ? "#define USE_NORMALMAP_OBJECTSPACE" : "",
				parameters.normalMapTangentSpace ? "#define USE_NORMALMAP_TANGENTSPACE" : "",
				parameters.emissiveMap ? "#define USE_EMISSIVEMAP" : "",

				parameters.anisotropy ? "#define USE_ANISOTROPY" : "",
				parameters.anisotropyMap ? "#define USE_ANISOTROPYMAP" : "",

				parameters.clearcoat ? "#define USE_CLEARCOAT" : "",
				parameters.clearcoatMap ? "#define USE_CLEARCOATMAP" : "",
				parameters.clearcoatRoughnessMap ? "#define USE_CLEARCOAT_ROUGHNESSMAP" : "",
				parameters.clearcoatNormalMap ? "#define USE_CLEARCOAT_NORMALMAP" : "",

				parameters.dispersion ? "#define USE_DISPERSION" : "",

				parameters.iridescence ? "#define USE_IRIDESCENCE" : "",
				parameters.iridescenceMap ? "#define USE_IRIDESCENCEMAP" : "",
				parameters.iridescenceThicknessMap ? "#define USE_IRIDESCENCE_THICKNESSMAP" : "",

				parameters.specularMap ? "#define USE_SPECULARMAP" : "",
				parameters.specularColorMap ? "#define USE_SPECULAR_COLORMAP" : "",
				parameters.specularIntensityMap ? "#define USE_SPECULAR_INTENSITYMAP" : "",

				parameters.roughnessMap ? "#define USE_ROUGHNESSMAP" : "",
				parameters.metalnessMap ? "#define USE_METALNESSMAP" : "",

				parameters.alphaMap ? "#define USE_ALPHAMAP" : "",
				parameters.alphaTest ? "#define USE_ALPHATEST" : "",
				parameters.alphaHash ? "#define USE_ALPHAHASH" : "",

				parameters.sheen ? "#define USE_SHEEN" : "",
				parameters.sheenColorMap ? "#define USE_SHEEN_COLORMAP" : "",
				parameters.sheenRoughnessMap ? "#define USE_SHEEN_ROUGHNESSMAP" : "",

				parameters.transmission ? "#define USE_TRANSMISSION" : "",
				parameters.transmissionMap ? "#define USE_TRANSMISSIONMAP" : "",
				parameters.thicknessMap ? "#define USE_THICKNESSMAP" : "",

				parameters.vertexTangents && parameters.flatShading == false ? "#define USE_TANGENT" : "",
				parameters.vertexColors || parameters.instancingColor || parameters.batchingColor ? "#define USE_COLOR" : "",
				parameters.vertexAlphas ? "#define USE_COLOR_ALPHA" : "",
				parameters.vertexUv1s ? "#define USE_UV1" : "",
				parameters.vertexUv2s ? "#define USE_UV2" : "",
				parameters.vertexUv3s ? "#define USE_UV3" : "",

				parameters.pointsUvs ? "#define USE_POINTS_UV" : "",

				parameters.gradientMap ? "#define USE_GRADIENTMAP" : "",

				parameters.flatShading ? "#define FLAT_SHADED" : "",

				parameters.doubleSided ? "#define DOUBLE_SIDED" : "",
				parameters.flipSided ? "#define FLIP_SIDED" : "",

				parameters.shadowMapEnabled ? "#define USE_SHADOWMAP" : "",
				parameters.shadowMapEnabled ? "#define " + shadowMapTypeDefine : "",

				parameters.premultipliedAlpha ? "#define PREMULTIPLIED_ALPHA" : "",

				parameters.numLightProbes > 0 ? "#define USE_LIGHT_PROBES" : "",

				parameters.useLegacyLights ? "#define LEGACY_LIGHTS" : "",

				parameters.decodeVideoTexture ? "#define DECODE_VIDEO_TEXTURE" : "",

				parameters.logarithmicDepthBuffer ? "#define USE_LOGDEPTHBUF" : "",

				"uniform mat4 viewMatrix;",
				"uniform vec3 cameraPosition;",
				"uniform bool isOrthographic;",

				(parameters.toneMapping != NoToneMapping) ? "#define TONE_MAPPING" : "",
				(parameters.toneMapping != NoToneMapping) ? ShaderChunk["tonemapping_pars_fragment"] : "", // this code is required here because it is used by the toneMapping() function defined below
				(parameters.toneMapping != NoToneMapping) ? getToneMappingFunction("toneMapping", parameters.toneMapping) : "",

				parameters.dithering ? "#define DITHERING" : "",
				parameters.opaque ? "#define OPAQUE" : "",

				ShaderChunk["colorspace_pars_fragment"], // this code is required here because it is used by the various encoding/decoding function defined below
				getTexelEncodingFunction("linearToOutputTexel", parameters.outputColorSpace),

				parameters.useDepthPacking ? "#define DEPTH_PACKING " + parameters.depthPacking : "",

				"\n"

			].filter(filterEmptyLine).join("\n");
		}

		vertexShader = resolveIncludes(vertexShader);
		vertexShader = replaceLightNums(vertexShader, parameters);
		vertexShader = replaceClippingPlaneNums(vertexShader, parameters);

		fragmentShader = resolveIncludes(fragmentShader);
		fragmentShader = replaceLightNums(fragmentShader, parameters);
		fragmentShader = replaceClippingPlaneNums(fragmentShader, parameters);

		vertexShader = unrollLoops(vertexShader);
		fragmentShader = unrollLoops(fragmentShader);

		if (parameters.isRawShaderMaterial != true) {
			// GLSL 3.0 conversion for built-in materials and ShaderMaterial

			versionString = "#version 300 es\n";

			prefixVertex = [
				customVertexExtensions,
				"#define attribute in",
				"#define varying out",
				"#define texture2D texture"
			].join("\n") + "\n" + prefixVertex;

			prefixFragment = [
				"#define varying in",
				(parameters.glslVersion == GLSL3) ? "" : "layout(location = 0) out high