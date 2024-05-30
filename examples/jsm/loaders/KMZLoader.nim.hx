import three.examples.jsm.loaders.ColladaLoader;
import three.examples.jsm.libs.fflate.module.fflate;
import three.FileLoader;
import three.Group;
import three.Loader;
import three.LoadingManager;

class KMZLoader extends Loader {

    public function new(manager:LoadingManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setResponseType("arraybuffer");
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch (e) {
                if (onError) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data:haxe.io.Bytes) {
        function findFile(url:String) {
            for (path in zip) {
                if (path.substr(-url.length) == url) {
                    return zip[path];
                }
            }
        }

        var manager = new LoadingManager();
        manager.setURLModifier(function(url) {
            var image = findFile(url);
            if (image) {
                trace("Loading", url);
                var blob = new Blob([image.buffer], {type: "application/octet-stream"});
                return URL.createObjectURL(blob);
            }
            return url;
        });

        var zip = fflate.unzipSync(data.b);

        if (zip["doc.kml"]) {
            var xml = new DOMParser().parseFromString(fflate.strFromU8(zip["doc.kml"]), "application/xml");
            var model = xml.querySelector("Placemark Model Link href");
            if (model) {
                var loader = new ColladaLoader(manager);
                return loader.parse(fflate.strFromU8(zip[model.textContent]));
            }
        } else {
            trace("KMZLoader: Missing doc.kml file.");
            for (path in zip) {
                var extension = path.split(".").pop().toLowerCase();
                if (extension == "dae") {
                    var loader = new ColladaLoader(manager);
                    return loader.parse(fflate.strFromU8(zip[path]));
                }
            }
        }
        trace("KMZLoader: Couldn't find .dae file.");
        return {scene: new Group()};
    }
}