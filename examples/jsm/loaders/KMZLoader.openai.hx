package three.js.examples.jsm.loaders;

import three.js.loaders.Loader;
import three.js.loaders.FileLoader;
import three.js.loaders.ColladaLoader;
import three.js.core.Group;
import three.js.loaders.LoadingManager;
import js.lib.DOMParser;
import js.html.XMLDocument;

import fflate.Fflate;

class KMZLoader extends Loader {
    public function new(manager:LoadingManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
        var loader = new FileLoader(manager);
        loader.path = path;
        loader.responseType = 'arraybuffer';
        loader.setRequestHeader(requestHeader);
        loader.withCredentials = withCredentials;
        loader.load(url, function(data:ArrayBuffer) {
            try {
                onLoad(parse(data));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    console.error(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parse(data:ArrayBuffer) {
        var zip = Fflate.unzipSync(new Uint8Array(data));
        var manager = new LoadingManager();
        manager.setURLModifier(function(url:String) {
            for (path in zip.keys()) {
                if (path.endsWith(url)) {
                    var image = zip[path];
                    console.log('Loading', url);
                    var blob = new js.html.Blob([image.buffer], { type: 'application/octet-stream' });
                    return js.Browser.Url.createObjectURL(blob);
                }
            }
            return url;
        });

        if (zip.exists('doc.kml')) {
            var xml = new DOMParser().parseFromString(Fflate.strFromU8(zip['doc.kml']), 'application/xml');
            var model = xml.querySelector('Placemark Model Link href');
            if (model != null) {
                var loader = new ColladaLoader(manager);
                return loader.parse(Fflate.strFromU8(zip[model.textContent]));
            }
        } else {
            console.warn('KMZLoader: Missing doc.kml file.');
            for (path in zip.keys()) {
                var extension = path.split('.').pop().toLowerCase();
                if (extension == 'dae') {
                    var loader = new ColladaLoader(manager);
                    return loader.parse(Fflate.strFromU8(zip[path]));
                }
            }
        }
        console.error('KMZLoader: Couldn\'t find .dae file.');
        return { scene: new Group() };
    }
}