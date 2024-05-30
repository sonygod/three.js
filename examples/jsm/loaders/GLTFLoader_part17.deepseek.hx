class GLTFTextureAVIFExtension {

	var parser:Dynamic;
	var name:String;
	var isSupported:Null<Promise<Bool>>;

	public function new(parser:Dynamic) {
		this.parser = parser;
		this.name = EXTENSIONS.EXT_TEXTURE_AVIF;
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
				throw 'THREE.GLTFLoader: AVIF required by asset but unsupported.';
			}
			return this.parser.loadTexture(textureIndex);
		});
	}

	public function detectSupport():Promise<Bool> {
		if (!this.isSupported) {
			this.isSupported = new Promise(function (resolve) {
				var image = new js.html.Image();
				image.src = 'data:image/avif;base64,AAAAIGZ0eXBhdmlmAAAAAGF2aWZtaWYxbWlhZk1BMUIAAADybWV0YQAAAAAAAAAoaGRscgAAAAAAAAAAcGljdAAAAAAAAAAAAAAAAGxpYmF2aWYAAAAADnBpdG0AAAAAAAEAAAAeaWxvYwAAAABEAAABAAEAAAABAAABGgAAABcAAAAoaWluZgAAAAAAAQAAABppbmZlAgAAAAABAABhdjAxQ29sb3IAAAAAamlwcnAAAABLaXBjbwAAABRpc3BlAAAAAAAAAAEAAAABAAAAEHBpeGkAAAAAAwgICAAAAAxhdjFDgQAMAAAAABNjb2xybmNseAACAAIABoAAAAAXaXBtYQAAAAAAAAABAAEEAQKDBAAAAB9tZGF0EgAKCBgABogQEDQgMgkQAAAAB8dSLfI=';
				image.onload = image.onerror = function () {
					resolve(image.height === 1);
				};
			});
		}
		return this.isSupported;
	}
}