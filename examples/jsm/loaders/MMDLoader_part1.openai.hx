package three.js.loaders;

import three.js.loaders.FileLoader;
import three.js.loaders.MeshBuilder;
import three.js.loaders.AnimationBuilder;
import three.js.loaders.Loader;
import three.js.loaders.MMDParser;

class MMDLoader extends Loader {
    public var loader:FileLoader;
    public var parser:MMDParser;
    public var meshBuilder:MeshBuilder;
    public var animationBuilder:AnimationBuilder;
    public var animationPath:String;
    public var resourcePath:String;

    public function new(manager:Loader) {
        super(manager);

        loader = new FileLoader(this.manager);
        parser = null; // lazy generation
        meshBuilder = new MeshBuilder(this.manager);
        animationBuilder = new AnimationBuilder();
    }

    public function setAnimationPath(animationPath:String):MMDLoader {
        this.animationPath = animationPath;
        return this;
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var builder:MeshBuilder = meshBuilder.setCrossOrigin(this.crossOrigin);

        var resourcePath:String;

        if (this.resourcePath != '') {
            resourcePath = this.resourcePath;
        } else if (this.path != '') {
            resourcePath = this.path;
        } else {
            resourcePath = LoaderUtils.extractUrlBase(url);
        }

        var parser:MMDParser = this._getParser();
        var extractModelExtension:ByteArray->String = this._extractModelExtension;

        loader
            .setMimeType(undefined)
            .setPath(this.path)
            .setResponseType('arraybuffer')
            .setRequestHeader(this.requestHeader)
            .setWithCredentials(this.withCredentials)
            .load(url, function(buffer:ByteArray) {
                try {
                    var modelExtension:String = extractModelExtension(buffer);

                    if (modelExtension != 'pmd' && modelExtension != 'pmx') {
                        if (onError != null) onError(new Error('THREE.MMDLoader: Unknown model file extension .' + modelExtension + '.'));
                        return;
                    }

                    var data:Dynamic = modelExtension == 'pmd' ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);

                    onLoad(builder.build(data, resourcePath, onProgress, onError));
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    public function loadAnimation(url:String, object:Dynamic, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var builder:AnimationBuilder = animationBuilder;

        this.loadVMD(url, function(vmd:Dynamic) {
            onLoad(object.isCamera ? builder.buildCameraAnimation(vmd) : builder.build(vmd, object));
        }, onProgress, onError);
    }

    public function loadWithAnimation(modelUrl:String, vmdUrl:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope:MMDLoader = this;

        this.load(modelUrl, function(mesh:Dynamic) {
            scope.loadAnimation(vmdUrl, mesh, function(animation:Dynamic) {
                onLoad({ mesh: mesh, animation: animation });
            }, onProgress, onError);
        }, onProgress, onError);
    }

    public function loadPMD(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var parser:MMDParser = this._getParser();

        loader
            .setMimeType(undefined)
            .setPath(this.path)
            .setResponseType('arraybuffer')
            .setRequestHeader(this.requestHeader)
            .setWithCredentials(this.withCredentials)
            .load(url, function(buffer:ByteArray) {
                try {
                    onLoad(parser.parsePmd(buffer, true));
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    public function loadPMX(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var parser:MMDParser = this._getParser();

        loader
            .setMimeType(undefined)
            .setPath(this.path)
            .setResponseType('arraybuffer')
            .setRequestHeader(this.requestHeader)
            .setWithCredentials(this.withCredentials)
            .load(url, function(buffer:ByteArray) {
                try {
                    onLoad(parser.parsePmx(buffer, true));
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    public function loadVMD(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var urls:Array<String> = Std.is(url, Array) ? cast url : [url];
        var vmds:Array<Dynamic> = [];
        var vmdNum:Int = urls.length;

        var parser:MMDParser = this._getParser();

        loader
            .setMimeType(undefined)
            .setPath(this.animationPath)
            .setResponseType('arraybuffer')
            .setRequestHeader(this.requestHeader)
            .setWithCredentials(this.withCredentials);

        for (i in 0...urls.length) {
            loader.load(urls[i], function(buffer:ByteArray) {
                try {
                    vmds.push(parser.parseVmd(buffer, true));

                    if (vmds.length == vmdNum) {
                        onLoad(parser.mergeVmds(vmds));
                    }
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
        }
    }

    public function loadVPD(url:String, isUnicode:Bool, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var parser:MMDParser = this._getParser();

        loader
            .setMimeType(isUnicode ? undefined : 'text/plain; charset=shift_jis')
            .setPath(this.animationPath)
            .setResponseType('text')
            .setRequestHeader(this.requestHeader)
            .setWithCredentials(this.withCredentials)
            .load(url, function(text:String) {
                try {
                    onLoad(parser.parseVpd(text, true));
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    private function _extractModelExtension(buffer:ByteArray):String {
        var decoder:TextDecoder = new TextDecoder('utf-8');
        var bytes:ByteArray = new ByteArray( buffer, 0, 3 );
        return decoder.decode(bytes).toLowerCase();
    }

    private function _getParser():MMDParser {
        if (parser == null) {
            parser = new MMDParser();
        }
        return parser;
    }
}