import three.FileLoader;
import three.Group;
import three.Loader;
import three.LoadingManager;
import three.loaders.ColladaLoader;
import fflate.unzipSync;
import fflate.strFromU8;

class KMZLoader extends Loader {

    public function new(manager:LoadingManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;

        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(scope.parse(text));
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

    public function parse(data:String):Dynamic {
        function findFile(url:String):Dynamic {
            for (path in zip) {
                if (path.substr(-url.length) == url) {
                    return zip[path];
                }
            }
            return null;
        }

        var manager = new LoadingManager();
        manager.setURLModifier(function(url:String):String {
            var image = findFile(url);
            if (image != null) {
                trace('Loading', url);
                var blob = js.Browser.Blob.fromArrayBuffer(image.buffer);
                return URL.createObjectURL(blob);
            }
            return url;
        });

        var zip = unzipSync(Std.stringToBytes(data));

        if (zip['doc.kml'] != null) {
            var xml = new js.Browser.DOMParser().parseFromString(fflate.strFromU8(zip['doc.kml']), 'application/xml');
            var model = xml.querySelector('Placemark Model Link href');
            if (model != null) {
                var loader = new ColladaLoader(manager);
                return loader.parse(fflate.strFromU8(zip[model.textContent]));
            }
        } else {
            trace('KMZLoader: Missing doc.kml file.');
            for (path in zip) {
                var extension = path.split('.').pop().toLowerCase();
                if (extension == 'dae') {
                    var loader = new ColladaLoader(manager);
                    return loader.parse(fflate.strFromU8(zip[path]));
                }
            }
        }

        trace('KMZLoader: Couldn\'t find .dae file.');
        return {scene: new Group()};
    }
}