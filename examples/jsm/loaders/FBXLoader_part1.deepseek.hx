class FBXLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		var path = (scope.path == "") ? LoaderUtils.extractUrlBase(url) : scope.path;
		var loader = new FileLoader(this.manager);
		loader.setPath(scope.path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function(buffer:ArrayBuffer) {
			try {
				onLoad(scope.parse(buffer, path));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					trace(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(FBXBuffer:ArrayBuffer, path:String):Dynamic {
		if (isFbxFormatBinary(FBXBuffer)) {
			var fbxTree = new BinaryParser().parse(FBXBuffer);
		} else {
			var FBXText = convertArrayBufferToString(FBXBuffer);
			if (!isFbxFormatASCII(FBXText)) {
				throw 'THREE.FBXLoader: Unknown format.';
			}
			if (getFbxVersion(FBXText) < 7000) {
				throw 'THREE.FBXLoader: FBX version not supported, FileVersion: ' + getFbxVersion(FBXText);
			}
			fbxTree = new TextParser().parse(FBXText);
		}
		var textureLoader = new TextureLoader(this.manager).setPath(this.resourcePath || path).setCrossOrigin(this.crossOrigin);
		return new FBXTreeParser(textureLoader, this.manager).parse(fbxTree);
	}
}