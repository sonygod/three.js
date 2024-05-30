package three.js.loaders;

import js.html.Image;
import js.Promise;

class GLTFTextureAVIFExtension {
    public var parser:GLTFParser;
    public var name:String;
    public var isSupported:Null<Promise<Bool>>;

    public function new(parser:GLTFParser) {
        this.parser = parser;
        this.name = EXTENSIONS.EXT_TEXTURE_AVIF;
        this.isSupported = null;
    }

    public function loadTexture(textureIndex:Int):Promise<Texture> {
        var name = this.name;
        var parser = this.parser;
        var json = parser.json;

        var textureDef = json.textures[textureIndex];

        if (!textureDef.extensions || !textureDef.extensions[name]) {
            return Promise.promise(null);
        }

        var extension = textureDef.extensions[name];
        var source = json.images[extension.source];

        var loader = parser.textureLoader;
        if (source.uri != null) {
            var handler = parser.options.manager.getHandler(source.uri);
            if (handler != null) loader = handler;
        }

        return detectSupport().then(function(isSupported:Bool) {
            if (isSupported) {
                return parser.loadTextureImage(textureIndex, extension.source, loader);
            }

            if (json.extensionsRequired && json.extensionsRequired.indexOf(name) >= 0) {
                throw new Error('THREE.GLTFLoader: AVIF required by asset but unsupported.');
            }

            // Fall back to PNG or JPEG.
            return parser.loadTexture(textureIndex);
        });
    }

    private function detectSupport():Promise<Bool> {
        if (this.isSupported == null) {
            this.isSupported = new Promise(function(resolve:Bool->Void) {
                var image = new Image();

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