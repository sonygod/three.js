class GLTFTextureWebPExtension {

	var parser:Dynamic;
	var name:String;
	var isSupported:Null<Promise<Bool>>;

	public function new(parser:Dynamic) {
		this.parser = parser;
		this.name = EXTENSIONS.EXT_TEXTURE_WEBP;
		this.isSupported = null;
	}

	public function loadTexture(textureIndex:Int):Promise<Dynamic> {
		var textureDef = this.parser.json.textures[textureIndex];
		if (!(textureDef.extensions && textureDef.extensions[this.name])) {
			return null;
		}
		var extension = textureDef.extensions[this.name];
		var source = this.parser.json.images[extension.source];
		var loader = this.parser.textureLoader;
		if (source.uri) {
			var handler = this.parser.options.manager.getHandler(source.uri);
			if (handler !== null) loader = handler;
		}
		return this.detectSupport().then(function (isSupported) {
			if (isSupported) return this.parser.loadTextureImage(textureIndex, extension.source, loader);
			if (this.parser.json.extensionsRequired && this.parser.json.extensionsRequired.indexOf(this.name) >= 0) {
				throw 'THREE.GLTFLoader: WebP required by asset but unsupported.';
			}
			return this.parser.loadTexture(textureIndex);
		});
	}

	public function detectSupport():Promise<Bool> {
		if (!this.isSupported) {
			this.isSupported = new Promise(function (resolve) {
				var image = new js.html.Image();
				image.src = 'data:image/webp;base64,UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA';
				image.onload = image.onerror = function () {
					resolve(image.height == 1);
				};
			});
		}
		return this.isSupported;
	}
}