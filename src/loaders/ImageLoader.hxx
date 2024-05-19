import js.Browser.document;
import js.Lib.createjs.Cache;
import js.Lib.createjs.Loader;

class ImageLoader extends Loader {

    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
        if (this.path !== undefined) url = this.path + url;

        url = this.manager.resolveURL(url);

        var scope = this;

        var cached = Cache.get(url);

        if (cached !== undefined) {
            this.manager.itemStart(url);

            js.Browser.setTimeout(function () {
                if (onLoad != null) onLoad(cached);

                scope.manager.itemEnd(url);
            }, 0);

            return cached;
        }

        var image = document.createElementNS('img');

        function onImageLoad() {
            removeEventListeners();

            Cache.add(url, this);

            if (onLoad != null) onLoad(this);

            scope.manager.itemEnd(url);
        }

        function onImageError(event) {
            removeEventListeners();

            if (onError != null) onError(event);

            scope.manager.itemError(url);
            scope.manager.itemEnd(url);
        }

        function removeEventListeners() {
            image.removeEventListener('load', onImageLoad, false);
            image.removeEventListener('error', onImageError, false);
        }

        image.addEventListener('load', onImageLoad, false);
        image.addEventListener('error', onImageError, false);

        if (url.substr(0, 5) !== 'data:') {
            if (this.crossOrigin !== undefined) image.crossOrigin = this.crossOrigin;
        }

        this.manager.itemStart(url);

        image.src = url;

        return image;
    }
}