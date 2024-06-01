import haxe.ds.IntMap;
import haxe.ds.StringMap;

class WebGLShaderCache {

	public var shaderCache:IntMap<WebGLShaderStage>;
	public var materialCache:StringMap<Array<WebGLShaderStage>>;

	public function new() {
		this.shaderCache = new IntMap();
		this.materialCache = new StringMap();
	}

	public function update(material:Dynamic):WebGLShaderCache {
		var vertexShader = material.vertexShader;
		var fragmentShader = material.fragmentShader;

		var vertexShaderStage = this._getShaderStage(vertexShader);
		var fragmentShaderStage = this._getShaderStage(fragmentShader);

		var materialShaders = this._getShaderCacheForMaterial(material);

		if (!materialShaders.contains(vertexShaderStage)) {
			materialShaders.push(vertexShaderStage);
			vertexShaderStage.usedTimes++;
		}

		if (!materialShaders.contains(fragmentShaderStage)) {
			materialShaders.push(fragmentShaderStage);
			fragmentShaderStage.usedTimes++;
		}

		return this;
	}

	public function remove(material:Dynamic):WebGLShaderCache {
		var materialShaders = this.materialCache.get(material);

		if (materialShaders != null) {
			for (shaderStage in materialShaders) {
				shaderStage.usedTimes--;

				if (shaderStage.usedTimes == 0) {
					this.shaderCache.remove(shaderStage.code);
				}
			}

			this.materialCache.remove(material);
		}

		return this;
	}

	public function getVertexShaderID(material:Dynamic):Int {
		return this._getShaderStage(material.vertexShader).id;
	}

	public function getFragmentShaderID(material:Dynamic):Int {
		return this._getShaderStage(material.fragmentShader).id;
	}

	public function dispose():Void {
		this.shaderCache.clear();
		this.materialCache.clear();
	}

	private function _getShaderCacheForMaterial(material:Dynamic):Array<WebGLShaderStage> {
		var cache = this.materialCache;
		var set = cache.get(material);

		if (set == null) {
			set = [];
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

	public var id:Int;
	public var code:String;
	public var usedTimes:Int;

	public function new(code:String) {
		this.id = _id++;
		this.code = code;
		this.usedTimes = 0;
	}

}

var _id:Int = 0;

class Main {

	static function main():Void {
		// Example usage of WebGLShaderCache
		var shaderCache = new WebGLShaderCache();

		var material1 = {vertexShader: "vertexShader1", fragmentShader: "fragmentShader1"};
		var material2 = {vertexShader: "vertexShader1", fragmentShader: "fragmentShader2"};

		shaderCache.update(material1);
		shaderCache.update(material2);

		trace("Vertex Shader ID for material1: " + shaderCache.getVertexShaderID(material1));
		trace("Fragment Shader ID for material2: " + shaderCache.getFragmentShaderID(material2));

		shaderCache.remove(material1);

		trace("Vertex Shader ID for material1 (after removal): " + shaderCache.getVertexShaderID(material1));

		shaderCache.dispose();
	}

}