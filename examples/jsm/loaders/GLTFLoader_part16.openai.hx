import js.html.Image;
import js.Promise;

class GLTFTextureWebPExtension {
    public var parser:GLTFParser;
    public var name:String;
    public var isSupported:Null<Promise<Bool>>;

    public function new(parser:GLTFParser) {
        this.parser = parser;
        this.name = EXTENSIONS.EXT_TEXTURE_WEBP;
        this.isSupported = null;
    }

    public function loadTexture(textureIndex:Int):Promise<Texture> {
        var name = this.name;
        var parser = this.parser;
        var json = parser.json;

        var textureDef = json.textures[textureIndex];

        if (!textureDef.extensions || !textureDef.extensions.exists(name)) {
            return Promise.resolve(null);
        }

        var extension = textureDef.extensions[name];
        var source = json.images[extension.source];

        var loader = parser.textureLoader;
        if (source.uri != null) {
            var handler = parser.options.manager.getHandler(source.uri);
            if (handler != null) loader = handler;
        }

        return detectSupport().then(function(isSupported:Bool) {
            if (isSupported) return parser.loadTextureImage(textureIndex, extension.source, loader);

            if (json.extensionsRequired && json.extensionsRequired.indexOf(name) >= 0) {
                throw new Error('THREE.GLTFLoader: WebP required by asset but unsupported.');
            }

            // Fall back to PNG or JPEG.
            return parser.loadTexture(textureIndex);
        });
    }

    public function detectSupport():Promise<Bool> {
        if (isSupported == null) {
            isSupported = new Promise(function(resolve:Bool->Void) {
                var image = new Image();

                // Lossy test image. Support for lossy images doesn't guarantee support for all
                // WebP images, unfortunately.
                image.src = 'data:image/webp;base64,UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA';

                image.onload = image.onerror = function() {
                    resolve(image.height == 1);
                };
            });
        }

        return isSupported;
    }
}