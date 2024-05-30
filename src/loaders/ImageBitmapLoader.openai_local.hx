import three.loaders.Cache;
import three.loaders.Loader;

class ImageBitmapLoader extends Loader {

    public var isImageBitmapLoader:Bool;
    public var options:Dynamic;

    public function new(manager:Dynamic) {
        super(manager);
        this.isImageBitmapLoader = true;

        if (untyped __js__("typeof createImageBitmap === 'undefined'")) {
            trace('THREE.ImageBitmapLoader: createImageBitmap() not supported.');
        }

        if (untyped __js__("typeof fetch === 'undefined'")) {
            trace('THREE.ImageBitmapLoader: fetch() not supported.');
        }

        this.options = { premultiplyAlpha: 'none' };
    }

    public function setOptions(options:Dynamic):ImageBitmapLoader {
        this.options = options;
        return this;
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        if (url == null) url = '';
        if (this.path != null) url = this.path + url;

        url = this.manager.resolveURL(url);

        var scope = this;

        var cached = Cache.get(url);

        if (cached != null) {
            scope.manager.itemStart(url);

            // If cached is a promise, wait for it to resolve
            if (Reflect.hasField(cached, "then")) {
                cached.then(function(imageBitmap:Dynamic) {
                    if (onLoad != null) onLoad(imageBitmap);
                    scope.manager.itemEnd(url);
                }).catch(function(e:Dynamic) {
                    if (onError != null) onError(e);
                });
                return;
            }

            // If cached is not a promise (i.e., it's already an imageBitmap)
            haxe.Timer.delay(function() {
                if (onLoad != null) onLoad(cached);
                scope.manager.itemEnd(url);
            }, 0);

            return;
        }

        var fetchOptions = {};
        fetchOptions.credentials = (this.crossOrigin == 'anonymous') ? 'same-origin' : 'include';
        fetchOptions.headers = this.requestHeader;

        var promise = js.Promise.resolve(js.Browser.window.fetch(url, fetchOptions)).then(function(res:Dynamic) {
            return res.blob();
        }).then(function(blob:Dynamic) {
            return untyped __js__("createImageBitmap")(blob, Object.assign(scope.options, { colorSpaceConversion: 'none' }));
        }).then(function(imageBitmap:Dynamic) {
            Cache.add(url, imageBitmap);
            if (onLoad != null) onLoad(imageBitmap);
            scope.manager.itemEnd(url);
            return imageBitmap;
        }).catch(function(e:Dynamic) {
            if (onError != null) onError(e);
            Cache.remove(url);
            scope.manager.itemError(url);
            scope.manager.itemEnd(url);
        });

        Cache.add(url, promise);
        scope.manager.itemStart(url);
    }
}