import js.html.WebSocket;
import js.html.XMLHttpRequest;
import js.html.FormData;
import js.html.FileReader;
import js.html.File;
import js.html.Blob;
import js.html.URL;
import js.html.window;
import js.html.HTMLImageElement;

class GLTFParser {

    public var json: Dynamic;
    public var extensions: Map<String, Dynamic>;
    public var plugins: Map<String, Dynamic>;
    public var options: Dynamic;
    public var cache: GLTFRegistry;
    public var associations: Map<Dynamic, Dynamic>;
    public var primitiveCache: Map<String, Dynamic>;
    public var nodeCache: Map<Int, Dynamic>;
    public var meshCache: Dynamic;
    public var cameraCache: Dynamic;
    public var lightCache: Dynamic;
    public var sourceCache: Map<Int, Promise<Texture>>;
    public var textureCache: Map<String, Promise<Texture>>;
    public var nodeNamesUsed: Map<String, Int>;
    public var textureLoader: TextureLoader;
    public var fileLoader: FileLoader;

    public function new(json: Dynamic = {}, options: Dynamic = {}) {
        this.json = json;
        this.extensions = new Map<String, Dynamic>();
        this.plugins = new Map<String, Dynamic>();
        this.options = options;
        this.cache = new GLTFRegistry();
        this.associations = new Map<Dynamic, Dynamic>();
        this.primitiveCache = new Map<String, Dynamic>();
        this.nodeCache = new Map<Int, Dynamic>();
        this.meshCache = {refs: new Map<Int, Int>(), uses: new Map<Int, Int>()};
        this.cameraCache = {refs: new Map<Int, Int>(), uses: new Map<Int, Int>()};
        this.lightCache = {refs: new Map<Int, Int>(), uses: new Map<Int, Int>()};
        this.sourceCache = new Map<Int, Promise<Texture>>();
        this.textureCache = new Map<String, Promise<Texture>>();
        this.nodeNamesUsed = new Map<String, Int>();

        var isSafari = false;
        var isFirefox = false;
        var firefoxVersion = -1;

        if (js.Browser.document != null) {
            var userAgent = js.Browser.navigator.userAgent;
            isSafari = js.Boot.staticCall(RegExp, "test", ["^((?!chrome|android).)*safari/i", userAgent]) == true;
            isFirefox = userAgent.indexOf("Firefox") > -1;
            if (isFirefox) {
                var match = userAgent.match(/Firefox\/([0-9]+)\./);
                if (match != null && match.length > 1) {
                    firefoxVersion = Std.parseInt(match[1]);
                }
            }
        }

        if (js.Browser.window.createImageBitmap == null || isSafari || (isFirefox && firefoxVersion < 98)) {
            this.textureLoader = new TextureLoader(this.options.manager);
        } else {
            this.textureLoader = new ImageBitmapLoader(this.options.manager);
        }

        this.textureLoader.setCrossOrigin(this.options.crossOrigin);
        this.textureLoader.setRequestHeader(this.options.requestHeader);

        this.fileLoader = new FileLoader(this.options.manager);
        this.fileLoader.setResponseType("arraybuffer");

        if (this.options.crossOrigin == "use-credentials") {
            this.fileLoader.setWithCredentials(true);
        }
    }

    public function setExtensions(extensions: Map<String, Dynamic>): Void {
        this.extensions = extensions;
    }

    public function setPlugins(plugins: Map<String, Dynamic>): Void {
        this.plugins = plugins;
    }

    public async function parse(onLoad: (result: Dynamic) -> Void, onError: (error: Error) -> Void): Promise<Void> {
        var parser = this;
        var json = this.json;
        var extensions = this.extensions;

        this.cache.removeAll();
        this.nodeCache = new Map<Int, Dynamic>();

        this._invokeAll(function(ext: Dynamic): Dynamic {
            if (ext._markDefs != null) {
                return ext._markDefs();
            }
            return null;
        });

        var dependencies: Array<Dynamic> = [];
        try {
            await this._invokeAll(function(ext: Dynamic): Promise<Void> {
                if (ext.beforeRoot != null) {
                    return ext.beforeRoot();
                }
                return null;
            });

            dependencies = await Promise.all([
                parser.getDependencies("scene"),
                parser.getDependencies("animation"),
                parser.getDependencies("camera")
            ]);
        } catch (error) {
            onError(error);
            return;
        }

        var result = {
            scene: dependencies[0][json.scene || 0],
            scenes: dependencies[0],
            animations: dependencies[1],
            cameras: dependencies[2],
            asset: json.asset,
            parser: parser,
            userData: new Map<String, Dynamic>()
        };

        addUnknownExtensionsToUserData(extensions, result, json);
        assignExtrasToUserData(result, json);

        try {
            await this._invokeAll(function(ext: Dynamic): Promise<Void> {
                if (ext.afterRoot != null) {
                    return ext.afterRoot(result);
                }
                return null;
            });

            for (scene in result.scenes) {
                scene.updateMatrixWorld();
            }

            onLoad(result);
        } catch (error) {
            onError(error);
        }
    }

    // Rest of the class methods...
    // Please note that the rest of the class methods need to be converted to Haxe as well.
}