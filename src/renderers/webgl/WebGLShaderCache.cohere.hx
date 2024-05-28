var _id: Int = 0;

class WebGLShaderCache {
	public var shaderCache: Map<String, WebGLShaderStage>;
	public var materialCache: Map<Dynamic, Set<WebGLShaderStage>>;

	public function new() {
		shaderCache = new Map();
		materialCache = new Map();
	}

	public function update(material: Dynamic): WebGLShaderCache {
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

	public function remove(material: Dynamic): WebGLShaderCache {
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

	public function getVertexShaderID(material: Dynamic): Int {
		return _getShaderStage(material.vertexShader).id;
	}

	public function getFragmentShaderID(material: Dynamic): Int {
		return _getShaderStage(material.fragmentShader).id;
	}

	public function dispose(): Void {
		shaderCache.clear();
		materialCache.clear();
	}

	private function _getShaderCacheForMaterial(material: Dynamic): Set<WebGLShaderStage> {
		var cache = materialCache;
		var set = cache.get(material);

		if (set == null) {
			set = new Set();
			cache.set(material, set);
		}

		return set;
	}

	private function _getShaderStage(code: String): WebGLShaderStage {
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
	public var id: Int;
	public var code: String;
	public var usedTimes: Int;

	public function new(code: String) {
		id = _id++;
		this.code = code;
		usedTimes = 0;
	}
}