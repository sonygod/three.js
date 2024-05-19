package three.js.examples.jsm.loaders;

import js.html.Image;
import js.Promise;

class GLTFTextureAVIFExtension {
    public var parser:Dynamic;
    public var name:String;
    public var isSupported:Promise<Bool>;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.EXT_TEXTURE_AVIF;
        this.isSupported = null;
    }

    public function loadTexture(textureIndex:Int):Promise<Dynamic> {
        var name:String = this.name;
        var parser:Dynamic = this.parser;
        var json:Dynamic = parser.json;

        var textureDef:Dynamic = json.textures[textureIndex];

        if (!textureDef.extensions || !textureDef.extensions[name]) {
            return Promise.resolve(null);
        }

        var extension:Dynamic = textureDef.extensions[name];
        var source:Dynamic = json.images[extension.source];

        var loader:Dynamic = parser.textureLoader;
        if (source.uri) {
            var handler:Dynamic = parser.options.manager.getHandler(source.uri);
            if (handler != null) loader = handler;
        }

        return detectSupport().then(function(isSupported:Bool) {
            if (isSupported) return parser.loadTextureImage(textureIndex, extension.source, loader);
            if (json.extensionsRequired && json.extensionsRequired.indexOf(name) >= 0) {
                throw new Error('THREE.GLTFLoader: AVIF required by asset but unsupported.');
            }
            // Fall back to PNG or JPEG.
            return parser.loadTexture(textureIndex);
        });
    }

    public function detectSupport():Promise<Bool> {
        if (this.isSupported == null) {
            this.isSupported = new Promise(function(resolve:Bool->Void) {
                var image:Image = new Image();

                // Lossy test image.
                image.src = 'data:image/avif;base64,AAAAIGZ0eXBhdmlmAAAAAGF2aWZtaWYxbWlhZk1BMUIAAADybWV0YQAAAAAAAAAoaGRscgAAAAAAAAAAcGljdAAAAAAAAAAAAAAAAGxpYmF2aWYAAAAADnBpdG0AAAAAAAEAAAAeaWxvYwAAAABEAAABAAEAAAABAAABGgAAABcAAAAoaWluZgAAAAAAAQAAABppbmZlAgAAAAABAABhdjAxQ29sb3IAAAAAamlwcnAAAABLaXBjbwAAABRpc3BlAAAAAAAAAAEAAAABAAAAEHBpeGkAAAAAAwgICAAAAAxhdjFDgQAMAAAAABNjb2xybmNseAACAAIABoAAAAAXaXBtYQAAAAAAAAABAAEEAQKDBAAAAB9tZGF0EgAKCBgABogQEDQgMgkQAAAAB8dSLfI=';
                image.onload = image.onerror = function() {
                    resolve(image.height === 1);
                };
            });
        }
        return this.isSupported;
    }
}