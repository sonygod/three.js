import three.js.src.constants.BackSide;
import three.js.src.constants.DoubleSide;
import three.js.src.constants.CubeUVReflectionMapping;
import three.js.src.constants.ObjectSpaceNormalMap;
import three.js.src.constants.TangentSpaceNormalMap;
import three.js.src.constants.NoToneMapping;
import three.js.src.constants.NormalBlending;
import three.js.src.constants.LinearSRGBColorSpace;
import three.js.src.constants.SRGBTransfer;
import three.js.src.core.Layers;
import three.js.src.renderers.webgl.WebGLProgram;
import three.js.src.renderers.webgl.WebGLShaderCache;
import three.js.src.shaders.ShaderLib;
import three.js.src.shaders.UniformsUtils;
import three.js.src.math.ColorManagement;

class WebGLPrograms {
    private var _programLayers:Layers;
    private var _customShaders:WebGLShaderCache;
    private var _activeChannels:Set<Int>;
    private var programs:Array<WebGLProgram>;

    private var logarithmicDepthBuffer:Bool;
    private var SUPPORTS_VERTEX_TEXTURES:Bool;

    private var precision:String;

    private var shaderIDs:Map<String, String>;

    public function new(renderer:WebGLRenderer, cubemaps:CubeUVReflectionMapping, cubeuvmaps:CubeUVReflectionMapping, extensions:Map<String, Bool>, capabilities:Map<String, Dynamic>, bindingStates:Map<String, Dynamic>, clipping:Map<String, Dynamic>) {
        _programLayers = new Layers();
        _customShaders = new WebGLShaderCache();
        _activeChannels = new Set<Int>();
        programs = [];

        logarithmicDepthBuffer = capabilities.get("logarithmicDepthBuffer");
        SUPPORTS_VERTEX_TEXTURES = capabilities.get("vertexTextures");

        precision = capabilities.get("precision");

        shaderIDs = new Map<String, String>();
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

    private function getChannel(value:Int):String {
        _activeChannels.add(value);

        if (value == 0) return "uv";

        return "uv" + value;
    }

    private function getParameters(material:Dynamic, lights:Dynamic, shadows:Dynamic, scene:Dynamic, object:Dynamic):Dynamic {
        // ...
    }

    private function getProgramCacheKey(parameters:Dynamic):String {
        // ...
    }

    private function getProgramCacheKeyParameters(array:Array<Dynamic>, parameters:Dynamic):Void {
        // ...
    }

    private function getProgramCacheKeyBooleans(array:Array<Dynamic>, parameters:Dynamic):Void {
        // ...
    }

    private function getUniforms(material:Dynamic):Dynamic {
        // ...
    }

    private function acquireProgram(parameters:Dynamic, cacheKey:String):WebGLProgram {
        // ...
    }

    private function releaseProgram(program:WebGLProgram):Void {
        // ...
    }

    private function releaseShaderCache(material:Dynamic):Void {
        // ...
    }

    public function dispose():Void {
        // ...
    }
}