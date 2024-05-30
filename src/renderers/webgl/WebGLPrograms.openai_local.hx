package renderers.webgl;

import three.constants.*;

class WebGLPrograms {
    
    private var _programLayers: Layers;
    private var _customShaders: WebGLShaderCache;
    private var _activeChannels: Set<Int>;
    private var programs: Array<WebGLProgram>;

    private var logarithmicDepthBuffer: Bool;
    private var SUPPORTS_VERTEX_TEXTURES: Bool;

    private var precision: String;

    private var shaderIDs: Map<String>;

    public function new(
        renderer: Dynamic, 
        cubemaps: Dynamic, 
        cubeuvmaps: Dynamic, 
        extensions: Dynamic, 
        capabilities: Dynamic, 
        bindingStates: Dynamic, 
        clipping: Dynamic
    ) {
        _programLayers = new Layers();
        _customShaders = new WebGLShaderCache();
        _activeChannels = new Set<Int>();
        programs = [];

        logarithmicDepthBuffer = capabilities.logarithmicDepthBuffer;
        SUPPORTS_VERTEX_TEXTURES = capabilities.vertexTextures;

        precision = capabilities.precision;

        shaderIDs = {
            MeshDepthMaterial: 'depth',
            MeshDistanceMaterial: 'distanceRGBA',
            MeshNormalMaterial: 'normal',
            MeshBasicMaterial: 'basic',
            MeshLambertMaterial: 'lambert',
            MeshPhongMaterial: 'phong',
            MeshToonMaterial: 'toon',
            MeshStandardMaterial: 'physical',
            MeshPhysicalMaterial: 'physical',
            MeshMatcapMaterial: 'matcap',
            LineBasicMaterial: 'basic',
            LineDashedMaterial: 'dashed',
            PointsMaterial: 'points',
            ShadowMaterial: 'shadow',
            SpriteMaterial: 'sprite'
        };
    }

    private function getChannel(value: Int): String {
        _activeChannels.add(value);

        if (value == 0) return 'uv';

        return 'uv' + value;
    }

    public function getParameters(material: Dynamic, lights: Dynamic, shadows: Dynamic, scene: Dynamic, object: Dynamic): Dynamic {
        // Implementation...
        return null;
    }

    private function getProgramCacheKey(parameters: Dynamic): String {
        // Implementation...
        return "";
    }

    private function getProgramCacheKeyParameters(array: Array<Dynamic>, parameters: Dynamic): Void {
        // Implementation...
    }

    private function getProgramCacheKeyBooleans(array: Array<Dynamic>, parameters: Dynamic): Void {
        // Implementation...
    }

    public function getUniforms(material: Dynamic): Dynamic {
        // Implementation...
        return null;
    }

    public function acquireProgram(parameters: Dynamic, cacheKey: String): Dynamic {
        // Implementation...
        return null;
    }

    public function releaseProgram(program: Dynamic): Void {
        // Implementation...
    }

    public function releaseShaderCache(material: Dynamic): Void {
        // Implementation...
    }

    public function dispose(): Void {
        // Implementation...
    }
}