package three.loaders;

import three.loaders.Cache;
import three.loaders.Loader;

class ImageBitmapLoader extends Loader {
    public var isImageBitmapLoader:Bool = true;

    public function new(manager:LoaderManager) {
        super(manager);
        if (typeof createImageBitmap == 'undefined') {
            trace('THREE.ImageBitmapLoader: createImageBitmap() not supported.');
        }
        if (typeof fetch == 'undefined') {
            trace('THREE.ImageBitmapLoader: fetch() not supported.');
        }
        options = { premultiplyAlpha: 'none' };
    }

    public function setOptions(options:Dynamic):ImageBitmapLoader {
        this.options = options;
        return this;
    }

    public function load(url:String, onLoad:ImageBitmap->Void, onProgress:Void->Void, onError:Error->Void):Void {
        if (url == null) url = '';
        if (path != null) url = path + url;
        url = manager.resolveURL(url);

        var cached:Dynamic = Cache.get(url);
        if (cached != null) {
            manager.itemStart(url);
            if (Reflect.isFunction(cached.then)) {
                cached.then(function(imageBitmap:ImageBitmap) {
                    if (onLoad != null) onLoad(imageBitmap);
                    manager.itemEnd(url);
                }).catchError(function(e:Error) {
                    if (onError != null) onError(e);
                });
                return;
            }
            haxe.Timer.delay(function() {
                if (onLoad != null) onLoad(cached);
                manager.itemEnd(url);
            }, 0);
            return cached;
        }

        var fetchOptions:Dynamic = {};
        fetchOptions.credentials = if (crossOrigin == 'anonymous') 'same-origin' else 'include';
        fetchOptions.headers = requestHeader;

        var promise:Promise<ImageBitmap> = fetch(url, fetchOptions)
            .then(function(res:Dynamic) {
                return res.blob();
            })
            .then(function(blob:Dynamic) {
                return createImageBitmap(blob, Object.assign(options, { colorSpaceConversion: 'none' }));
            })
            .then(function(imageBitmap:ImageBitmap) {
                Cache.add(url, imageBitmap);
                if (onLoad != null) onLoad(imageBitmap);
                manager.itemEnd(url);
                return imageBitmap;
            })
            .catchError(function(e:Error) {
                if (onError != null) onError(e);
                Cache.remove(url);
                manager.itemError(url);
                manager.itemEnd(url);
            });
        Cache.add(url, promise);
        manager.itemStart(url);
    }
}