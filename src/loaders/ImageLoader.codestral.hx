import three.js.loaders.Cache;
import three.js.loaders.Loader;
import three.js.utils.createElementNS;
import js.html.ImageElement;

class ImageLoader extends Loader {

    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):ImageElement {
        if (this.path != null) url = this.path + url;
        url = this.manager.resolveURL(url);

        var cached = Cache.get(url);
        if (cached != null) {
            this.manager.itemStart(url);
            var _g = () -> {
                if (onLoad != null) onLoad(cached);
                this.manager.itemEnd(url);
            };
            js.Browser.window.setTimeout(_g, 0);
            return cached;
        }

        var image = createElementNS('img');
        var _g1 = image;
        var _g2 = () -> {
            image.removeEventListener('load', onImageLoad);
            image.removeEventListener('error', onImageError);
            if (onLoad != null) onLoad(this);
            this.manager.itemEnd(url);
        };
        var onImageLoad = _g1.addEventListener('load', _g2);

        var _g3 = image;
        var _g4 = (event) -> {
            image.removeEventListener('load', onImageLoad);
            image.removeEventListener('error', onImageError);
            if (onError != null) onError(event);
            this.manager.itemError(url);
            this.manager.itemEnd(url);
        };
        var onImageError = _g3.addEventListener('error', _g4);

        if (url.substring(0, 5) != 'data:') {
            if (this.crossOrigin != null) image.crossOrigin = this.crossOrigin;
        }

        this.manager.itemStart(url);
        image.src = url;
        return image;
    }
}