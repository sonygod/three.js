package loaders;

import three.Cache;
import three.Loader;
import three.utils.createElementNS;

class ImageLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:(image:js.html.Image)->Void, onProgress:Dynamic, onError:(event:js.html.ErrorEvent)->Void):js.html.Image {
        if (this.path != null) url = this.path + url;
        url = this.manager.resolveURL(url);

        var cached:Dynamic = Cache.get(url);
        if (cached != null) {
            this.manager.itemStart(url);
            haxe.Timer.delay(function() {
                if (onLoad != null) onLoad(cached);
                this.manager.itemEnd(url);
            }, 0);
            return cached;
        }

        var image:js.html.Image = createElementNS('img');
        function onImageLoad(event:js.html.Event):Void {
            removeEventListeners();
            Cache.add(url, image);
            if (onLoad != null) onLoad(image);
            this.manager.itemEnd(url);
        }

        function onImageError(event:js.html.ErrorEvent):Void {
            removeEventListeners();
            if (onError != null) onError(event);
            this.manager.itemError(url);
            this.manager.itemEnd(url);
        }

        function removeEventListeners():Void {
            image.removeEventListener('load', onImageLoad);
            image.removeEventListener('error', onImageError);
        }

        image.addEventListener('load', onImageLoad);
        image.addEventListener('error', onImageError);

        if (url.substr(0, 5) != 'data:') {
            if (this.crossOrigin != null) image.crossOrigin = this.crossOrigin;
        }

        this.manager.itemStart(url);
        image.src = url;

        return image;
    }
}

// Export the ImageLoader class
extern class ImageLoader {
    public function new(manager:LoaderManager);
    public function load(url:String, onLoad:(image:js.html.Image)->Void, onProgress:Dynamic, onError:(event:js.html.ErrorEvent)->Void):js.html.Image;
}