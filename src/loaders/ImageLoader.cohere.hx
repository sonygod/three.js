import js.Browser.Location;
import js.Browser.XMLHttpRequest;
import js.html.HTMLElement;
import js.html.HTMLImageElement;

class ImageLoader extends Loader {
    public function new(manager:Loader) {
        super(manager);
    }

    public function load(url:String, onLoad:Null<Function>, onProgress:Null<Function>, onError:Null<Function>):HTMLImageElement {
        if (path != null) url = path + url;

        url = manager.resolveURL(url);

        var cached = Cache.get(url);
        if (cached != null) {
            manager.itemStart(url);

            var scope = this;
            setTimeout(function() {
                if (onLoad != null) onLoad(cached);
                scope.manager.itemEnd(url);
            }, 0);

            return cached;
        }

        var image = cast HTMLImageElement HTMLElement.create('img');

        function onImageLoad() {
            removeEventListeners();

            Cache.add(url, cast HTMLImageElement image);

            if (onLoad != null) onLoad(image);

            manager.itemEnd(url);
        }

        function onImageError(event:Dynamic) {
            removeEventListeners();

            if (onError != null) onError(event);

            manager.itemError(url);
            manager.itemEnd(url);
        }

        function removeEventListeners() {
            image.removeEventListener('load', onImageLoad, false);
            image.removeEventListener('error', onImageError, false);
        }

        image.addEventListener('load', onImageLoad, false);
        image.addEventListener('error', onImageError, false);

        if (url.indexOf('data:', 0, 5) != 0) {
            if (crossOrigin != null) image.crossOrigin = crossOrigin;
        }

        manager.itemStart(url);

        image.src = url;

        return image;
    }
}

class Cache {
    static function get(url:String):Null<HTMLImageElement> {
        return null;
    }

    static function add(url:String, image:HTMLImageElement):Void {
    }
}

class Loader {
    public var path:Null<String>;
    public var crossOrigin:Null<String>;
    public var manager:Null<Dynamic>;

    public function new(manager:Dynamic) {
        this.manager = manager;
    }

    public function resolveURL(url:String):String {
        return Location.href.split('?')[0] + url;
    }

    public function itemStart(url:String):Void {
    }

    public function itemEnd(url:String):Void {
    }

    public function itemError(url:String):Void {
    }
}