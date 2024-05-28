package three.loaders;

import three.Cache;
import three.Loader;
import three.utils.createElementNS;

class ImageLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Dynamic {
        if (this.path != null) url = this.path + url;
        url = this.manager.resolveURL(url);

        var cached = Cache.get(url);
        if (cached != null) {
            this.manager.itemStart(url);
            haxe.Timer.delay(function() {
                if (onLoad != null) onLoad(cached);
                this.manager.itemEnd(url);
            }, 0);
            return cached;
        }

        var image = createElementNS('img');
        var scope = this;

        function onImageLoad(event:Dynamic) {
            removeEventListeners();
            Cache.add(url, image);
            if (onLoad != null) onLoad(image);
            scope.manager.itemEnd(url);
        }

        function onImageError(event:Dynamic) {
            removeEventListeners();
            if (onError != null) onError(event);
            scope.manager.itemError(url);
            scope.manager.itemEnd(url);
        }

        function removeEventListeners() {
            image.removeEventListener('load', onImageLoad);
            image.removeEventListener('error', onImageError);
        }

        image.addEventListener('load', onImageLoad);
        image.addEventListener('error', onImageError);

        if (url.substring(0, 5) != 'data:') {
            if (this.crossOrigin != null) image.crossOrigin = this.crossOrigin;
        }

        scope.manager.itemStart(url);
        image.src = url;
        return image;
    }
}

// export
@:keep
extern class ImageLoader extends Loader {}