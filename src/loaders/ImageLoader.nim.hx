import three.js.src.loaders.Cache;
import three.js.src.loaders.Loader;
import three.js.src.utils.createElementNS;

class ImageLoader extends Loader {

    public function new(manager:Loader.Manager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {

        if (this.path !== null) url = this.path + url;

        url = this.manager.resolveURL(url);

        var cached = Cache.get(url);

        if (cached !== null) {

            this.manager.itemStart(url);

            setTimeout(function () {

                if (onLoad != null) onLoad(cached);

                this.manager.itemEnd(url);

            }, 0);

            return cached;

        }

        var image = createElementNS('img');

        function onImageLoad() {

            removeEventListeners();

            Cache.add(url, this);

            if (onLoad != null) onLoad(this);

            this.manager.itemEnd(url);

        }

        function onImageError(event:Dynamic) {

            removeEventListeners();

            if (onError != null) onError(event);

            this.manager.itemError(url);
            this.manager.itemEnd(url);

        }

        function removeEventListeners() {

            image.removeEventListener('load', onImageLoad, false);
            image.removeEventListener('error', onImageError, false);

        }

        image.addEventListener('load', onImageLoad, false);
        image.addEventListener('error', onImageError, false);

        if (url.slice(0, 5) !== 'data:') {

            if (this.crossOrigin !== null) image.crossOrigin = this.crossOrigin;

        }

        this.manager.itemStart(url);

        image.src = url;

        return image;

    }

}

export(default) ImageLoader;