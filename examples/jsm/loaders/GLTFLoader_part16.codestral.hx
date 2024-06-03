class GLTFTextureWebPExtension {

    private var parser: GLTFParser;
    public var name: String = EXTENSIONS.EXT_TEXTURE_WEBP;
    public var isSupported: Promise<Bool> = null;

    public function new(parser: GLTFParser) {
        this.parser = parser;
    }

    public function loadTexture(textureIndex: Int): Promise<Texture> {
        var json = this.parser.json;
        var textureDef = json.textures[textureIndex];

        if (textureDef.extensions == null || textureDef.extensions[this.name] == null) {
            return new Promise<Texture>(resolve => resolve(null));
        }

        var extension = textureDef.extensions[this.name];
        var source = json.images[extension.source];

        var loader = this.parser.textureLoader;
        if (source.uri != null) {
            var handler = this.parser.options.manager.getHandler(source.uri);
            if (handler != null) loader = handler;
        }

        return this.detectSupport().then(function (isSupported) {
            if (isSupported) return this.parser.loadTextureImage(textureIndex, extension.source, loader);

            if (json.extensionsRequired != null && json.extensionsRequired.indexOf(this.name) >= 0) {
                throw new Error('THREE.GLTFLoader: WebP required by asset but unsupported.');
            }

            // Fall back to PNG or JPEG.
            return this.parser.loadTexture(textureIndex);
        }.bind(this));
    }

    public function detectSupport(): Promise<Bool> {
        if (this.isSupported == null) {
            this.isSupported = new Promise<Bool>(function (resolve) {
                var image = new js.html.Image();
                image.src = 'data:image/webp;base64,UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA';
                image.onload = image.onerror = function () {
                    resolve(image.height == 1);
                };
            });
        }
        return this.isSupported;
    }
}