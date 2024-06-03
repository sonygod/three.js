import js.html.FileLoader;
import three.Group;
import three.Loader;
import three.LoadingManager;
import ColladaLoader;
import fflate;

class KMZLoader extends Loader {

    public function new(manager: LoadingManager) {
        super(manager);
    }

    public function load(url: String, onLoad: Null<(obj: Dynamic) -> Void>, onProgress: Null<(event: ProgressEvent) -> Void>, onError: Null<(event: ErrorEvent) -> Void>) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setResponseType('arraybuffer');
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load((text) -> {
            try {
                if (onLoad != null) {
                    onLoad(this.parse(text));
                }
            } catch (err:Dynamic) {
                if (onError != null) {
                    onError(err);
                } else {
                    js.Browser.console.error(err);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data: ArrayBuffer): Dynamic {
        var findFile = function(url: String): Dynamic {
            var zip = fflate.unzipSync(new Uint8Array(data));
            for (path in zip) {
                if (path.substr(path.length - url.length, url.length) === url) {
                    return zip[path];
                }
            }
            return null;
        };

        var manager = new LoadingManager();
        manager.setURLModifier(function(url: String): String {
            var image = findFile(url);
            if (image != null) {
                js.Browser.console.log('Loading', url);
                var blob = new js.html.Blob([image.buffer], {type: 'application/octet-stream'});
                return js.html.URL.createObjectURL(blob);
            }
            return url;
        });

        var zip = fflate.unzipSync(new Uint8Array(data));

        if (zip['doc.kml'] != null) {
            var xml = js.Browser.document.implementation.createDocument('', '', null);
            xml.loadXML(fflate.strFromU8(zip['doc.kml']));
            var model = xml.querySelector('Placemark Model Link href');
            if (model != null) {
                var loader = new ColladaLoader(manager);
                return loader.parse(fflate.strFromU8(zip[model.textContent]));
            }
        } else {
            js.Browser.console.warn('KMZLoader: Missing doc.kml file.');
            for (path in zip) {
                var extension = path.split('.').pop().toLowerCase();
                if (extension === 'dae') {
                    var loader = new ColladaLoader(manager);
                    return loader.parse(fflate.strFromU8(zip[path]));
                }
            }
        }

        js.Browser.console.error('KMZLoader: Couldn\'t find .dae file.');
        return {scene: new Group()};
    }
}