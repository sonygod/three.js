package three.js.src.renderers.webgl;

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

    public function new(renderer:WebGLRenderer, cubemaps:Array<Texture>, cubeuvmaps:Array<Texture>, extensions:Extensions, capabilities:Capabilities, bindingStates:BindingStates, clipping:Clipping) {
        _programLayers = new Layers();
        _customShaders = new WebGLShaderCache();
        _activeChannels = new Set<Int>();
        programs = new Array<WebGLProgram>();

        var logarithmicDepthBuffer = capabilities.logarithmicDepthBuffer;
        var SUPPORTS_VERTEX_TEXTURES = capabilities.vertexTextures;

        var precision = capabilities.precision;

        var shaderIDs = [
            'MeshDepthMaterial' => 'depth',
            'MeshDistanceMaterial' => 'distanceRGBA',
            'MeshNormalMaterial' => 'normal',
            'MeshBasicMaterial' => 'basic',
            'MeshLambertMaterial' => 'lambert',
            'MeshPhongMaterial' => 'phong',
            'MeshToonMaterial' => 'toon',
            'MeshStandardMaterial' => 'physical',
            'MeshPhysicalMaterial' => 'physical',
            'MeshMatcapMaterial' => 'matcap',
            'LineBasicMaterial' => 'basic',
            'LineDashedMaterial' => 'dashed',
            'PointsMaterial' => 'points',
            'ShadowMaterial' => 'shadow',
            'SpriteMaterial' => 'sprite'
        ];

        function getChannel(value:Int):String {
            _activeChannels.add(value);

            if (value == 0) return 'uv';
            return 'uv' + value;
        }

        function getParameters(material:Material, lights:Array<Light>, shadows:Array<Shadow>, scene:Scene, object:Object3D):Parameters {
            var fog = scene.fog;
            var geometry = object.geometry;
            var environment = material.isMeshStandardMaterial ? scene.environment : null;

            var envMap = (material.isMeshStandardMaterial ? cubeuvmaps : cubemaps).get(material.envMap || environment);
            var envMapCubeUVHeight = envMap != null && envMap.mapping == CubeUVReflectionMapping ? envMap.image.height : null;

            var shaderID = shaderIDs[material.type];

            // ... (rest of the code remains the same)

            return parameters;
        }

        function getProgramCacheKey(parameters:Parameters):String {
            var array = [];

            if (parameters.shaderID != null) {
                array.push(parameters.shaderID);
            } else {
                array.push(parameters.customVertexShaderID);
                array.push(parameters.customFragmentShaderID);
            }

            // ... (rest of the code remains the same)

            return array.join();
        }

        function getProgramCacheKeyParameters(array:Array<String>, parameters:Parameters) {
            array.push(parameters.precision);
            array.push(parameters.outputColorSpace);
            array.push(parameters.envMapMode);
            array.push(parameters.envMapCubeUVHeight);
            array.push(parameters.mapUv);
            array.push(parameters.alphaMapUv);
            // ... (rest of the code remains the same)
        }

        function getProgramCacheKeyBooleans(array:Array<String>, parameters:Parameters) {
            _programLayers.disableAll();

            if (parameters.supportsVertexTextures) _programLayers.enable(0);
            if (parameters.instancing) _programLayers.enable(1);
            if (parameters.instancingColor) _programLayers.enable(2);
            if (parameters.instancingMorph) _programLayers.enable(3);
            if (parameters.matcap) _programLayers.enable(4);
            if (parameters.envMap) _programLayers.enable(5);
            if (parameters.normalMapObjectSpace) _programLayers.enable(6);
            if (parameters.normalMapTangentSpace) _programLayers.enable(7);
            // ... (rest of the code remains the same)
        }

        function acquireProgram(parameters:Parameters, cacheKey:String):WebGLProgram {
            var program:WebGLProgram;

            for (p in programs) {
                if (p.cacheKey == cacheKey) {
                    program = p;
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

        function releaseProgram(program:WebGLProgram) {
            if (--program.usedTimes == 0) {
                var i = programs.indexOf(program);
                programs[ i ] = programs[ programs.length - 1 ];
                programs.pop();

                program.destroy();
            }
        }

        function releaseShaderCache(material:Material) {
            _customShaders.remove(material);
        }

        function dispose() {
            _customShaders.dispose();
        }

        return {
            getParameters: getParameters,
            getProgramCacheKey: getProgramCacheKey,
            getUniforms: getUniforms,
            acquireProgram: acquireProgram,
            releaseProgram: releaseProgram,
            releaseShaderCache: releaseShaderCache,
            dispose: dispose
        };
    }
}