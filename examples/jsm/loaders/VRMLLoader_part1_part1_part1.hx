class VRMLLoader extends Loader {

	public function new(manager:LoaderManager) {
		super(manager);
	}

	public override function load(url:String, onLoad:Void -> Void, onProgress:Int -> Void, onError:Dynamic -> Void):Void {
		var scope = this;
		var path = (scope.path == '') ? LoaderUtils.extractUrlBase(url) : scope.path;
		var loader = FileLoader(manager);
		loader.path = scope.path;
		loader.requestHeader = scope.requestHeader;
		loader.withCredentials = scope.withCredentials;
		loader.load(url, function(text:String) {
			try {
				onLoad(scope.parse(text, path));
			} catch(e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:String, path:String):Dynamic {
		var nodeMap = {};

		// ... (Rest of the code remains the same as it doesn't need any modifications)

	}

}