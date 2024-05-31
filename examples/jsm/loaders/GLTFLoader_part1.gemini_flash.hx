import three.core.Object3D;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.loaders.LoaderUtils;
import three.loaders.LoadingManager;
import js.lib.Promise;
import three.extensions.gltf.GLTFParser;
import three.extensions.gltf.GLTFBinaryExtension;
import three.extensions.gltf.EXTENSIONS;
import three.extensions.gltf.DRACOLoader;
import three.extensions.gltf.KTX2Loader;
import three.extensions.gltf.MeshoptDecoder;

// Extensions
import three.extensions.gltf.GLTFMaterialsUnlitExtension;
import three.extensions.gltf.GLTFDracoMeshCompressionExtension;
import three.extensions.gltf.GLTFTextureTransformExtension;
import three.extensions.gltf.GLTFMeshQuantizationExtension;
import three.extensions.gltf.GLTFMaterialsClearcoatExtension;
import three.extensions.gltf.GLTFMaterialsDispersionExtension;
import three.extensions.gltf.GLTFTextureBasisUExtension;
import three.extensions.gltf.GLTFTextureWebPExtension;
import three.extensions.gltf.GLTFTextureAVIFExtension;
import three.extensions.gltf.GLTFMaterialsSheenExtension;
import three.extensions.gltf.GLTFMaterialsTransmissionExtension;
import three.extensions.gltf.GLTFMaterialsVolumeExtension;
import three.extensions.gltf.GLTFMaterialsIorExtension;
import three.extensions.gltf.GLTFMaterialsEmissiveStrengthExtension;
import three.extensions.gltf.GLTFMaterialsSpecularExtension;
import three.extensions.gltf.GLTFMaterialsIridescenceExtension;
import three.extensions.gltf.GLTFMaterialsAnisotropyExtension;
import three.extensions.gltf.GLTFMaterialsBumpExtension;
import three.extensions.gltf.GLTFLightsExtension;
import three.extensions.gltf.GLTFMeshoptCompression;
import three.extensions.gltf.GLTFMeshGpuInstancing;

class GLTFLoader extends Loader {

    public var dracoLoader:DRACOLoader;
    public var ktx2Loader:KTX2Loader;
    public var meshoptDecoder:MeshoptDecoder;
    public var pluginCallbacks:Array<Dynamic>;
    
    public function new(manager:LoadingManager = null) {
        super(manager);

        this.dracoLoader = null;
        this.ktx2Loader = null;
        this.meshoptDecoder = null;

        this.pluginCallbacks = [];

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsClearcoatExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsDispersionExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFTextureBasisUExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFTextureWebPExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFTextureAVIFExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsSheenExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsTransmissionExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsVolumeExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsIorExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsEmissiveStrengthExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsSpecularExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsIridescenceExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsAnisotropyExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMaterialsBumpExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFLightsExtension(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMeshoptCompression(parser);
        });

        register(function (parser:GLTFParser) {
            return new GLTFMeshGpuInstancing(parser);
        });
    }

    public function load(url:String, onLoad:Object3D->Void, ?onProgress:Int->Void, ?onError:Dynamic->Void):Void {

        var scope = this;
        var resourcePath:String = null;

        if (this.resourcePath != '') {
            resourcePath = this.resourcePath;
        } else if (this.path != '') {
            var relativeUrl = LoaderUtils.extractUrlBase(url);
            resourcePath = LoaderUtils.resolveURL(relativeUrl, this.path);
        } else {
            resourcePath = LoaderUtils.extractUrlBase(url);
        }

        this.manager.itemStart(url);

        var _onError = function (e) {
            if (onError != null) {
                onError(e);
            } else {
                trace('Error: ' + e);
            }

            scope.manager.itemError(url);
            scope.manager.itemEnd(url);
        };

        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);

        loader.load(url, function (data:ArrayBuffer) {
            try {
                scope.parse(data.buffer, resourcePath, function (gltf) {
                    onLoad(gltf);
                    scope.manager.itemEnd(url);
                }, _onError);
            } catch (e) {
                _onError(e);
            }
        }, onProgress, _onError);

    }

    public function setDRACOLoader(dracoLoader:DRACOLoader):GLTFLoader {
        this.dracoLoader = dracoLoader;
        return this;
    }

    public function setDDSLoader():Void {
        throw "THREE.GLTFLoader: \"MSFT_texture_dds\" no longer supported. Please update to \"KHR_texture_basisu\".";
    }

    public function setKTX2Loader(ktx2Loader:KTX2Loader):GLTFLoader {
        this.ktx2Loader = ktx2Loader;
        return this;
    }

    public function setMeshoptDecoder(meshoptDecoder:MeshoptDecoder):GLTFLoader {
        this.meshoptDecoder = meshoptDecoder;
        return this;
    }

    public function register(callback:GLTFParser->Dynamic):GLTFLoader {
        if (this.pluginCallbacks.indexOf(callback) == -1) {
            this.pluginCallbacks.push(callback);
        }
        return this;
    }

    public function unregister(callback:GLTFParser->Dynamic):GLTFLoader {
        var index = this.pluginCallbacks.indexOf(callback);
        if (index != -1) {
            this.pluginCallbacks.splice(index, 1);
        }
        return this;
    }

    public function parse(data:haxe.io.BytesData, path:String, onLoad:Object3D->Void, ?onError:Dynamic->Void):Void {
        var json:Dynamic = null;
        var extensions = {};
        var plugins = {};

        // Determine the type of data and parse accordingly
        if (Std.isOfType(data, String)) {
            json = haxe.Json.parse(cast(data, String));
        } else if (Std.isOfType(data, haxe.io.BytesData)) {
            var byteData:haxe.io.BytesData = cast data;

            // Check for binary glTF header
            if (byteData.length >= 4 && byteData.get(0) == 0x67 && byteData.get(1) == 0x6c && byteData.get(2) == 0x54 && byteData.get(3) == 0x46) {
                try {
                    extensions[EXTENSIONS.KHR_BINARY_GLTF] = new GLTFBinaryExtension(byteData);
                } catch (error) {
                    if (onError != null) onError(error);
                    return;
                }
                json = haxe.Json.parse(extensions[EXTENSIONS.KHR_BINARY_GLTF].content);
            } else {
                // Assume JSON format
                var textDecoder = new TextDecoder();
                var text = textDecoder.decode(new Uint8Array(byteData));
                json = haxe.Json.parse(text);
            }
        } else {
            // Handle other potential data types (e.g., Blob) if needed
            if (onError != null) onError("Unsupported data type: " + Type.typeof(data));
            return;
        }

        if (json.asset == null || json.asset.version[0] < 2) {
            if (onError != null) onError(new Error("THREE.GLTFLoader: Unsupported asset. glTF versions >=2.0 are supported."));
            return;
        }

        var parser = new GLTFParser(json, {
            path: path != null ? path : (this.resourcePath != null ? this.resourcePath : ""),
            crossOrigin: this.crossOrigin,
            requestHeader: this.requestHeader,
            manager: this.manager,
            ktx2Loader: this.ktx2Loader,
            meshoptDecoder: this.meshoptDecoder
        });

        parser.fileLoader.setRequestHeader(this.requestHeader);

        for (i in 0...this.pluginCallbacks.length) {
            var plugin = this.pluginCallbacks[i](parser);
            if (plugin.name == null) {
                trace('THREE.GLTFLoader: Invalid plugin found: missing name');
            }

            plugins[plugin.name] = plugin;
            extensions[plugin.name] = true; // Workaround
        }

        if (json.extensionsUsed != null) {
            for (i in 0...json.extensionsUsed.length) {
                var extensionName = json.extensionsUsed[i];
                var extensionsRequired = json.extensionsRequired;

                switch (extensionName) {
                    case EXTENSIONS.KHR_MATERIALS_UNLIT:
                        extensions[extensionName] = new GLTFMaterialsUnlitExtension();
                    case EXTENSIONS.KHR_DRACO_MESH_COMPRESSION:
                        extensions[extensionName] = new GLTFDracoMeshCompressionExtension(json, this.dracoLoader);
                    case EXTENSIONS.KHR_TEXTURE_TRANSFORM:
                        extensions[extensionName] = new GLTFTextureTransformExtension();
                    case EXTENSIONS.KHR_MESH_QUANTIZATION:
                        extensions[extensionName] = new GLTFMeshQuantizationExtension();
                    default:
                        if (extensionsRequired != null && extensionsRequired.indexOf(extensionName) >= 0 && plugins[extensionName] == null) {
                            trace('THREE.GLTFLoader: Unknown extension "' + extensionName + '".');
                        }
                }
            }
        }

        parser.setExtensions(extensions);
        parser.setPlugins(plugins);
        parser.parse(onLoad, onError);
    }

    public function parseAsync(data:haxe.io.BytesData, path:String):Promise<Object3D> {
        var scope = this;
        return new Promise(function(resolve, reject) {
            scope.parse(data, path, resolve, reject);
        });
    }

}