import js.html.WebStorage;

class FBXLoader extends Loader {

    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope:FBXLoader = this;
        var path:String = (scope.path == '') ? LoaderUtils.extractUrlBase(url) : scope.path;
        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);

        loader.load(url, function(buffer:ArrayBuffer) {
            try {
                onLoad(scope.parse(buffer, path));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    js.Browser.console.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(FBXBuffer:ArrayBuffer, path:String):Dynamic {
        var fbxTree:Dynamic;
        if (isFbxFormatBinary(FBXBuffer)) {
            fbxTree = new BinaryParser().parse(FBXBuffer);
        } else {
            var FBXText:String = convertArrayBufferToString(FBXBuffer);
            if (!isFbxFormatASCII(FBXText)) {
                throw new js.Error("THREE.FBXLoader: Unknown format.");
            }
            if (getFbxVersion(FBXText) < 7000) {
                throw new js.Error("THREE.FBXLoader: FBX version not supported, FileVersion: " + getFbxVersion(FBXText));
            }
            fbxTree = new TextParser().parse(FBXText);
        }
        // js.Browser.console.log(fbxTree);
        var textureLoader:TextureLoader = new TextureLoader(this.manager).setPath(this.resourcePath != null ? this.resourcePath : path).setCrossOrigin(this.crossOrigin);
        return new FBXTreeParser(textureLoader, this.manager).parse(fbxTree);
    }
}