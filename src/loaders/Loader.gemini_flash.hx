import three.loaders.LoadingManager;

class Loader {

	public var manager:LoadingManager;

	public var crossOrigin:String = "anonymous";
	public var withCredentials:Bool = false;
	public var path:String = "";
	public var resourcePath:String = "";
	public var requestHeader:Dynamic = {};

	public function new(manager:LoadingManager = null) {
		this.manager = manager != null ? manager : LoadingManager.default;
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		// Override this method in subclasses
	}

	public function loadAsync(url:String, onProgress:Dynamic):Dynamic {
		var scope = this;
		return new Promise((resolve:Dynamic, reject:Dynamic) -> {
			scope.load(url, resolve, onProgress, reject);
		});
	}

	public function parse(data:Dynamic):Void {
		// Override this method in subclasses
	}

	public function setCrossOrigin(crossOrigin:String):Loader {
		this.crossOrigin = crossOrigin;
		return this;
	}

	public function setWithCredentials(value:Bool):Loader {
		this.withCredentials = value;
		return this;
	}

	public function setPath(path:String):Loader {
		this.path = path;
		return this;
	}

	public function setResourcePath(resourcePath:String):Loader {
		this.resourcePath = resourcePath;
		return this;
	}

	public function setRequestHeader(requestHeader:Dynamic):Loader {
		this.requestHeader = requestHeader;
		return this;
	}

}

Loader.DEFAULT_MATERIAL_NAME = "__DEFAULT";