package three.js.examples.jwm.loaders;

import js.Lib;
import js.Promise;
import js.html.Image;

class GLTFTextureWebPExtension {
    public var parser:Dynamic;
    public var name:String;
    public var isSupported:Null<Promise<Bool>>;

    public function new(parser:Dynamic) {
        this.parser = parser;
        this.name = EXTENSIONS.EXT_TEXTURE_WEBP;
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
        if (source.uri != null) {
            var handler:Dynamic = parser.options.manager.getHandler(source.uri);
            if (handler != null) loader = handler;
        }

        return this.detectSupport().then(function(isSupported:Bool) {
            if (isSupported) return parser.loadTextureImage(textureIndex, extension.source, loader);

            if (json.extensionsRequired != null && json.extensionsRequired.indexOf(name) >= 0) {
                throw new Error('THREE.GLTFLoader: WebP required by asset but unsupported.');
            }

            // Fall back to PNG or JPEG.
            return parser.loadTexture(textureIndex);
        });
    }

    public function detectSupport():Promise<Bool> {
        if (this.isSupported == null) {
            this.isSupported = new Promise(function(resolve:Bool->Void) {
                var image:Image = new Image();

                // Lossy test image. Support for lossy images doesn't guarantee support for all
                // WebP images, unfortunately.
                image.src = 'data:image/webp;base64,UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA';

                image.onload = image.onerror = function() {
                    resolve(image.height == 1);
                };
            });
        }

        return this.isSupported;
    }
}