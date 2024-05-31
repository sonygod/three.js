import three.GLTFLoader;
import three.TextureLoader;
import three.Manager;
import js.lib.Promise;

class GLTFTextureAVIFExtension {

    public var parser:GLTFLoader;
    public var name:String;
    public var isSupported:Null<Promise<Bool>>;

    public function new(parser:GLTFLoader) {

        this.parser = parser;
        this.name = "EXT_TEXTURE_AVIF";
        this.isSupported = null;

    }

    public function loadTexture(textureIndex:Int):Null<Promise<Dynamic>> {

        final json = parser.json;

        final textureDef = json.textures[textureIndex];

        if (textureDef.extensions == null || !Reflect.hasField(textureDef.extensions, name)) {

            return null;

        }

        final extension = Reflect.field(textureDef.extensions, name);
        final source = json.images[extension.source];

        var loader:TextureLoader = parser.textureLoader;
        if (source.uri != null) {

            final handler = parser.options.manager.getHandler(source.uri);
            if (handler != null) loader = handler;

        }

        return detectSupport().then(function(isSupported) {

            if (isSupported) return parser.loadTextureImage(textureIndex, extension.source, loader);

            if (json.extensionsRequired != null && json.extensionsRequired.indexOf(name) >= 0) {

                throw new Error("THREE.GLTFLoader: AVIF required by asset but unsupported.");

            }

            // Fall back to PNG or JPEG.
            return parser.loadTexture(textureIndex);

        });

    }

    public function detectSupport():Promise<Bool> {

        if (this.isSupported == null) {

            this.isSupported = new Promise(function(resolve, reject) {

                var image = new js.html.Image();

                // Lossy test image.
                image.src = "data:image/avif;base64,AAAAIGZ0eXBhdmlmAAAAAGF2aWZtaWYxbWlhZk1BMUIAAADybWV0YQAAAAAAAAAoaGRscgAAAAAAAAAAcGljdAAAAAAAAAAAAAAAAGxpYmF2aWYAAAAADnBpdG0AAAAAAAEAAAAeaWxvYwAAAABEAAABAAEAAAABAAABGgAAABcAAAAoaWluZgAAAAAAAQAAABppbmZlAgAAAAABAABhdjAxQ29sb3IAAAAAamlwcnAAAABLaXBjbwAAABRpc3BlAAAAAAAAAAEAAAABAAAAEHBpeGkAAAAAAwgICAAAAAxhdjFDgQAMAAAAABNjb2xybmNseAACAAIABoAAAAAXaXBtYQAAAAAAAAABAAEEAQKDBAAAAB9tZGF0EgAKCBgABogQEDQgMgkQAAAAB8dSLfI=";
                image.onload = function(_) resolve(image.height == 1);
                image.onerror = function(_) resolve(false);

            });

        }

        return this.isSupported;

    }

}