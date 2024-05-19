package three.js.examples.jm.loaders;

import three.js.loaders.Loader;
import three.js.loaders.FileLoader;
import three.js.loaders.ColladaLoader;
import three.js.core.Group;
import three.js.loaders.LoadingManager;
import js.Blob;
import js.html.DOMParser;
import js.html.URL;

class KMZLoader extends Loader {
    
    public function new(manager:LoadingManager) {
        super(manager);
    }

    public function load(url:String, onLoad:(object:Dynamic)->Void, onProgress:(event:ProgressEvent)->Void, onError:(event:ErrorEvent)->Void):Void {
        var scope:KMZLoader = this;
        var loader:FileLoader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(data:ArrayBuffer) {
            try {
                onLoad(scope.parse(data));
            } catch (e:Error) {
                if (onError != null) {
                    onError(e);
                } else {
                    Console.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data:ArrayBuffer):Dynamic {
        function findFile(url:String):Dynamic {
            for (path in zip) {
                if (path.substr(-url.length) == url) {
                    return zip[path];
                }
            }
            return null;
        }

        var manager:LoadingManager = new LoadingManager();
        manager.setURLModifier(function(url:String):String {
            var image:Dynamic = findFile(url);
            if (image != null) {
                Console.log('Loading ' + url);
                var blob:Blob = new Blob([image.buffer], { type: 'application/octet-stream' });
                return URL.createObjectURL(blob);
            }
            return url;
        });

        var zip:Dynamic = fflate.unzipSync(new Uint8Array(data));
        if (zip['doc.kml'] != null) {
            var xml:Dynamic = new DOMParser().parseFromString(fflate.strFromU8(zip['doc.kml']), 'application/xml');
            var model:Dynamic = xml.querySelector('Placemark Model Link href');
            if (model != null) {
                var loader:ColladaLoader = new ColladaLoader(manager);
                return loader.parse(fflate.strFromU8(zip[model.textContent]));
            }
        } else {
            Console.warn('KMZLoader: Missing doc.kml file.');
            for (path in zip) {
                var extension:String = path.split('.').pop().toLowerCase();
                if (extension == 'dae') {
                    var loader:ColladaLoader = new ColladaLoader(manager);
                    return loader.parse(fflate.strFromU8(zip[path]));
                }
            }
        }
        Console.error('KMZLoader: Couldn\'t find .dae file.');
        return { scene: new Group() };
    }
}