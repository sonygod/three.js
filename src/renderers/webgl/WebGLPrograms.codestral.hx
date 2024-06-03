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

	var _programLayers:Layers;
	var _customShaders:WebGLShaderCache;
	var _activeChannels:Set<Int>;
	var programs:Array<WebGLProgram>;

	var logarithmicDepthBuffer:Bool;
	var SUPPORTS_VERTEX_TEXTURES:Bool;

	var precision:Int;

	var shaderIDs:haxe.ds.StringMap<String>;

	public function new(renderer, cubemaps, cubeuvmaps, extensions, capabilities, bindingStates, clipping) {

		_programLayers = new Layers();
		_customShaders = new WebGLShaderCache();
		_activeChannels = new haxe.ds.IntMap<Bool>();
		programs = new Array<WebGLProgram>();

		logarithmicDepthBuffer = capabilities.logarithmicDepthBuffer;
		SUPPORTS_VERTEX_TEXTURES = capabilities.vertexTextures;

		precision = capabilities.precision;

		shaderIDs = new haxe.ds.StringMap<String>();
		shaderIDs.set("MeshDepthMaterial", "depth");
		shaderIDs.set("MeshDistanceMaterial", "distanceRGBA");
		shaderIDs.set("MeshNormalMaterial", "normal");
		shaderIDs.set("MeshBasicMaterial", "basic");
		shaderIDs.set("MeshLambertMaterial", "lambert");
		shaderIDs.set("MeshPhongMaterial", "phong");
		shaderIDs.set("MeshToonMaterial", "toon");
		shaderIDs.set("MeshStandardMaterial", "physical");
		shaderIDs.set("MeshPhysicalMaterial", "physical");
		shaderIDs.set("MeshMatcapMaterial", "matcap");
		shaderIDs.set("LineBasicMaterial", "basic");
		shaderIDs.set("LineDashedMaterial", "dashed");
		shaderIDs.set("PointsMaterial", "points");
		shaderIDs.set("ShadowMaterial", "shadow");
		shaderIDs.set("SpriteMaterial", "sprite");
	}

	public function getChannel(value:Int):String {

		_activeChannels.set(value, true);

		if (value == 0) return "uv";

		return "uv${value}";
	}

	public function getParameters(material, lights, shadows, scene, object):haxe.ds.StringMap<Dynamic> {

		// ... continue converting the rest of the function here

	}

	// ... continue converting the rest of the class here

}