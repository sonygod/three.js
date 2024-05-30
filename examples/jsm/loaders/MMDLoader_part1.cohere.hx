class MMDLoader extends Loader {
    private var loader:FileLoader;
    private var meshBuilder:MeshBuilder;
    private var animationBuilder:AnimationBuilder;
    private var parser:MMDParser.Parser;
    private var animationPath:String;

    public function new(manager:LoadingManager) {
        super(manager);
        loader = FileLoader(manager);
        meshBuilder = MeshBuilder(manager);
        animationBuilder = AnimationBuilder();
        parser = null;
    }

    public function setAnimationPath(animationPath:String):MMDLoader {
        this.animationPath = animationPath;
        return this;
    }

    public function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
        var builder = meshBuilder.setCrossOrigin(crossOrigin);
        var resourcePath:String = null;

        if (resourcePath == null) {
            if (this.resourcePath != null) {
                resourcePath = this.resourcePath;
            } else if (this.path != null) {
                resourcePath = this.path;
            } else {
                resourcePath = LoaderUtils.extractUrlBase(url);
            }
        }

        var extractModelExtension = _extractModelExtension;
        var parser = _getParser();

        loader.setMimeType(null)
            .setPath(path)
            .setResponseType('arraybuffer')
            .setRequestHeader(requestHeader)
            .setWithCredentials(withCredentials)
            .load(url, function(buffer) {
                try {
                    var modelExtension = extractModelExtension(buffer);
                    if (modelExtension != 'pmd' && modelExtension != 'pmx') {
                        if (onError != null) onError(Std.string('THREE.MMDLoader: Unknown model file extension .' + modelExtension + '.'));
                        return;
                    }
                    var data = if (modelExtension == 'pmd') parser.parsePmd(buffer, true) else parser.parsePmx(buffer, true);
                    onLoad(builder.build(data, resourcePath, onProgress, onError));
                } catch( e:Dynamic ) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    public function loadAnimation(url:Dynamic, object:Dynamic, onLoad:Function, onProgress:Function, onError:Function):Void {
        var builder = animationBuilder;
        loadVMD(url, function(vmd) {
            onLoad(if (object.isCamera) builder.buildCameraAnimation(vmd) else builder.build(vmd, object));
        }, onProgress, onError);
    }

    public function loadWithAnimation(modelUrl:String, vmdUrl:Dynamic, onLoad:Function, onProgress:Function, onError:Function):Void {
        var scope = this;
        load(modelUrl, function(mesh) {
            scope.loadAnimation(vmdUrl, mesh, function(animation) {
                onLoad({ mesh: mesh, animation: animation });
            }, onProgress, onError);
        }, onProgress, onError);
    }

    public function loadPMD(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
        var parser = _getParser();
        loader.setMimeType(null)
            .setPath(path)
            .setResponseType('arraybuffer')
            .setRequestHeader(requestHeader)
            .setWithCredentials(withCredentials)
            .load(url, function(buffer) {
                try {
                    onLoad(parser.parsePmd(buffer, true));
                } catch( e:Dynamic ) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    public function loadPMX(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
        var parser = _getParser();
        loader.setMimeType(null)
            .setPath(path)
            .setResponseType('arraybuffer')
            .setRequestHeader(requestHeader)
            .setWithCredentials(withCredentials)
            .load(url, function(buffer) {
                try {
                    onLoad(parser.parsePmx(buffer, true));
                } catch( e:Dynamic ) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    public function loadVMD(url:Dynamic, onLoad:Function, onProgress:Function, onError:Function):Void {
        var urls = if (Array.isArray(url)) url else [url];
        var vmds = [];
        var vmdNum = urls.length;
        var parser = _getParser();
        loader.setMimeType(null)
            .setPath(animationPath)
            .setResponseType('arraybuffer')
            .setRequestHeader(requestHeader)
            .setWithCredentials(withCredentials);

        for (i in 0...vmdNum) {
            var i = i;
            loader.load(urls[i], function(buffer) {
                try {
                    vmds.push(parser.parseVmd(buffer, true));
                    if (vmds.length == vmdNum) onLoad(parser.mergeVmds(vmds));
                } catch( e:Dynamic ) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
        }
    }

    public function loadVPD(url:String, isUnicode:Bool, onLoad:Function, onProgress:Function, onError:Function):Void {
        var parser = _getParser();
        loader.setMimeType(if (isUnicode) null else 'text/plain; charset=shift_jis')
            .setPath(animationPath)
            .setResponseType('text')
            .setRequestHeader(requestHeader)
            .setWithCredentials(withCredentials)
            .load(url, function(text) {
                try {
                    onLoad(parser.parseVpd(text, true));
                } catch( e:Dynamic ) {
                    if (onError != null) onError(e);
                }
            }, onProgress, onError);
    }

    private function _extractModelExtension(buffer:Bytes):String {
        var bytes = new Uint8Array(buffer, 0, 3);
        return new String(bytes, 'utf-8').toLowerCase();
    }

    private function _getParser():MMDParser.Parser {
        if (parser == null) {
            parser = MMDParser.Parser();
        }
        return parser;
    }
}