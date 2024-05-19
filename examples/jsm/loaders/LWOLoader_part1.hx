package three.js.examples.jm.loaders;

import haxe.io.Bytes;
import js.html.ArrayBuffer;
import js.html.XMLHttpRequest;
import three.js.loaders.Loader;
import three.js.loaders.FileLoader;
import three.js.loaders.TextureLoader;
import three.js.parsers.IFFParser;
import three.js.parsers.LWOTreeParser;

class LWOLoader extends Loader {
    
    public var resourcePath:String;

    public function new(manager:LoaderManager, ?parameters:Dynamic) {
        super(manager);
        resourcePath = (parameters != null && parameters.resourcePath != null) ? parameters.resourcePath : '';
    }

    public function load(url:String, onLoad:(Dynamic->Void), onProgress:(Float->Void), onError:(Dynamic->Void)) {
        var scope:LWOLoader = this;
        var path:String = (scope.path == '') ? extractParentUrl(url, 'Objects') : scope.path;
        var modelName:String = url.split(path).pop().split('.').shift();

        var loader:FileLoader = new FileLoader(this.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');

        loader.load(url, function(buffer:ArrayBuffer) {
            try {
                onLoad(scope.parse(Bytes.ofData(buffer), path, modelName));
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

    public function parse(iffBuffer:Bytes, path:String, modelName:String):Dynamic {
        var lwoTree = new IFFParser().parse(iffBuffer);

        var textureLoader:TextureLoader = new TextureLoader(this.manager).setPath(resourcePath != null ? resourcePath : path).setCrossOrigin(crossOrigin);

        return new LWOTreeParser(textureLoader).parse(modelName);
    }
}