package three.js.src.renderers.webgl;

import three.js.constants.BackSide;
import three.js.constants.DoubleSide;
import three.js.constants.CubeUVReflectionMapping;
import three.js.constants.ObjectSpaceNormalMap;
import three.js.constants.TangentSpaceNormalMap;
import three.js.constants.NoToneMapping;
import three.js.constants.NormalBlending;
import three.js.constants.LinearSRGBColorSpace;
import three.js.constants.SRGBTransfer;

import three.js.core.Layers;
import three.js.renderers.webgl.WebGLProgram;
import three.js.renderers.webgl.WebGLShaderCache;
import three.js.shaders.ShaderLib;
import three.js.shaders.UniformsUtils;
import three.js.math.ColorManagement;

class WebGLPrograms {
    private var _programLayers:Layers;
    private var _customShaders:WebGLShaderCache;
    private var _activeChannels:Set<Int>;
    private var programs:Array<WebGLProgram>;

    public function new(renderer:WebGLRenderer, cubemaps:Array<Texture>, cubeuvmaps:Array<Texture>, extensions:Array<WebGLExtension>, capabilities:WebGLCapabilities, bindingStates:BindingStates, clipping:Clipping) {
        _programLayers = new Layers();
        _customShaders = new WebGLShaderCache();
        _activeChannels = new Set();
        programs = [];

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
            var envMapCubeUVHeight = (envMap != null && envMap.mapping == CubeUVReflectionMapping) ? envMap.image.height : null;

            var shaderID = shaderIDs[material.type];

            // Heuristics to create shader parameters according to lights in the scene
            // (not to blow over maxLights budget)

            if (material.precision != null) {
                precision = capabilities.getMaxPrecision(material.precision);

                if (precision != material.precision) {
                    // log warning
                }
            }

            // ...

            var parameters = {
                shaderID: shaderID,
                shaderType: material.type,
                shaderName: material.name,

                vertexShader: vertexShader,
                fragmentShader: fragmentShader,
                defines: material.defines,

                customVertexShaderID: customVertexShaderID,
                customFragmentShaderID: customFragmentShaderID,

                isRawShaderMaterial: material.isRawShaderMaterial === true,
                glslVersion: material.glslVersion,

                precision: precision,

                batching: isBatchedMesh,
                batchingColor: isBatchedMesh && object.colorsTexture != null,
                instancing: isInstancedMesh,
                instancingColor: isInstancedMesh && object.instanceColor != null,
                instancingMorph: isInstancedMesh && object.morphTexture != null,

                supportsVertexTextures: SUPPORTS_VERTEX_TEXTURES,
                outputColorSpace: currentRenderTarget == null ? renderer.outputColorSpace : (currentRenderTarget.isXRRenderTarget === true ? currentRenderTarget.texture.colorSpace : LinearSRGBColorSpace),
                alphaToCoverage: material.alphaToCoverage != null,

                map: hasMap,
                matcap: hasMatcap,
                envMap: hasEnvMap,
                envMapMode: hasEnvMap && envMap.mapping,
                envMapCubeUVHeight: envMapCubeUVHeight,
                aoMap: hasAOMap,
                lightMap: hasLightMap,
                bumpMap: hasBumpMap,
                normalMap: hasNormalMap,
                displacementMap: SUPPORTS_VERTEX_TEXTURES && hasDisplacementMap,
                emissiveMap: hasEmissiveMap,

                normalMapObjectSpace: hasNormalMap && material.normalMapType == ObjectSpaceNormalMap,
                normalMapTangentSpace: hasNormalMap && material.normalMapType == TangentSpaceNormalMap,

                metalnessMap: hasMetalnessMap,
                roughnessMap: hasRoughnessMap,

                anisotropy: hasAnisotropy,
                anisotropyMap: hasAnisotropyMap,

                clearcoat: hasClearcoat,
                clearcoatMap: hasClearcoatMap,
                clearcoatNormalMap: hasClearcoatNormalMap,
                clearcoatRoughnessMap: hasClearcoatRoughnessMap,

                dispersion: hasDispersion,

                iridescence: hasIridescence,
                iridescenceMap: hasIridescenceMap,
                iridescenceThicknessMap: hasIridescenceThicknessMap,

                sheen: hasSheen,
                sheenColorMap: hasSheenColorMap,
                sheenRoughnessMap: hasSheenRoughnessMap,

                specularMap: hasSpecularMap,
                specularColorMap: hasSpecularColorMap,
                specularIntensityMap: hasSpecularIntensityMap,

                transmission: hasTransmission,
                transmissionMap: hasTransmissionMap,
                thicknessMap: hasThicknessMap,

                gradientMap: hasGradientMap,

                opaque: material.transparent === false && material.blending === NormalBlending && material.alphaToCoverage === false,

                alphaMap: hasAlphaMap,
                alphaTest: hasAlphaTest,
                alphaHash: hasAlphaHash,

                combine: material.combine,

                // ...
            };

            // the usage of getChannel() determines the active texture channels for this shader

            parameters.vertexUv1s = _activeChannels.has(1);
            parameters.vertexUv2s = _activeChannels.has(2);
            parameters.vertexUv3s = _activeChannels.has(3);

            _activeChannels.clear();

            return parameters;
        }

        function getProgramCacheKey(parameters:Parameters):String {
            // ...
        }

        function getProgramCacheKeyParameters(array:Array<String>, parameters:Parameters):Void {
            // ...
        }

        function getProgramCacheKeyBooleans(array:Array<String>, parameters:Parameters):Void {
            // ...
        }

        function acquireProgram(parameters:Parameters, cacheKey:String):WebGLProgram {
            var program;

            // Check if code has been already compiled
            for (p in programs) {
                if (p.cacheKey == cacheKey) {
                    program = p;
                    ++ program.usedTimes;
                    break;
                }
            }

            if (program == null) {
                program = new WebGLProgram(renderer, cacheKey, parameters, bindingStates);
                programs.push(program);
            }

            return program;
        }

        function releaseProgram(program:WebGLProgram):Void {
            if (-- program.usedTimes == 0) {
                // Remove from unordered set
                var i = programs.indexOf(program);
                programs[i] = programs[programs.length - 1];
                programs.pop();

                // Free WebGL resources
                program.destroy();
            }
        }

        function releaseShaderCache(material:Material):Void {
            _customShaders.remove(material);
        }

        function dispose():Void {
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