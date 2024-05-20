class WebGLShaderCache {

	var shaderCache:Map<String, WebGLShaderStage>;
	var materialCache:Map<Material, Set<WebGLShaderStage>>;
	static var _id:Int = 0;

	public function new() {

		this.shaderCache = new Map();
		this.materialCache = new Map();

	}

	public function update(material:Material):WebGLShaderCache {

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

	public function remove(material:Material):WebGLShaderCache {

		var materialShaders = this.materialCache.get(material);

		for (shaderStage in materialShaders) {

			shaderStage.usedTimes--;

			if (shaderStage.usedTimes == 0) this.shaderCache.remove(shaderStage.code);

		}

		this.materialCache.remove(material);

		return this;

	}

	public function getVertexShaderID(material:Material):Int {

		return this._getShaderStage(material.vertexShader).id;

	}

	public function getFragmentShaderID(material:Material):Int {

		return this._getShaderStage(material.fragmentShader).id;

	}

	public function dispose():Void {

		this.shaderCache.clear();
		this.materialCache.clear();

	}

	private function _getShaderCacheForMaterial(material:Material):Set<WebGLShaderStage> {

		var cache = this.materialCache;
		var set = cache.get(material);

		if (set == null) {

			set = new Set();
			cache.set(material, set);

		}

		return set;

	}

	private function _getShaderStage(code:String):WebGLShaderStage {

		var cache = this.shaderCache;
		var stage = cache.get(code);

		if (stage == null) {

			stage = new WebGLShaderStage(code);
			cache.set(code, stage);

		}

		return stage;

	}

}

class WebGLShaderStage {

	public var id(default, null):Int;
	public var code(default, null):String;
	public var usedTimes(default, null):Int;

	public function new(code:String) {

		this.id = WebGLShaderCache._id++;

		this.code = code;
		this.usedTimes = 0;

	}

}