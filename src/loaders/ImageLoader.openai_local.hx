import three.Cache;
import three.Loader;
import js.Browser.document;
import js.html.Image;

class ImageLoader extends Loader {

    public function new(manager:Dynamic) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Image {
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
        
        var image:Image = cast document.createElement("img");
        
        var onImageLoad = function(_:Event):Void {
            removeEventListeners();
            Cache.add(url, image);
            if (onLoad != null) onLoad(image);
            scope.manager.itemEnd(url);
        };
        
        var onImageError = function(event:Event):Void {
            removeEventListeners();
            if (onError != null) onError(event);
            scope.manager.itemError(url);
            scope.manager.itemEnd(url);
        };
        
        var removeEventListeners = function():Void {
            image.removeEventListener('load', onImageLoad, false);
            image.removeEventListener('error', onImageError, false);
        };
        
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