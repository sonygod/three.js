class GLTFTextureAVIFExtension {
    public var parser:GLTFParser;
    public var name:String;
    public var isSupported:Null<Promise<Bool>>;

    public function new(parser:GLTFParser) {
        this.parser = parser;
        this.name = EXTENSIONS.EXT_TEXTURE_AVIF;
        this.isSupported = null;
    }

    public function loadTexture(textureIndex:Int):Future<Null<Texture>> {
        var name = this.name;
        var parser = this.parser;
        var json = parser.json;

        var textureDef = json.textures[textureIndex];

        if (!textureDef.extensions || !textureDef.extensions.exists(name)) {
            return Promise.async(null);
        }

        var extension = textureDef.extensions[name];
        var source = json.images[extension.source];

        var loader = parser.textureLoader;
        if (source.uri != null) {
            var handler = parser.options.manager.getHandler(source.uri);
            if (handler != null) {
                loader = handler;
            }
        }

        return this.detectSupport().then(function(isSupported) {
            if (isSupported) {
                return parser.loadTextureImage(textureIndex, extension.source, loader);
            }

            if (json.extensionsRequired.exists(name)) {
                throw "THREE.GLTFLoader: AVIF required by asset but unsupported.";
            }

            // Fall back to PNG or JPEG.
            return parser.loadTexture(textureIndex);
        });
    }

    public function detectSupport():Future<Bool> {
        if (this.isSupported == null) {
            this.isSupported = Promise.async(function(complete, error) {
                var image = cast Image(Std.create("Image"));
                image.src = "data:image/avif;base64,AAAAIGZ0eXBhdmlmAAAAAGF2aWZtaWYxbWlhZk1BMUIAAADybWV0YQAAAAAAAAAoaGRscgAAAAAAAAAAcGljdAAAAAAAAAAAAAAAAGxpYmF2aWYAAAAADnBpdG0AAAAAAAEAAAAeaWxvYwAAAABEAAABAAEAAAABAAABGgAAABcAAAAoaWluZgAAAAAAAQAAABppbmZlAgAAAAABAABhdjAxQ29sb3IAAAAAamlwcnAAAABLaXBjbwAAABRpc3BlAAAAAAAAAAEAAAABAAAAEHBpeGkAAAAAAwgICAAAAAxhdjFDgQAMAAAAABNjb2xybmNseAACAAIABoAAAAAXaXBtYQAAAAAAAAABAAEEAQKDBAAAAB9tZGF0EgAKCBgABogQEDQgMgkQAAAAB8dSLfI=";

                image.onload = function() {
                    complete(image.height == 1);
                };

                image.onerror = function() {
                    error("Failed to load test image");
                };
            });
        }

        return this.isSupported;
    }
}