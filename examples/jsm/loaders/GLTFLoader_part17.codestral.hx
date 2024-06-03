import js.Promise;
import js.Image;
import js.html.ImageElement;

class GLTFTextureAVIFExtension {
    public var parser: dynamic;
    public var name: String;
    public var isSupported: Promise<Bool> = null;

    public function new(parser: dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.EXT_TEXTURE_AVIF;
    }

    public function loadTexture(textureIndex: Int): Promise<dynamic> {
        var name = this.name;
        var parser = this.parser;
        var json = parser.json;
        var textureDef = json.textures[textureIndex];

        if (textureDef.extensions == null || textureDef.extensions[name] == null) {
            return null;
        }

        var extension = textureDef.extensions[name];
        var source = json.images[extension.source];
        var loader = parser.textureLoader;

        if (source.uri != null) {
            var handler = parser.options.manager.getHandler(source.uri);
            if (handler != null) loader = handler;
        }

        return this.detectSupport().then(function(isSupported: Bool): dynamic {
            if (isSupported) {
                return parser.loadTextureImage(textureIndex, extension.source, loader);
            }

            if (json.extensionsRequired != null && json.extensionsRequired.indexOf(name) >= 0) {
                throw "THREE.GLTFLoader: AVIF required by asset but unsupported.";
            }

            return parser.loadTexture(textureIndex);
        });
    }

    public function detectSupport(): Promise<Bool> {
        if (this.isSupported == null) {
            this.isSupported = new Promise<Bool>(function(resolve: (Bool -> Void), reject: (Dynamic -> Void)): Void {
                var image: ImageElement = js.html.Image();

                image.onload = image.onerror = function(_: Event): Void {
                    resolve(image.height == 1);
                };

                image.src = "data:image/avif;base64,AAAAIGZ0eXBhdmlmAAAAAGF2aWZtaWYxbWlhZk1BMUIAAADybWV0YQAAAAAAAAAoaGRscgAAAAAAAAAAcGljdAAAAAAAAAAAAAAAAGxpYmF2aWYAAAAADnBpdG0AAAAAAAEAAAAeaWxvYwAAAABEAAABAAEAAAABAAABGgAAABcAAAAoaWluZgAAAAAAAQAAABppbmZlAgAAAAABAABhdjAxQ29sb3IAAAAAamlwcnAAAABLaXBjbwAAABRpc3BlAAAAAAAAAAEAAAABAAAAEHBpeGkAAAAAAwgICAAAAAxhdjFDgQAMAAAAABNjb2xybmNseAACAAIABoAAAAAXaXBtYQAAAAAAAAABAAEEAQKDBAAAAB9tZGF0EgAKCBgABogQEDQgMgkQAAAAB8dSLfI=";
            });
        }

        return this.isSupported;
    }
}