class GLTFLoader extends Loader {

	var dracoLoader:Null<Loader>;
	var ktx2Loader:Null<Loader>;
	var meshoptDecoder:Null<Loader>;
	var pluginCallbacks:Array<Dynamic->GLTFParser>;

	public function new(manager:Loader) {
		super(manager);
		dracoLoader = null;
		ktx2Loader = null;
		meshoptDecoder = null;
		pluginCallbacks = [];
		register(function(parser:GLTFParser) return new GLTFMaterialsClearcoatExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMaterialsDispersionExtension(parser));
		register(function(parser:GLTFParser) return new GLTFTextureBasisUExtension(parser));
		register(function(parser:GLTFParser) return new GLTFTextureWebPExtension(parser));
		register(function(parser:GLTFParser) return new GLTFTextureAVIFExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMaterialsSheenExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMaterialsTransmissionExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMaterialsVolumeExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMaterialsIorExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMaterialsEmissiveStrengthExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMaterialsSpecularExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMaterialsIridescenceExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMaterialsAnisotropyExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMaterialsBumpExtension(parser));
		register(function(parser:GLTFParser) return new GLTFLightsExtension(parser));
		register(function(parser:GLTFParser) return new GLTFMeshoptCompression(parser));
		register(function(parser:GLTFParser) return new GLTFMeshGpuInstancing(parser));
	}

	public function load(url:String, onLoad:GLTF->Void, onProgress:LoaderProgress->Void, onError:Error->Void) {
		var scope = this;
		var resourcePath:String;
		if (this.resourcePath != "") {
			resourcePath = this.resourcePath;
		} else if (this.path != "") {
			var relativeUrl = LoaderUtils.extractUrlBase(url);
			resourcePath = LoaderUtils.resolveURL(relativeUrl, this.path);
		} else {
			resourcePath = LoaderUtils.extractUrlBase(url);
		}
		this.manager.itemStart(url);
		var _onError = function(e:Error) {
			if (onError != null) {
				onError(e);
			} else {
				trace(e);
			}
			scope.manager.itemError(url);
			scope.manager.itemEnd(url);
		};
		var loader = new FileLoader(this.manager);
		loader.setPath(this.path);
		loader.setResponseType("arraybuffer");
		loader.setRequestHeader(this.requestHeader);
		loader.setWithCredentials(this.withCredentials);
		loader.load(url, function(data:ArrayBuffer) {
			try {
				scope.parse(data, resourcePath, function(gltf:GLTF) {
					onLoad(gltf);
					scope.manager.itemEnd(url);
				}, _onError);
			} catch (e:Dynamic) {
				_onError(e);
			}
		}, onProgress, _onError);
	}

	public function setDRACOLoader(dracoLoader:Loader) {
		this.dracoLoader = dracoLoader;
		return this;
	}

	public function setDDSLoader() {
		throw "THREE.GLTFLoader: \"MSFT_texture_dds\" no longer supported. Please update to \"KHR_texture_basisu\".";
	}

	public function setKTX2Loader(ktx2Loader:Loader) {
		this.ktx2Loader = ktx2Loader;
		return this;
	}

	public function setMeshoptDecoder(meshoptDecoder:Loader) {
		this.meshoptDecoder = meshoptDecoder;
		return this;
	}

	public function register(callback:GLTFParser->GLTFExtension) {
		if (this.pluginCallbacks.indexOf(callback) == -1) {
			this.pluginCallbacks.push(callback);
		}
		return this;
	}

	public function unregister(callback:GLTFParser->GLTFExtension) {
		var index = this.pluginCallbacks.indexOf(callback);
		if (index != -1) {
			this.pluginCallbacks.splice(index, 1);
		}
		return this;
	}

	public function parse(data:Dynamic, path:String, onLoad:GLTF->Void, onError:Error->Void) {
		var json:Dynamic;
		var extensions:Map<String, GLTFExtension> = {};
		var plugins:Map<String, GLTFExtension> = {};
		var textDecoder = new TextDecoder();
		if (Std.is(data, String)) {
			json = haxe.Json.parse(data);
		} else if (data instanceof ArrayBuffer) {
			var magic = textDecoder.decode(new Uint8Array(data, 0, 4));
			if (magic == BINARY_EXTENSION_HEADER_MAGIC) {
				try {
					extensions[EXTENSIONS.KHR_BINARY_GLTF] = new GLTFBinaryExtension(data);
				} catch (error:Dynamic) {
					if (onError != null) onError(error);
					return;
				}
				json = haxe.Json.parse(extensions[EXTENSIONS.KHR_BINARY_GLTF].content);
			} else {
				json = haxe.Json.parse(textDecoder.decode(data));
			}
		} else {
			json = data;
		}
		if (json.asset == null || json.asset.version[0] < 2) {
			if (onError != null) onError(new Error("THREE.GLTFLoader: Unsupported asset. glTF versions >=2.0 are supported."));
			return;
		}
		var parser = new GLTFParser(json, {
			path: path != "" ? path : this.resourcePath != "" ? this.resourcePath : "",
			crossOrigin: this.crossOrigin,
			requestHeader: this.requestHeader,
			manager: this.manager,
			ktx2Loader: this.ktx2Loader,
			meshoptDecoder: this.meshoptDecoder
		});
		parser.fileLoader.setRequestHeader(this.requestHeader);
		for (i in this.pluginCallbacks) {
			var plugin = this.pluginCallbacks[i](parser);
			if (plugin.name == null) trace("THREE.GLTFLoader: Invalid plugin found: missing name");
			plugins[plugin.name] = plugin;
			extensions[plugin.name] = true;
		}
		if (json.extensionsUsed != null) {
			for (i in json.extensionsUsed) {
				var extensionName = json.extensionsUsed[i];
				var extensionsRequired = json.extensionsRequired || [];
				switch (extensionName) {
					case EXTENSIONS.KHR_MATERIALS_UNLIT:
						extensions[extensionName] = new GLTFMaterialsUnlitExtension();
						break;
					case EXTENSIONS.KHR_DRACO_MESH_COMPRESSION:
						extensions[extensionName] = new GLTFDracoMeshCompressionExtension(json, this.dracoLoader);
						break;
					case EXTENSIONS.KHR_TEXTURE_TRANSFORM:
						extensions[extensionName] = new GLTFTextureTransformExtension();
						break;
					case EXTENSIONS.KHR_MESH_QUANTIZATION:
						extensions[extensionName] = new GLTFMeshQuantizationExtension();
						break;
					default:
						if (extensionsRequired.indexOf(extensionName) >= 0 && plugins[extensionName] == null) {
							trace("THREE.GLTFLoader: Unknown extension \"" + extensionName + "\".");
						}
				}
			}
		}
		parser.setExtensions(extensions);
		parser.setPlugins(plugins);
		parser.parse(onLoad, onError);
	}

	public function parseAsync(data:Dynamic, path:String):Promise<GLTF> {
		var scope = this;
		return new Promise(function(resolve, reject) {
			scope.parse(data, path, resolve, reject);
		});
	}

}