Here is the converted Haxe code:
```
package three.loaders;

import three.Cache;
import three.Loader;

class ImageBitmapLoader extends Loader {
    public var isImageBitmapLoader:Bool = true;

    public function new(manager:Loader) {
        super(manager);
        if (js.Browser.createImageBitmap == null) {
            trace("THREE.ImageBitmapLoader: createImageBitmap() not supported.");
        }
        if (js.Browser.fetch == null) {
            trace("THREE.ImageBitmapLoader: fetch() not supported.");
        }
        options = { premultiplyAlpha: 'none' };
    }

    public function setOptions(options:Dynamic):ImageBitmapLoader {
        this.options = options;
        return this;
    }

    public function load(url:String, onLoad:(imageBitmap:js.html.ImageBitmap) -> Void, onProgress:Void->Void, onError:(e:Dynamic) -> Void):Void {
        if (url == null) url = '';
        if (path != null) url = path + url;
        url = manager.resolveURL(url);

        var cached:Dynamic = Cache.get(url);
        if (cached != null) {
            manager.itemStart(url);
            if (Reflect.hasField(cached, "then")) {
                cached.then(function(imageBitmap:js.html.ImageBitmap) {
                    if (onLoad != null) onLoad(imageBitmap);
                    manager.itemEnd(url);
                }).catchError(function(e:Dynamic) {
                    if (onError != null) onError(e);
                });
                return;
            } else {
                haxe.Timer.delay(function() {
                    if (onLoad != null) onLoad(cached);
                    manager.itemEnd(url);
                }, 0);
                return cached;
            }
        }

        var fetchOptions:Dynamic = {};
        fetchOptions.credentials = (crossOrigin == 'anonymous') ? 'same-origin' : 'include';
        fetchOptions.headers = requestHeader;

        var promise:js.Promise<js.html.ImageBitmap> = js.Browser.fetch(url, fetchOptions)
            .then(function(res:js.html.Response) {
                return res.blob();
            })
            .then(function(blob:js.lib.html.Blob) {
                return js.Browser.createImageBitmap(blob, Object.assign(options, { colorSpaceConversion: 'none' }));
            })
            .then(function(imageBitmap:js.html.ImageBitmap) {
                Cache.add(url, imageBitmap);
                if (onLoad != null) onLoad(imageBitmap);
                manager.itemEnd(url);
                return imageBitmap;
            })
            .catchError(function(e:Dynamic) {
                if (onError != null) onError(e);
                Cache.remove(url);
                manager.itemError(url);
                manager.itemEnd(url);
            });
        Cache.add(url, promise);
        manager.itemStart(url);
    }
}
```
Note that I had to make some assumptions about the Haxe type system and the conversion of JavaScript APIs to Haxe. Specifically:

* I assumed that `js.html.ImageBitmap` is the equivalent Haxe type for the JavaScript `ImageBitmap` type.
* I used the `js.Browser` class to access the `fetch` and `createImageBitmap` APIs, as well as `js.html.Response` and `js.lib.html.Blob` for the `fetch` response and blob types.
* I used the `haxe.Timer` class to implement the `setTimeout` functionality.
* I used the `Reflect` class to check for the presence of a `then` method on the `cached` object.

Please review the converted code to ensure it meets your requirements.