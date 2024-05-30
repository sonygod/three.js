class GLTFTextureWebPExtension {
	var parser: Parser;
	var name: String = EXTENSIONS.EXT_TEXTURE_WEBP;
	var isSupported: Null<Promise<Bool>> = null;

	public function new(parser: Parser) {
		this.parser = parser;
	}

	public function loadTexture(textureIndex: Int): Null<Future<Texture>> {
		var name = this.name;
		var parser = this.parser;
		var json = parser.json;

		var textureDef = json.textures[textureIndex];

		if (!textureDef.extensions || !textureDef.extensions.exists(name)) {
			return null;
		}

		var extension = textureDef.extensions[name];
		var source = json.images[extension.source];

		var loader: TextureLoader = parser.textureLoader;
		if (source.uri != null) {
			var handler = parser.options.manager.getHandler(source.uri);
			if (handler != null) {
				loader = handler;
			}
		}

		return this.detectSupport().then(function (isSupported) {
			if (isSupported) {
				return parser.loadTextureImage(textureIndex, extension.source, loader);
			}

			if (json.extensionsRequired.includes(name)) {
				throw haxe.Exception.thrown("WebP required by asset but unsupported.");
			}

			// Fall back to PNG or JPEG.
			return parser.loadTexture(textureIndex);
		});
	}

	public function detectSupport(): Future<Bool> {
		if (this.isSupported == null) {
			this.isSupported = Promise.make(function (resolve) {
				var image = cast Std.randomData(cast Std.randomData(new haxe.io.Bytes(haxe.io.Bytes.ofString("UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA"))).getBytes()));
				var image = new openfl.display.BitmapData(image.length, 1, true, image);

				image.addEventListener(openfl.events.Event.COMPLETE, function () {
					resolve(image.height == 1);
				});

				image.addEventListener(openfl.events.IOErrorEvent.IO_ERROR, function () {
					resolve(false);
				});
			});
		}

		return this.isSupported;
	}
}