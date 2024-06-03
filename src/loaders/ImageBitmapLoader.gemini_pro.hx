import Cache from "./Cache";
import Loader from "./Loader";

class ImageBitmapLoader extends Loader {

  public var isImageBitmapLoader:Bool = true;
  public var options:Dynamic;

  public function new(manager:Loader) {
    super(manager);

    if (js.Lib.isUnresolved(js.Lib.global.createImageBitmap)) {
      Sys.warning("THREE.ImageBitmapLoader: createImageBitmap() not supported.");
    }

    if (js.Lib.isUnresolved(js.Lib.global.fetch)) {
      Sys.warning("THREE.ImageBitmapLoader: fetch() not supported.");
    }

    options = { premultiplyAlpha: "none" };
  }

  public function setOptions(options:Dynamic):ImageBitmapLoader {
    this.options = options;
    return this;
  }

  public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Dynamic {
    if (url == null) {
      url = "";
    }

    if (path != null) {
      url = path + url;
    }

    url = manager.resolveURL(url);

    var scope = this;

    var cached = Cache.get(url);

    if (cached != null) {
      manager.itemStart(url);

      if (js.Lib.isUnresolved(cached.then)) {
        cached.then(function(imageBitmap) {
          if (onLoad != null) {
            onLoad(imageBitmap);
          }
          scope.manager.itemEnd(url);
        }).catch(function(e) {
          if (onError != null) {
            onError(e);
          }
        });
        return;
      }

      Timer.delay(function() {
        if (onLoad != null) {
          onLoad(cached);
        }
        scope.manager.itemEnd(url);
      }, 0);
      return cached;
    }

    var fetchOptions:Dynamic = {};
    fetchOptions.credentials = (crossOrigin == "anonymous") ? "same-origin" : "include";
    fetchOptions.headers = requestHeader;

    var promise = js.Lib.global.fetch(url, fetchOptions).then(function(res) {
      return res.blob();
    }).then(function(blob) {
      return js.Lib.global.createImageBitmap(blob, js.Lib.assign(scope.options, { colorSpaceConversion: "none" }));
    }).then(function(imageBitmap) {
      Cache.add(url, imageBitmap);

      if (onLoad != null) {
        onLoad(imageBitmap);
      }
      scope.manager.itemEnd(url);
      return imageBitmap;
    }).catch(function(e) {
      if (onError != null) {
        onError(e);
      }

      Cache.remove(url);

      scope.manager.itemError(url);
      scope.manager.itemEnd(url);
    });

    Cache.add(url, promise);
    scope.manager.itemStart(url);
  }
}

export function ImageBitmapLoader() {
  return new ImageBitmapLoader(null);
}