import three.Cache;
import three.Loader;
import js.lib.Promise;
import js.Browser;

class ImageBitmapLoader extends Loader {

    public var isImageBitmapLoader:Bool;
    public var options:Dynamic;

    public function new(manager:Dynamic) {
        super(manager);
        this.isImageBitmapLoader = true;

        if (Reflect.field(Browser, "createImageBitmap") == null) {
            haxe.Log.trace('THREE.ImageBitmapLoader: createImageBitmap() not supported.', { fileName: "ImageBitmapLoader.hx", lineNumber: 12 });
        }

        if (Reflect.field(Browser, "fetch") == null) {
            haxe.Log.trace('THREE.ImageBitmapLoader: fetch() not supported.', { fileName: "ImageBitmapLoader.hx", lineNumber: 16 });
        }

        this.options = { premultiplyAlpha: 'none' };
    }

    public function setOptions(options:Dynamic):ImageBitmapLoader {
        this.options = options;
        return this;
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        if (url == null) url = '';

        if (this.path != null) url = this.path + url;

        url = this.manager.resolveURL(url);

        var scope = this;
        var cached = Cache.get(url);

        if (cached != null) {
            scope.manager.itemStart(url);

            // 如果缓存的是一个Promise，等待其解决
            if (Std.is(cached, Promise)) {
                (cast cached:Promise).then(function(imageBitmap:Dynamic) {
                    if (onLoad != null) onLoad(imageBitmap);
                    scope.manager.itemEnd(url);
                }).catch(function(e:Dynamic) {
                    if (onError != null) onError(e);
                });
                return;
            }

            // 如果缓存的不是Promise（即已经是imageBitmap）
            haxe.Timer.delay(function() {
                if (onLoad != null) onLoad(cached);
                scope.manager.itemEnd(url);
            }, 0);

            return cached;
        }

        var fetchOptions = { };
        fetchOptions.credentials = (this.crossOrigin == 'anonymous') ? 'same-origin' : 'include';
        fetchOptions.headers = this.requestHeader;

        var promise:Promise<Dynamic> = Browser.fetch(url, fetchOptions).then(function(res:Dynamic) {
            return res.blob();
        }).then(function(blob:Dynamic) {
            return Browser.createImageBitmap(blob, Object.assign(scope.options, { colorSpaceConversion: 'none' }));
        }).then(function(imageBitmap:Dynamic) {
            Cache.add(url, imageBitmap);
            if (onLoad != null) onLoad(imageBitmap);
            scope.manager.itemEnd(url);
            return imageBitmap;
        }).catch(function(e:Dynamic) {
            if (onError != null) onError(e);
            Cache.remove(url);
            scope.manager.itemError(url);
            scope.manager.itemEnd(url);
        });

        Cache.add(url, promise);
        scope.manager.itemStart(url);
    }

    public static function main() {
        // 这里是一个示例的 main 函数
        var manager = new LoaderManager();
        var loader = new ImageBitmapLoader(manager);
        loader.load("path/to/image", function(image) {
            trace("Image loaded successfully.");
        }, null, function(error) {
            trace("Error loading image: " + error);
        });
    }
}