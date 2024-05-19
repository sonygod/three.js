package three.js.examples.jsm.loaders;

import haxe.Json;
import haxe.io.Bytes;
import haxe.io.TextDecoder;

class GLTFLoader extends Loader {
    var dracoLoader:Null<Dynamic>;
    var ktx2Loader:Null<Dynamic>;
    var meshoptDecoder:Null<Dynamic>;
    var pluginCallbacks:Array<Dynamic>;

    public function new(manager:Loader) {
        super(manager);
        dracoLoader = null;
        ktx2Loader = null;
        meshoptDecoder = null;
        pluginCallbacks = [];

        register(function(parser:Dynamic) {
            return new GLTFMaterialsClearcoatExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMaterialsDispersionExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFTextureBasisUExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFTextureWebPExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFTextureAVIFExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMaterialsSheenExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMaterialsTransmissionExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMaterialsVolumeExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMaterialsIorExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMaterialsEmissiveStrengthExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMaterialsSpecularExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMaterialsIridescenceExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMaterialsAnisotropyExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMaterialsBumpExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFLightsExtension(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMeshoptCompression(parser);
        });

        register(function(parser:Dynamic) {
            return new GLTFMeshGpuInstancing(parser);
        });
    }

    public function load(url:String, onLoad:GLTF->Void, onProgress:Float->Void, onError:Dynamic->Void) {
        var scope:GLTFLoader = this;
        var resourcePath:String;
        if (resourcePath != '') {
            resourcePath = resourcePath;
        } else if (path != '') {
            var relativeUrl:String = LoaderUtils.extractUrlBase(url);
            resourcePath = LoaderUtils.resolveURL(relativeUrl, path);
        } else {
            resourcePath = LoaderUtils.extractUrlBase(url);
        }

        manager.itemStart(url);

        var _onError:Dynamic->Void = function(e:Dynamic) {
            if (onError != null) {
                onError(e);
            } else {
                Console.error(e);
            }
            scope.manager.itemError(url);
            scope.manager.itemEnd(url);
        };

        var loader:FileLoader = new FileLoader(manager);
        loader.setPath(path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(requestHeader);
        loader.setWithCredentials(withCredentials);

        loader.load(url, function(data:Bytes) {
            try {
                scope.parse(data, resourcePath, function(gltf:GLTF) {
                    onLoad(gltf);
                    scope.manager.itemEnd(url);
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
        throw new Error('THREE.GLTFLoader: "MSFT_texture_dds" no longer supported. Please update to "KHR_texture_basisu".');
    }

    public function setKTX2Loader(ktx2Loader:Dynamic) {
        this.ktx2Loader = ktx2Loader;
        return this;
    }

    public function setMeshoptDecoder(meshoptDecoder:Dynamic) {
        this.meshoptDecoder = meshoptDecoder;
        return this;
    }

    public function register(callback:Dynamic->Void) {
        if (pluginCallbacks.indexOf(callback) == -1) {
            pluginCallbacks.push(callback);
        }
        return this;
    }

    public function unregister(callback:Dynamic->Void) {
        var index:Int = pluginCallbacks.indexOf(callback);
        if (index != -1) {
            pluginCallbacks.splice(index, 1);
        }
        return this;
    }

    public function parse(data:Dynamic, path:String, onLoad:GLTF->Void, onError:Dynamic->Void) {
        var json:Dynamic;
        var extensions:Dynamic = {};
        var plugins:Dynamic = {};
        var textDecoder:TextDecoder = new TextDecoder();

        if (Std.isOfType(data, String)) {
            json = Json.parse(data);
        } else if (Std.isOfType(data, Bytes)) {
            var magic:String = textDecoder.decode(new Uint8Array(data, 0, 4));
            if (magic == BINARY_EXTENSION_HEADER_MAGIC) {
                try {
                    extensions[EXTENSIONS.KHR_BINARY_GLTF] = new GLTFBinaryExtension(data);
                } catch (error:Dynamic) {
                    if (onError != null) onError(error);
                    return;
                }
                json = Json.parse(extensions[EXTENSIONS.KHR_BINARY_GLTF].content);
            } else {
                json = Json.parse(textDecoder.decode(data));
            }
        } else {
            json = data;
        }

        if (json.asset == null || json.asset.version[0] < 2) {
            if (onError != null) onError(new Error('THREE.GLTFLoader: Unsupported asset. glTF versions >=2.0 are supported.'));
            return;
        }

        var parser:GLTFParser = new GLTFParser(json, {
            path: path != null ? path : resourcePath,
            crossOrigin: crossOrigin,
            requestHeader: requestHeader,
            manager: manager,
            ktx2Loader: ktx2Loader,
            meshoptDecoder: meshoptDecoder
        });

        parser.fileLoader.setRequestHeader(requestHeader);

        for (i in 0...pluginCallbacks.length) {
            var plugin:Dynamic = pluginCallbacks[i](parser);
            if (!plugin.name) Console.error('THREE.GLTFLoader: Invalid plugin found: missing name');
            plugins[plugin.name] = plugin;
            extensions[plugin.name] = true;
        }

        if (json.extensionsUsed != null) {
            for (i in 0...json.extensionsUsed.length) {
                var extensionName:String = json.extensionsUsed[i];
                var extensionsRequired:Array<String> = json.extensionsRequired;

                switch (extensionName) {
                    case EXTENSIONS.KHR_MATERIALS_UNLIT:
                        extensions[extensionName] = new GLTFMaterialsUnlitExtension();
                        break;
                    case EXTENSIONS.KHR_DRACO_MESH_COMPRESSION:
                        extensions[extensionName] = new GLTFDracoMeshCompressionExtension(json, dracoLoader);
                        break;
                    case EXTENSIONS.KHR_TEXTURE_TRANSFORM:
                        extensions[extensionName] = new GLTFTextureTransformExtension();
                        break;
                    case EXTENSIONS.KHR_MESH_QUANTIZATION:
                        extensions[extensionName] = new GLTFMeshQuantizationExtension();
                        break;
                    default:
                        if (extensionsRequired.indexOf(extensionName) >= 0 && plugins[extensionName] == null) {
                            Console.warn('THREE.GLTFLoader: Unknown extension "' + extensionName + '".');
                        }
                }
            }
        }

        parser.setExtensions(extensions);
        parser.setPlugins(plugins);
        parser.parse(onLoad, onError);
    }

    public function parseAsync(data:Dynamic, path:String):Promise<GLTF> {
        var scope:GLTFLoader = this;
        return new Promise(function(resolve:GLTF->Void, reject:Dynamic->Void) {
            scope.parse(data, path, resolve, reject);
        });
    }
}