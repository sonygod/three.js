package three.renderers.webgl;

import haxe.ds.Map;

class WebGLShaderCache {

    private var shaderCache:Map<String, WebGLShaderStage>;
    private var materialCache:Map<Dynamic, Set<WebGLShaderStage>>;

    public function new() {
        this.shaderCache = new Map();
        this.materialCache = new Map();
    }

    public function update(material:Dynamic):WebGLShaderCache {
        var vertexShader = material.vertexShader;
        var fragmentShader = material.fragmentShader;

        var vertexShaderStage = this._getShaderStage(vertexShader);
        var fragmentShaderStage = this._getShaderStage(fragmentShader);

        var materialShaders = this._getShaderCacheForMaterial(material);

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

    public function remove(material:Dynamic):WebGLShaderCache {
        var materialShaders = this.materialCache.get(material);

        for (shaderStage in materialShaders) {
            shaderStage.usedTimes--;

            if (shaderStage.usedTimes == 0) {
                this.shaderCache.remove(shaderStage.code);
            }
        }

        this.materialCache.remove(material);

        return this;
    }

    public function getVertexShaderID(material:Dynamic):Int {
        return this._getShaderStage(material.vertexShader).id;
    }

    public function getFragmentShaderID(material:Dynamic):Int {
        return this._getShaderStage(material.fragmentShader).id;
    }

    public function dispose():Void {
        this.shaderCache = new Map();
        this.materialCache = new Map();
    }

    private function _getShaderCacheForMaterial(material:Dynamic):Set<WebGLShaderStage> {
        var set = this.materialCache.get(material);

        if (set == null) {
            set = new Set();
            this.materialCache.set(material, set);
        }

        return set;
    }

    private function _getShaderStage(code:String):WebGLShaderStage {
        var stage = this.shaderCache.get(code);

        if (stage == null) {
            stage = new WebGLShaderStage(code);
            this.shaderCache.set(code, stage);
        }

        return stage;
    }
}

class WebGLShaderStage {
    public static var _id:Int = 0;

    public var id:Int;
    public var code:String;
    public var usedTimes:Int;

    public function new(code:String) {
        this.id = _id++;
        this.code = code;
        this.usedTimes = 0;
    }
}