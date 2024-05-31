import threejs.Cache;
import threejs.Loader;
import threejs.utils.createElementNS;

class ImageLoader extends Loader {

    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Dynamic {
        if (this.path != null) url = this.path + url;

        url = this.manager.resolveURL(url);

        var scope = this;
        var cached = Cache.get(url);

        if (cached != null) {
            scope.manager.itemStart(url);

            haxe.Timer.delay(function() {
                if (onLoad != null) onLoad(cached);
                scope.manager.itemEnd(url);
            }, 0);

            return cached;
        }

        var image = createElementNS('img');

        function onImageLoad(event:Dynamic):Void {
            removeEventListeners();
            Cache.add(url, image);
            if (onLoad != null) onLoad(image);
            scope.manager.itemEnd(url);
        }

        function onImageError(event:Dynamic):Void {
            removeEventListeners();
            if (onError != null) onError(event);
            scope.manager.itemError(url);
            scope.manager.itemEnd(url);
        }

        function removeEventListeners():Void {
            image.removeEventListener('load', onImageLoad, false);
            image.removeEventListener('error', onImageError, false);
        }

        image.addEventListener('load', onImageLoad, false);
        image.addEventListener('error', onImageError, false);

        if (url.substr(0, 5) != 'data:') {
            if (this.crossOrigin != null) image.crossOrigin = this.crossOrigin;
        }

        scope.manager.itemStart(url);
        image.src = url;

        return image;
    }
}

@:jsRequire("three", "Cache")
@:jsRequire("three", "Loader")
@:jsRequire("three/utils", "createElementNS")
class Main {
    static function main() {
        // 可以在这里测试 ImageLoader 类的实例化和方法调用
    }
}