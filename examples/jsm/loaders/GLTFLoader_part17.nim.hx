class GLTFTextureAVIFExtension {

	var parser:GLTFLoader;
	var name:String;
	var isSupported:Dynamic;

	public function new(parser:GLTFLoader) {

		this.parser = parser;
		this.name = EXTENSIONS.EXT_TEXTURE_AVIF;
		this.isSupported = null;

	}

	public function loadTexture(textureIndex:Int):Future<Dynamic> {

		var name:String = this.name;
		var parser:GLTFLoader = this.parser;
		var json:Dynamic = parser.json;

		var textureDef:Dynamic = json.textures[textureIndex];

		if (!Std.is(textureDef.extensions, Dynamic) || !Std.is(textureDef.extensions[name], Dynamic)) {

			return null;

		}

		var extension:Dynamic = textureDef.extensions[name];
		var source:Dynamic = json.images[extension.source];

		var loader:Dynamic = parser.textureLoader;
		if (Std.is(source.uri, String)) {

			var handler:Dynamic = parser.options.manager.getHandler(source.uri);
			if (handler != null) loader = handler;

		}

		return this.detectSupport().then(function(isSupported:Bool) {

			if (isSupported) return parser.loadTextureImage(textureIndex, extension.source, loader);

			if (Std.is(json.extensionsRequired, Array<String>) && json.extensionsRequired.indexOf(name) >= 0) {

				throw new HaxeException("THREE.GLTFLoader: AVIF required by asset but unsupported.");

			}

			// Fall back to PNG or JPEG.
			return parser.loadTexture(textureIndex);

		});

	}

	public function detectSupport():Future<Bool> {

		if (this.isSupported == null) {

			this.isSupported = new Future<Bool>(function(resolve:Dynamic) {

				var image:js.html.Image = js.Browser.document.createElement("img");

				// Lossy test image.
				image.src = 'data:image/avif;base64,AAAAIGZ0eXBhdmlmAAAAAGF2aWZtaWYxbWlhZk1BMUIAAADybWV0YQAAAAAAAAAoaGRscgAAAAAAAAAAcGljdAAAAAAAAAAAAAAAAGxpYmF2aWYAAAAADnBpdG0AAAAAAAEAAAAeaWxvYwAAAABEAAABAAEAAAABAAABGgAAABcAAAAoaWluZgAAAAAAAQAAABppbmZlAgAAAAABAABhdjAxQ29sb3IAAAAAamlwcnAAAABLaXBjbwAAABRpc3BlAAAAAAAAAAEAAAABAAAAEHBpeGkAAAAAAwgICAAAAAxhdjFDgQAMAAAAABNjb2xybmNseAACAAIABoAAAAAXaXBtYQAAAAAAAAABAAEEAQKDBAAAAB9tZGF0EgAKCBgABogQEDQgMgkQAAAAB8dSLfI=';
				image.onload = image.onerror = function() {

					resolve(image.height == 1);

				};

			});

		}

		return this.isSupported;

	}

}