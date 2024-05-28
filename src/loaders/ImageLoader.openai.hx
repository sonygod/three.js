package three.loaders;

import three.core.Cache;
import three.loaders.Loader;
import three.utils.createElementNS;

class ImageLoader extends Loader {
    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Float->Void, onError:Dynamic->Void):Dynamic {
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

        var image = createElementNS("img");

        function onImageLoad(event:Dynamic):Void {
            removeEventListeners();
            Cache.add(url, image);
            if (onLoad != null) onLoad(image);
            this.manager.itemEnd(url);
        }

        function onImageError(event:Dynamic):Void {
            removeEventListeners();
            if (onError != null) onError(event);
            this.manager.itemError(url);
            this.manager.itemEnd(url);
        }

        function removeEventListeners():Void {
            image.removeEventListener("load", onImageLoad);
            image.removeEventListener("error", onImageError);
        }

        image.addEventListener("load", onImageLoad);
        image.addEventListener("error", onImageError);

        if (url.substr(0, 5) != "data:") {
            if (this.crossOrigin != null) image.crossOrigin = this.crossOrigin;
        }

        this.manager.itemStart(url);
        image.src = url;

        return image;
    }
}