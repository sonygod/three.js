class FBXLoader extends Loader {
    public function new(manager:BaseLoader) {
        super(manager);
    }

    public function load(url:String, onLoad:LoadHandler, onProgress:ProgressHandler, onError:ErrorHandler):Void {
        var scope = this;
        var path = if (scope.path == '') LoaderUtils.extractUrlBase(url) else scope.path;
        var loader = new FileLoader(scope.manager);
        loader.path = scope.path;
        loader.responseType = 'arraybuffer';
        loader.requestHeader = scope.requestHeader;
        loader.withCredentials = scope.withCredentials;

        loader.load(url, function(buffer) {
            try {
                onLoad(scope.parse(buffer, path));
            } catch(e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(FBXBuffer:ArrayBuffer, path:String):FBX {
        if (isFbxFormatBinary(FBXBuffer)) {
            var fbxTree = new BinaryParser().parse(FBXBuffer);
        } else {
            var FBXText = convertArrayBufferToString(FBXBuffer);
            if (!isFbxFormatASCII(FBXText)) {
                throw new Error('THREE.FBXLoader: Unknown format.');
            }
            if (getFbxVersion(FBXText) < 7000) {
                throw new Error('THREE.FBXLoader: FBX version not supported, FileVersion: ' + getFbxVersion(FBXText));
            }
            var fbxTree = new TextParser().parse(FBXText);
        }

        var textureLoader = new TextureLoader(scope.manager);
        textureLoader.path = scope.resourcePath != null ? scope.resourcePath : path;
        textureLoader.crossOrigin = scope.crossOrigin;

        return new FBXTreeParser(textureLoader, scope.manager).parse(fbxTree);
    }
}