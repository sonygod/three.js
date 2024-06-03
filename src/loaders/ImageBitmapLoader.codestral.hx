import three.loaders.Cache;
import three.loaders.Loader;

class ImageBitmapLoader extends Loader {

    public function new(manager:Loader.Manager) {
        super(manager);
        this.isImageBitmapLoader = true;

        if (js.Browser.window.createImageBitmap == null) {
            trace('THREE.ImageBitmapLoader: createImageBitmap() not supported.');
        }

        if (js.Browser.window.fetch == null) {
            trace('THREE.ImageBitmapLoader: fetch() not supported.');
        }

        this.options = {premultiplyAlpha: 'none'};
    }

    public function setOptions(options:Dynamic):ImageBitmapLoader {
        this.options = options;
        return this;
    }

    public function load(url:String, onLoad:Null<(imageBitmap:Dynamic) -> Void>, onProgress:Null<(event:ProgressEvent) -> Void>, onError:Null<(event:Dynamic) -> Void>):Void {
        if (url == null) url = '';
        if (this.path != null) url = this.path + url;
        url = this.manager.resolveURL(url);

        var cached = Cache.get(url);
        if (cached != null) {
            this.manager.itemStart(url);

            if (js.Boot.hasField(cached, 'then')) {
                cached.then(imageBitmap => {
                    if (onLoad != null) onLoad(imageBitmap);
                    this.manager.itemEnd(url);
                }).catch(e => {
                    if (onError != null) onError(e);
                });
                return;
            }

            js.Browser.requestAnimationFrame(() -> {
                if (onLoad != null) onLoad(cached);
                this.manager.itemEnd(url);
            });
            return;
        }

        var fetchOptions = {
            credentials: (this.crossOrigin == 'anonymous') ? 'same-origin' : 'include',
            headers: this.requestHeader
        };

        var promise = js.Browser.window.fetch(url, fetchOptions).then(function (res) {
            return res.blob();
        }).then(function (blob) {
            var options = this.options.copy();
            options['colorSpaceConversion'] = 'none';
            return js.Browser.window.createImageBitmap(blob, options);
        }).then(function (imageBitmap) {
            Cache.add(url, imageBitmap);
            if (onLoad != null) onLoad(imageBitmap);
            this.manager.itemEnd(url);
            return imageBitmap;
        }).catch(function (e) {
            if (onError != null) onError(e);
            Cache.remove(url);
            this.manager.itemError(url);
            this.manager.itemEnd(url);
        });

        Cache.add(url, promise);
        this.manager.itemStart(url);
    }
}