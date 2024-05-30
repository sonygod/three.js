class MMDLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
		this.loader = new FileLoader(manager);
		this.parser = null; // lazy generation
		this.meshBuilder = new MeshBuilder(manager);
		this.animationBuilder = new AnimationBuilder();
	}

	public function setAnimationPath(animationPath:String):MMDLoader {
		this.animationPath = animationPath;
		return this;
	}

	// Load MMD assets as Three.js Object

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var builder = this.meshBuilder.setCrossOrigin(this.crossOrigin);
		var resourcePath:String = if (this.resourcePath != "") this.resourcePath else if (this.path != "") this.path else LoaderUtils.extractUrlBase(url);
		var parser = this._getParser();
		var extractModelExtension = this._extractModelExtension;
		this.loader
			.setMimeType(null)
			.setPath(this.path)
			.setResponseType("arraybuffer")
			.setRequestHeader(this.requestHeader)
			.setWithCredentials(this.withCredentials)
			.load(url, function(buffer:ArrayBuffer) {
				try {
					var modelExtension = extractModelExtension(buffer);
					if (modelExtension != "pmd" && modelExtension != "pmx") {
						if (onError != null) onError(new Error("THREE.MMDLoader: Unknown model file extension ." + modelExtension + "."));
						return;
					}
					var data = modelExtension == "pmd" ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);
					onLoad(builder.build(data, resourcePath, onProgress, onError));
				} catch (e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	// ... 其他方法的转换，与上述JavaScript代码类似 ...

	private function _extractModelExtension(buffer:ArrayBuffer):String {
		var decoder = new TextDecoder("utf-8");
		var bytes = new Uint8Array(buffer, 0, 3);
		return decoder.decode(bytes).toLowerCase();
	}

	private function _getParser():Dynamic {
		if (this.parser == null) {
			this.parser = new MMDParser.Parser();
		}
		return this.parser;
	}
}