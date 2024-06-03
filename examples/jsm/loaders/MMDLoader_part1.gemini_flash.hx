import three.loaders.Loader;
import three.loaders.FileLoader;
import three.loaders.LoaderUtils;
import three.core.MeshBuilder;
import three.animation.AnimationBuilder;
import three.loaders.MMDParser;

class MMDLoader extends Loader {

	public var loader:FileLoader;
	public var parser:MMDParser.Parser;
	public var meshBuilder:MeshBuilder;
	public var animationBuilder:AnimationBuilder;

	public var animationPath:String;

	public function new(manager:Loader) {
		super(manager);

		loader = new FileLoader(manager);
		parser = null;
		meshBuilder = new MeshBuilder(manager);
		animationBuilder = new AnimationBuilder();
	}

	public function setAnimationPath(animationPath:String):MMDLoader {
		this.animationPath = animationPath;
		return this;
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var builder = meshBuilder.setCrossOrigin(crossOrigin);

		var resourcePath:String;
		if (resourcePath != "") {
			resourcePath = this.resourcePath;
		} else if (path != "") {
			resourcePath = this.path;
		} else {
			resourcePath = LoaderUtils.extractUrlBase(url);
		}

		parser = _getParser();
		var extractModelExtension = _extractModelExtension;

		loader
			.setMimeType(null)
			.setPath(path)
			.setResponseType('arraybuffer')
			.setRequestHeader(requestHeader)
			.setWithCredentials(withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					var modelExtension = extractModelExtension(buffer);
					if (modelExtension != "pmd" && modelExtension != "pmx") {
						if (onError != null) onError(new Error("THREE.MMDLoader: Unknown model file extension ." + modelExtension + "."));
						return;
					}

					var data:Dynamic = modelExtension == "pmd" ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);
					onLoad(builder.build(data, resourcePath, onProgress, onError));
				} catch(e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadAnimation(url:String, object:Dynamic, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var builder = animationBuilder;
		loadVMD(url, function(vmd:Dynamic) {
			onLoad(object.isCamera ? builder.buildCameraAnimation(vmd) : builder.build(vmd, object));
		}, onProgress, onError);
	}

	public function loadWithAnimation(modelUrl:String, vmdUrl:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var scope = this;
		load(modelUrl, function(mesh:Dynamic) {
			scope.loadAnimation(vmdUrl, mesh, function(animation:Dynamic) {
				onLoad({
					mesh:mesh,
					animation:animation
				});
			}, onProgress, onError);
		}, onProgress, onError);
	}

	public function loadPMD(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var parser = _getParser();
		loader
			.setMimeType(null)
			.setPath(path)
			.setResponseType('arraybuffer')
			.setRequestHeader(requestHeader)
			.setWithCredentials(withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmd(buffer, true));
				} catch(e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadPMX(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var parser = _getParser();
		loader
			.setMimeType(null)
			.setPath(path)
			.setResponseType('arraybuffer')
			.setRequestHeader(requestHeader)
			.setWithCredentials(withCredentials)
			.load(url, function(buffer:haxe.io.Bytes) {
				try {
					onLoad(parser.parsePmx(buffer, true));
				} catch(e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	public function loadVMD(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var urls:Array<String> = url.split(',');
		var vmds:Array<Dynamic> = [];
		var vmdNum:Int = urls.length;
		var parser = _getParser();

		loader
			.setMimeType(null)
			.setPath(animationPath)
			.setResponseType('arraybuffer')
			.setRequestHeader(requestHeader)
			.setWithCredentials(withCredentials);

		for (i in 0...urls.length) {
			loader.load(urls[i], function(buffer:haxe.io.Bytes) {
				try {
					vmds.push(parser.parseVmd(buffer, true));
					if (vmds.length == vmdNum) onLoad(parser.mergeVmds(vmds));
				} catch(e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
		}
	}

	public function loadVPD(url:String, isUnicode:Bool, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
		var parser = _getParser();
		loader
			.setMimeType(isUnicode ? null : "text/plain; charset=shift_jis")
			.setPath(animationPath)
			.setResponseType('text')
			.setRequestHeader(requestHeader)
			.setWithCredentials(withCredentials)
			.load(url, function(text:String) {
				try {
					onLoad(parser.parseVpd(text, true));
				} catch(e:Dynamic) {
					if (onError != null) onError(e);
				}
			}, onProgress, onError);
	}

	private function _extractModelExtension(buffer:haxe.io.Bytes):String {
		var decoder = new haxe.io.BytesInput(buffer).readString(3);
		return decoder.toLowerCase();
	}

	private function _getParser():MMDParser.Parser {
		if (parser == null) {
			parser = new MMDParser.Parser();
		}
		return parser;
	}
}