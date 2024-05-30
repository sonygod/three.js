class GLTFLoader extends Loader {
    var dracoLoader:DracoLoader;
    var ktx2Loader:KTX2Loader;
    var meshoptDecoder:MeshoptDecoder;
    var pluginCallbacks:Array<Function>;

    public function new(manager:LoadingManager) {
        super(manager);
        pluginCallbacks = [];

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsClearcoatExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsDispersionExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFTextureBasisUExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFTextureWebPExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFTextureAVIFExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsSheenExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsTransmissionExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsVolumeExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsIorExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsEmissiveStrengthExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsSpecularExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsIridescenceExtension(parser);
        });

        register(function(parser:GLTFParser) {
            return new GLTFMaterialsAnisotropyExtension(parser);
        });

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

    public function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
        var scope = this;
        var resourcePath:String;

        if (resourcePath != '') {
            resourcePath = this.resourcePath;
        } else if (path != '') {
            var relativeUrl = LoaderUtils.extractUrlBase(url);
            resourcePath = LoaderUtils.resolveURL(relativeUrl, this.path);
        } else {
            resourcePath = LoaderUtils.extractUrlBase(url);
        }

        manager.itemStart(url);

        function _onError(e:Dynamic) {
            if (onError != null) {
                onError(e);
            } else {
                trace(e);
            }
            scope.manager.itemError(url);
            scope.manager.itemEnd(url);
        }

        var loader = new FileLoader(manager);
        loader.path = this.path;
        loader.responseType = 'arraybuffer';
        loader.requestHeader = this.requestHeader;
        loader.withCredentials = this.withCredentials;

        loader.load(url, function(data) {
            try {
                scope.parse(data, resourcePath, function(gltf) {
                    onLoad(gltf);
                    scope.manager.itemEnd(url);
                }, _onError);
            } catch(e) {
                _onError(e);
            }
        }, onProgress, _onError);
    }

    public function setDRACOLoader(dracoLoader:DracoLoader):GLTFLoader {
        this.dracoLoader = dracoLoader;
        return this;
    }

    public function setDDSLoader():Void {
        throw new Error('THREE.GLTFLoader: "MSFT_texture_dds" no longer supported. Please update to "KHR_texture_basisu".');
    }

    public function setKTX2Loader(ktx2Loader:KTX2Loader):GLTFLoader {
        this.ktx2Loader = ktx2Loader;
        return this;
    }

    public function setMeshoptDecoder(meshoptDecoder:MeshoptDecoder):GLTFLoader {
        this.meshoptDecoder = meshoptDecoder;
        return this;
    }

    public function register(callback:Function):GLTFLoader {
        if (pluginCallbacks.indexOf(callback) == -1) {
            pluginCallbacks.push(callback);
        }
        return this;
    }

    public function unregister(callback:Function):GLTFLoader {
        if (pluginCallbacks.indexOf(callback) != -1) {
            pluginCallbacks.splice(pluginCallbacks.indexOf(callback), 1);
        }
        return this;
    }

    public function parse(data:Dynamic, path:String, onLoad:Function, onError:Function):Void {
        var json:Dynamic;
        var extensions:Map<String, GLTFExtension>;
        var plugins:Map<String, GLTFPlugin>;
        var textDecoder = new TextDecoder();

        if (Std.is(data, String)) {
            json = Json.parse(data);
        } else if (Std.is(data, ArrayBuffer)) {
            var magic = textDecoder.decode(new Uint8Array(data, 0, 4));
            if (magic == BINARY_EXTENSION_HEADER_MAGIC) {
                try {
                    extensions = {EXTENSIONS.KHR_BINARY_GLTF: new GLTFBinaryExtension(data)};
                    json = Json.parse(extensions[EXTENSIONS.KHR_BINARY_GLTF].content);
                } catch(error) {
                    if (onError != null) onError(error);
                    return;
                }
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

        var parser = new GLTFParser(json, {
            path: path != null ? path : (resourcePath != null ? resourcePath : ''),
            crossOrigin: crossOrigin,
            requestHeader: requestHeader,
            manager: manager,
            ktx2Loader: ktx2Loader,
            meshoptDecoder: meshoptDecoder
        });

        parser.fileLoader.setRequestHeader(requestHeader);

        for (i in 0...pluginCallbacks.length) {
            var plugin = pluginCallbacks[i](parser);
            if (plugin.name == null) {
                trace('THREE.GLTFLoader: Invalid plugin found: missing name');
            }
            plugins[plugin.name] = plugin;
            extensions[plugin.name] = true; // Workaround to avoid determining as unknown extension
        }

        if (json.extensionsUsed != null) {
            for (i in 0...json.extensionsUsed.length) {
                var extensionName = json.extensionsUsed[i];
                var extensionsRequired = json.extensionsRequired != null ? json.extensionsRequired : [];

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
                        if (extensionsRequired.indexOf(extensionName) != -1 && plugins[extensionName] == null) {
                            trace('THREE.GLTFLoader: Unknown extension "' + extensionName + '".');
                        }
                }
            }
        }

        parser.setExtensions(extensions);
        parser.setPlugins(plugins);
        parser.parse(onLoad, onError);
    }

    public function parseAsync(data:Dynamic, path:String):Promise<Dynamic> {
        var scope = this;
        return new Promise(function(resolve, reject) {
            scope.parse(data, path, resolve, reject);
        });
    }
}