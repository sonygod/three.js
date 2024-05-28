import js.Browser.Window;
import js.html.Image;
import js.html.ImageElement;
import js.html.ImageData;
import js.html.MediaError;
import js.html.TimeRanges;
import js.html.Video;
import js.html.VideoElement;
import js.html._Canvas;
import js.html._CanvasRenderingContext2D;
import js.html._HTMLCanvasElement;
import js.html._HTMLImageElement;
import js.html._HTMLVideoElement;
import js.html._ImageData;
import js.html._TimeRanges;
import js.html._Window;
import js.lib.File;
import js.sys.ArrayBuffer;
import js.sys.DataView;
import js.sys.Float32Array;
import js.sys.Float64Array;
import js.sys.Int16Array;
import js.sys.Int32Array;
import js.sys.Int8Array;
import js.sys.Uint16Array;
import js.sys.Uint32Array;
import js.sys.Uint8Array;
import js.sys.Uint8ClampedArray;

class CubeTextureLoader extends Loader {
	public function new(manager:BaseLoader) {
		super(manager);
	}

	public function load(urls:Array<String>, onLoad:CubeTexture->Void, onProgress:Float->Void, onError:Dynamic->Void):CubeTexture {
		var texture = new CubeTexture();
		texture.colorSpace = SRGBColorSpace;

		var loader = new ImageLoader(manager);
		loader.crossOrigin = crossOrigin;
		loader.path = path;

		var loaded = 0;

		function loadTexture(i:Int) {
			loader.load(urls[i], function(image:_Image) {
				texture.images[i] = image;

				loaded++;

				if (loaded == 6) {
					texture.needsUpdate = true;

					if (onLoad != null) {
						onLoad(texture);
					}
				}
			}, null, onError);
		}

		for (i in 0...urls.length) {
			loadTexture(i);
		}

		return texture;
	}
}

class _Image extends Image {
}

class BaseLoader {
}

class CubeTexture {
	public var colorSpace:Int;
	public var images:Array<_Image>;
	public var needsUpdate:Bool;
}

class ImageLoader extends Loader {
	public function new(manager:BaseLoader) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic->Void, onProgress:Float->Void, onError:Dynamic->Void) {

	}

	public function setCrossOrigin(value:String) {

	}

	public function setPath(value:String) {

	}
}

class Loader {
	public var crossOrigin:String;
	public var path:String;

	public function new(manager:BaseLoader) {

	}
}

class SRGBColorSpace {

}