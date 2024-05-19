import three.js.src.loaders.LoadingManager;

class Loader {

	var manager:LoadingManager;
	var crossOrigin:String;
	var withCredentials:Bool;
	var path:String;
	var resourcePath:String;
	var requestHeader:Dynamic;

	public function new(manager:LoadingManager) {
		this.manager = (manager != null) ? manager : LoadingManager.DefaultLoadingManager;
		this.crossOrigin = 'anonymous';
		this.withCredentials = false;
		this.path = '';
		this.resourcePath = '';
		this.requestHeader = {};
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {}

	public function loadAsync(url:String, onProgress:Dynamic->Void):Promise<Dynamic> {
		var scope = this;
		return new Promise(function(resolve, reject) {
			scope.load(url, resolve, onProgress, reject);
		});
	}

	public function parse(data:Dynamic):Dynamic {}

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

	public static var DEFAULT_MATERIAL_NAME:String = '__DEFAULT';
}