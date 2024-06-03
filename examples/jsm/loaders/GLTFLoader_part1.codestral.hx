import js.html.Loader;
import js.html.FileLoader;
import js.html.LoaderUtils;

class GLTFLoader extends Loader {
    var dracoLoader:Dynamic;
    var ktx2Loader:Dynamic;
    var meshoptDecoder:Dynamic;
    var pluginCallbacks:Array<Dynamic>;

    public function new(manager:Dynamic) {
        super(manager);

        dracoLoader = null;
        ktx2Loader = null;
        meshoptDecoder = null;
        pluginCallbacks = [];

        register(function(parser:Dynamic) {
            return new GLTFMaterialsClearcoatExtension(parser);
        });

        // Other register calls...

        register(function(parser:Dynamic) {
            return new GLTFMeshGpuInstancing(parser);
        });
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope:GLTFLoader = this;
        var resourcePath:String;

        if (resourcePath != '') {
            resourcePath = this.resourcePath;
        } else if (path != '') {
            var relativeUrl:String = LoaderUtils.extractUrlBase(url);
            resourcePath = LoaderUtils.resolveURL(relativeUrl, path);
        } else {
            resourcePath = LoaderUtils.extractUrlBase(url);
        }

        manager.itemStart(url);

        var _onError:Dynamic = function(e:Dynamic) {
            if (onError != null) {
                onError(e);
            } else {
                console.error(e);
            }
            scope.manager.itemError(url);
            scope.manager.itemEnd(url);
        };

        var loader:FileLoader = new FileLoader(manager);

        loader.setPath(path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(requestHeader);
        loader.setWithCredentials(withCredentials);

        loader.load(url, function(data:Dynamic) {
            try {
                scope.parse(data, resourcePath, function(gltf:Dynamic) {
                    onLoad(gltf);
                    scope.manager.itemEnd(url);
                }, _onError);
            } catch (e:Dynamic) {
                _onError(e);
            }
        }, onProgress, _onError);
    }

    public function setDRACOLoader(dracoLoader:Dynamic):GLTFLoader {
        this.dracoLoader = dracoLoader;
        return this;
    }

    public function setKTX2Loader(ktx2Loader:Dynamic):GLTFLoader {
        this.ktx2Loader = ktx2Loader;
        return this;
    }

    public function setMeshoptDecoder(meshoptDecoder:Dynamic):GLTFLoader {
        this.meshoptDecoder = meshoptDecoder;
        return this;
    }

    public function register(callback:Dynamic):GLTFLoader {
        if (pluginCallbacks.indexOf(callback) == -1) {
            pluginCallbacks.push(callback);
        }
        return this;
    }

    // Other methods...
}