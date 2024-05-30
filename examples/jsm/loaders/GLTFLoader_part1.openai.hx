package three.js.examples.jsm.loaders;

import three.js.loaders.Loader;

class GLTFLoader extends Loader {
    var dracoLoader:Dynamic;
    var ktx2Loader:Dynamic;
    var meshoptDecoder:Dynamic;
    var pluginCallbacks:Array<GLTFParser->Void>;

    public function new(manager:Loader) {
        super(manager);
        dracoLoader = null;
        ktx2Loader = null;
        meshoptDecoder = null;
        pluginCallbacks = [];

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsClearcoatExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsDispersionExtension(parser);
        });

        // ... (register all other extensions)

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsBumpExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFLightsExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMeshoptCompression(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMeshGpuInstancing(parser);
        });
    }

    public function load(url:String, onLoad:GLTF->Void, onProgress:Float->Void, onError:String->Void) {
        var scope:GLTFLoader = this;
        var resourcePath:String;

        if (resourcePath != "") {
            resourcePath = resourcePath;
        } else if (path != "") {
            var relativeUrl:String = LoaderUtils.extractUrlBase(url);
            resourcePath = LoaderUtils.resolveURL(relativeUrl, path);
        } else {
            resourcePath = LoaderUtils.extractUrlBase(url);
        }

        manager.itemStart(url);

        var _onError:String->Void = function(e:String) {
            if (onError != null) {
                onError(e);
            } else {
                console.error(e);
            }
            manager.itemError(url);
            manager.itemEnd(url);
        };

        var loader:FileLoader = new FileLoader(manager);
        loader.setPath(path);
        loader.setResponseType("arraybuffer");
        loader.setRequestHeader(requestHeader);
        loader.setWithCredentials(withCredentials);

        loader.load(url, function(data:ArrayBuffer) {
            try {
                parse(data, resourcePath, function(gltf:GLTF) {
                    onLoad(gltf);
                    manager.itemEnd(url);
                }, _onError);
            } catch (e:Dynamic) {
                _onError(e);
            }
        }, onProgress, _onError);
    }

    public function setDRACOLoader(dracoLoader:Dynamic) {
        this.dracoLoader = dracoLoader;
        return this;
    }

    public function setDDSLoader() {
        throw new Error("THREE.GLTFLoader: \"MSFT_texture_dds\" no longer supported. Please update to \"KHR_texture_basisu\".");
    }

    public function setKTX2Loader(ktx2Loader:Dynamic) {
        this.ktx2Loader = ktx2Loader;
        return this;
    }

    public function setMeshoptDecoder(meshoptDecoder:Dynamic) {
        this.meshoptDecoder = meshoptDecoder;
        return this;
    }

    public function register(callback:GLTFParser->Void) {
        if (pluginCallbacks.indexOf(callback) == -1) {
            pluginCallbacks.push(callback);
        }
        return this;
    }

    public function unregister(callback:GLTFParser->Void) {
        if (pluginCallbacks.indexOf(callback) != -1) {
            pluginCallbacks.splice(pluginCallbacks.indexOf(callback), 1);
        }
        return this;
    }

    public function parse(data:Dynamic, path:String, onLoad:GLTF->Void, onError:String->Void) {
        // ... (parse function implementation)
    }

    public function parseAsync(data:Dynamic, path:String) {
        var scope:GLTFLoader = this;
        return new Promise(GLTF->Void, function(resolve:GLTF->Void, reject:String->Void) {
            scope.parse(data, path, resolve, reject);
        });
    }
}