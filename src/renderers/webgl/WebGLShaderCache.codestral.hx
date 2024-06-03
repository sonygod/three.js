import haxe.ds.StringMap;
import haxe.ds.Set;

class WebGLShaderCache {
    private var _id: Int = 0;
    private var shaderCache: StringMap<WebGLShaderStage>;
    private var materialCache: StringMap<Set<WebGLShaderStage>>;

    public function new() {
        this.shaderCache = new StringMap();
        this.materialCache = new StringMap();
    }

    public function update(material: Material): WebGLShaderCache {
        var vertexShader: String = material.vertexShader;
        var fragmentShader: String = material.fragmentShader;

        var vertexShaderStage: WebGLShaderStage = this._getShaderStage(vertexShader);
        var fragmentShaderStage: WebGLShaderStage = this._getShaderStage(fragmentShader);

        var materialShaders: Set<WebGLShaderStage> = this._getShaderCacheForMaterial(material);

        if (!materialShaders.exists(vertexShaderStage)) {
            materialShaders.add(vertexShaderStage);
            vertexShaderStage.usedTimes++;
        }

        if (!materialShaders.exists(fragmentShaderStage)) {
            materialShaders.add(fragmentShaderStage);
            fragmentShaderStage.usedTimes++;
        }

        return this;
    }

    public function remove(material: Material): WebGLShaderCache {
        var materialShaders: Set<WebGLShaderStage> = this.materialCache.get(material);

        for (shaderStage in materialShaders) {
            shaderStage.usedTimes--;

            if (shaderStage.usedTimes == 0) {
                this.shaderCache.remove(shaderStage.code);
            }
        }

        this.materialCache.remove(material);

        return this;
    }

    public function getVertexShaderID(material: Material): Int {
        return this._getShaderStage(material.vertexShader).id;
    }

    public function getFragmentShaderID(material: Material): Int {
        return this._getShaderStage(material.fragmentShader).id;
    }

    public function dispose(): Void {
        this.shaderCache.clear();
        this.materialCache.clear();
    }

    private function _getShaderCacheForMaterial(material: Material): Set<WebGLShaderStage> {
        var cache: StringMap<Set<WebGLShaderStage>> = this.materialCache;
        var set: Set<WebGLShaderStage> = cache.get(material);

        if (set == null) {
            set = new Set();
            cache.set(material, set);
        }

        return set;
    }

    private function _getShaderStage(code: String): WebGLShaderStage {
        var cache: StringMap<WebGLShaderStage> = this.shaderCache;
        var stage: WebGLShaderStage = cache.get(code);

        if (stage == null) {
            stage = new WebGLShaderStage(code);
            cache.set(code, stage);
        }

        return stage;
    }
}

class WebGLShaderStage {
    public var id: Int;
    public var code: String;
    public var usedTimes: Int;

    public function new(code: String) {
        this.id = WebGLShaderCache._id++;
        this.code = code;
        this.usedTimes = 0;
    }
}

class Material {
    public var vertexShader: String;
    public var fragmentShader: String;

    public function new(vertexShader: String, fragmentShader: String) {
        this.vertexShader = vertexShader;
        this.fragmentShader = fragmentShader;
    }
}