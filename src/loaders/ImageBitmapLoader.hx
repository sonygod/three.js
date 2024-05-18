package loaders;

import three.Cache;
import three.Loader;

class ImageBitmapLoader extends Loader {
    
    public var isImageBitmapLoader:Bool = true;

    public function new(manager:LoaderManager) {
        super(manager);
        if (createImageBitmap == null) {
            trace('THREE.ImageBitmapLoader: createImageBitmap() not supported.');
        }
        if (fetch == null) {
            trace('THREE.ImageBitmapLoader: fetch() not supported.');
        }
        options = { premultiplyAlpha: 'none' };
    }

    public function setOptions(options:Dynamic):ImageBitmapLoader {
        this.options = options;
        return this;
    }

    public function load(url:String, onLoad:(imageBitmap:Dynamic)->Void, onProgress:(progress:Float)->Void, onError:(error:Dynamic)->Void):Void {
        if (url == null) url = '';
        if (path != null) url = path + url;
        url = manager.resolveURL(url);

        var cached:Dynamic = Cache.get(url);
        if (cached != null) {
            manager.itemStart(url);
            if (cached.then != null) {
                cached.then(function(imageBitmap:Dynamic) {
                    if (onLoad != null) onLoad(imageBitmap);
                    manager.itemEnd(url);
                }).catchError(function(e:Dynamic) {
                    if (onError != null) onError(e);
                });
                return;
            }
            // If cached is not a promise (i.e., it's already an imageBitmap)
            haxe.Timer.delay(function() {
                if (onLoad != null) onLoad(cached);
                manager.itemEnd(url);
            }, 0);
            return cached;
        }

        var fetchOptions:Dynamic = {};
        fetchOptions.credentials = (crossOrigin == 'anonymous') ? 'same-origin' : 'include';
        fetchOptions.headers = requestHeader;

        var promise:Promise<Dynamic> = fetch(url, fetchOptions).then(function(res:Dynamic) {
            return res.blob();
        }).then(function(blob:Dynamic) {
            return createImageBitmap(blob, Object.assign(options, { colorSpaceConversion: 'none' }));
        }).then(function(imageBitmap:Dynamic) {
            Cache.add(url, imageBitmap);
            if (onLoad != null) onLoad(imageBitmap);
            manager.itemEnd(url);
            return imageBitmap;
        }).catchError(function(e:Dynamic) {
            if (onError != null) onError(e);
            Cache.remove(url);
            manager.itemError(url);
            manager.itemEnd(url);
        });

        Cache.add(url, promise);
        manager.itemStart(url);
    }
}