package three.js.examples.jss.loaders;

import three.js.loaders.Loader;
import three.js.loaders.FileLoader;
import three.js.loaders.LoaderUtils;
import three.js.loaders.FBXTreeParser;
import three.js.loaders.TextureLoader;
import three.js.loaders.BinaryParser;
import three.js.loaders.TextParser;

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
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(FBXBuffer:ArrayBuffer, path:String):Dynamic {
        if (isFbxFormatBinary(FBXBuffer)) {
            var fbxTree:Dynamic = new BinaryParser().parse(FBXBuffer);
        } else {
            var FBXText:String = convertArrayBufferToString(FBXBuffer);
            if (!isFbxFormatASCII(FBXText)) {
                throw new Error('THREE.FBXLoader: Unknown format.');
            }
            if (getFbxVersion(FBXText) < 7000) {
                throw new Error('THREE.FBXLoader: FBX version not supported, FileVersion: ' + getFbxVersion(FBXText));
            }
            fbxTree = new TextParser().parse(FBXText);
        }
        // trace(fbxTree);

        var textureLoader:TextureLoader = new TextureLoader(this.manager).setPath(this.resourcePath || path).setCrossOrigin(this.crossOrigin);
        return new FBXTreeParser(textureLoader, this.manager).parse(fbxTree);
    }
}