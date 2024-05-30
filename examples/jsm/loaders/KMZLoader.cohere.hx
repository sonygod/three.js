import haxe.io.Bytes;

class KMZLoader {
    function new(manager:LoadingManager) {
        // ...
    }

    function load(url:String, onLoad:Function, onProgress:Function, onError:Function):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.path = scope.path;
        loader.responseType = 'arraybuffer';
        loader.setRequestHeader(scope.requestHeader);
        loader.withCredentials = scope.withCredentials;
        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    function parse(data:Bytes):Void {
        function findFile(url:String):Bytes {
            var path:String;
            for (path in zip) {
                if (path.endsWith(url)) {
                    return zip[path];
                }
            }
            return null;
        }

        var manager = new LoadingManager();
        manager.setURLModifier(function(url:String):String {
            var image = findFile(url);
            if (image != null) {
                trace.log('Loading $url');
                var blob = new Blob([image.getData()], { type: 'application/octet-stream' });
                return URL.createObjectURL(blob);
            }
            return url;
        });

        var zip = fflate.unzipSync(data);
        if (zip.exists('doc.kml')) {
            var xml = new DOMParser().parseFromString(fflate.strFromU8(zip.get('doc.kml')));
            var model = xml.querySelector('Placemark Model Link href');
            if (model != null) {
                var loader = new ColladaLoader(manager);
                return loader.parse(fflate.strFromU8(zip.get(model.textContent)));
            }
        } else {
            trace.warn('KMZLoader: Missing doc.kml file.');
            var path:String;
            var extension:String;
            for (path in zip) {
                extension = path.split('.').pop().toLowerCase();
                if (extension == 'dae') {
                    var loader = new ColladaLoader(manager);
                    return loader.parse(fflate.strFromU8(zip.get(path)));
                }
            }
        }
        trace.error('KMZLoader: Couldn\'t find .dae file.');
        return { scene: new Group() };
    }
}

class LoadingManager {
    // ...
}

class FileLoader {
    // ...
}

class ColladaLoader {
    // ...
}

class Group {
    // ...
}

class DOMParser {
    // ...
}

class Blob {
    // ...
}

class URL {
    // ...
}

class fflate {
    public static function unzipSync(data:Bytes):Dynamic {
        // ...
    }

    public static function strFromU8(data:Bytes):String {
        // ...
    }
}