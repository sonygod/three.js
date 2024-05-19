package three.js.examples.jsm.loaders;

import haxe.io.Bytes;
import js.html.Uint8Array;
import js.html.TextDecoder;

class MMDLoader extends Loader {
    public var loader:FileLoader;
    public var parser:MMDParser.Parser;
    public var meshBuilder:MeshBuilder;
    public var animationBuilder:AnimationBuilder;
    public var animationPath:String;
    public var resourcePath:String;
    public var path:String;
    public var crossOrigin:Bool;
    public var requestHeader:Dynamic;
    public var withCredentials:Bool;

    public function new(manager:Dynamic) {
        super(manager);
        loader = new FileLoader(this.manager);
        parser = null; // lazy generation
        meshBuilder = new MeshBuilder(this.manager);
        animationBuilder = new AnimationBuilder();
    }

    /**
     * @param animationPath
     * @return MMDLoader
     */
    public function setAnimationPath(animationPath:String):MMDLoader {
        this.animationPath = animationPath;
        return this;
    }

    /**
     * Loads Model file (.pmd or .pmx) as a SkinnedMesh.
     *
     * @param url - url to Model(.pmd or .pmx) file
     * @param onLoad
     * @param onProgress
     * @param onError
     */
    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
        var builder = meshBuilder.setCrossOrigin(crossOrigin);

        var resourcePath:String;
        if (this.resourcePath != '') {
            resourcePath = this.resourcePath;
        } else if (this.path != '') {
            resourcePath = this.path;
        } else {
            resourcePath = LoaderUtils.extractUrlBase(url);
        }

        var parser = _getParser();
        var extractModelExtension = _extractModelExtension;

        loader
            .setMimeType(undefined)
            .setPath(path)
            .setResponseType('arraybuffer')
            .setRequestHeader(requestHeader)
            .setWithCredentials(withCredentials)
            .load(url, function(buffer:Bytes) {
                try {
                    var modelExtension = extractModelExtension(buffer);
                    if (modelExtension != 'pmd' && modelExtension != 'pmx') {
                        if (onError != null) onError(new Error('THREE.MMDLoader: Unknown model file extension .' + modelExtension + '.'));
                        return;
                    }

                    var data = modelExtension == 'pmd' ? parser.parsePmd(buffer, true) : parser.parsePmx(buffer, true);
                    onLoad(builder.build(data, resourcePath, onProgress, onError));
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    /**
     * Loads Motion file(s) (.vmd) as a AnimationClip.
     * If two or more files are specified, they'll be merged.
     *
     * @param url - url(s) to animation(.vmd) file(s)
     * @param object - tracks will be fitting to this object
     * @param onLoad
     * @param onProgress
     * @param onError
     */
    public function loadAnimation(url:Dynamic, object:Dynamic, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
        var builder = animationBuilder;

        loadVMD(url, function(vmd:Dynamic) {
            onLoad(object.isCamera ? builder.buildCameraAnimation(vmd) : builder.build(vmd, object));
        }, onProgress, onError);
    }

    /**
     * Loads mode file and motion file(s) as an object containing
     * a SkinnedMesh and a AnimationClip.
     * Tracks of AnimationClip are fitting to the model.
     *
     * @param modelUrl - url to Model(.pmd or .pmx) file
     * @param vmdUrl - url(s) to animation(.vmd) file
     * @param onLoad
     * @param onProgress
     * @param onError
     */
    public function loadWithAnimation(modelUrl:String, vmdUrl:Dynamic, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
        var scope = this;

        load(modelUrl, function(mesh:Dynamic) {
            scope.loadAnimation(vmdUrl, mesh, function(animation:Dynamic) {
                onLoad({ mesh: mesh, animation: animation });
            }, onProgress, onError);
        }, onProgress, onError);
    }

    // Load MMD assets as Object data parsed by MMDParser

    /**
     * Loads .pmd file as an Object.
     *
     * @param url - url to .pmd file
     * @param onLoad
     * @param onProgress
     * @param onError
     */
    public function loadPMD(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
        var parser = _getParser();

        loader
            .setMimeType(undefined)
            .setPath(path)
            .setResponseType('arraybuffer')
            .setRequestHeader(requestHeader)
            .setWithCredentials(withCredentials)
            .load(url, function(buffer:Bytes) {
                try {
                    onLoad(parser.parsePmd(buffer, true));
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    /**
     * Loads .pmx file as an Object.
     *
     * @param url - url to .pmx file
     * @param onLoad
     * @param onProgress
     * @param onError
     */
    public function loadPMX(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
        var parser = _getParser();

        loader
            .setMimeType(undefined)
            .setPath(path)
            .setResponseType('arraybuffer')
            .setRequestHeader(requestHeader)
            .setWithCredentials(withCredentials)
            .load(url, function(buffer:Bytes) {
                try {
                    onLoad(parser.parsePmx(buffer, true));
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    /**
     * Loads .vmd file as an Object. If two or more files are specified
     * they'll be merged.
     *
     * @param url - url(s) to .vmd file(s)
     * @param onLoad
     * @param onProgress
     * @param onError
     */
    public function loadVMD(url:Dynamic, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
        var urls:Array<String> = Std.isOfType(url, Array) ? cast url : [url];
        var vmds:Array<Dynamic> = [];
        var vmdNum:Int = urls.length;

        var parser = _getParser();

        loader
            .setMimeType(undefined)
            .setPath(animationPath)
            .setResponseType('arraybuffer')
            .setRequestHeader(requestHeader)
            .setWithCredentials(withCredentials);

        for (i in 0...urls.length) {
            loader.load(urls[i], function(buffer:Bytes) {
                try {
                    vmds.push(parser.parseVmd(buffer, true));
                    if (vmds.length == vmdNum) onLoad(parser.mergeVmds(vmds));
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
        }
    }

    /**
     * Loads .vpd file as an Object.
     *
     * @param url - url to .vpd file
     * @param isUnicode
     * @param onLoad
     * @param onProgress
     * @param onError
     */
    public function loadVPD(url:String, isUnicode:Bool, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
        var parser = _getParser();

        loader
            .setMimeType(isUnicode ? undefined : 'text/plain; charset=shift_jis')
            .setPath(animationPath)
            .setResponseType('text')
            .setRequestHeader(requestHeader)
            .setWithCredentials(withCredentials)
            .load(url, function(text:String) {
                try {
                    onLoad(parser.parseVpd(text, true));
                } catch (e:Dynamic) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    // private methods

    function _extractModelExtension(buffer:Bytes):String {
        var decoder = new TextDecoder('utf-8');
        var bytes = new Uint8Array(buffer, 0, 3);
        return decoder.decode(bytes).toLowerCase();
    }

    function _getParser():MMDParser.Parser {
        if (parser == null) {
            parser = new MMDParser.Parser();
        }
        return parser;
    }
}