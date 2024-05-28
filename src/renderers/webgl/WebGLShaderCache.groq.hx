package three.js.src.renderers.webgl;

import haxe.ds.Map;
import haxe.ds.StringMap;

class WebGLShaderCache {
    private var shaderCache:Map<String, WebGLShaderStage>;
    private var materialCache:Map<Material, Set<WebGLShaderStage>>;

    public function new() {
        shaderCache = new Map<String, WebGLShaderStage>();
        materialCache = new StringMap<Set<WebGLShaderStage>>();
    }

    public function update(material:Material):WebGLShaderCache {
        var vertexShader = material.vertexShader;
        var fragmentShader = material.fragmentShader;

        var vertexShaderStage = _getShaderStage(vertexShader);
        var fragmentShaderStage = _getShaderStage(fragmentShader);

        var materialShaders = _getShaderCacheForMaterial(material);

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

    public function remove(material:Material):WebGLShaderCache {
        var materialShaders = materialCache.get(material);

        for (shaderStage in materialShaders) {
            shaderStage.usedTimes--;

            if (shaderStage.usedTimes == 0) {
                shaderCache.remove(shaderStage.code);
            }
        }

        materialCache.remove(material);

        return this;
    }

    public function getVertexShaderID(material:Material):Int {
        return _getShaderStage(material.vertexShader).id;
    }

    public function getFragmentShaderID(material:Material):Int {
        return _getShaderStage(material.fragmentShader).id;
    }

    public function dispose() {
        shaderCache.clear();
        materialCache.clear();
    }

    private function _getShaderCacheForMaterial(material:Material):Set<WebGLShaderStage> {
        var cache = materialCache;
        var set = cache.get(material);

        if (set == null) {
            set = new Set<WebGLShaderStage>();
            cache.set(material, set);
        }

        return set;
    }

    private function _getShaderStage(code:String):WebGLShaderStage {
        var cache = shaderCache;
        var stage = cache.get(code);

        if (stage == null) {
            stage = new WebGLShaderStage(code);
            cache.set(code, stage);
        }

        return stage;
    }
}

class WebGLShaderStage {
    public var id:Int;
    public var code:String;
    public var usedTimes:Int;

    public function new(code:String) {
        id = _id++;
        this.code = code;
        usedTimes = 0;
    }
}

class Set<T> {
    private var map:Map<T, Bool>;

    public function new() {
        map = new Map<T, Bool>();
    }

    public function add(item:T) {
        map.set(item, true);
    }

    public function exists(item:T):Bool {
        return map.exists(item);
    }

    public function remove(item:T) {
        map.remove(item);
    }

    public function iterator():Iterator<T> {
        return map.keys();
    }
}

var _id = 0;