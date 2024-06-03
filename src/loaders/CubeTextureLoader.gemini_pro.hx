import haxe.io.Bytes;
import js.html.Image;
import openfl.display.BitmapData;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.TextureBase;
import openfl.events.Event;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;

class CubeTextureLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(urls:Array<String>, onLoad:TextureBase->Void, onProgress:Event->Void, onError:Event->Void):CubeTexture {
		var texture = new CubeTexture();
		texture.colorSpace = SRGBColorSpace;

		var loader = new ImageLoader(this.manager);
		loader.setCrossOrigin(this.crossOrigin);
		loader.setPath(this.path);

		var loaded = 0;

		var loadTexture = function(i:Int) {
			loader.load(urls[i], function(image:Image) {
				texture.images[i] = image;
				loaded++;

				if (loaded == 6) {
					texture.needsUpdate = true;

					if (onLoad != null) onLoad(texture);
				}
			}, null, onError);
		};

		for (i in 0...urls.length) {
			loadTexture(i);
		}

		return texture;
	}
}

class ImageLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Image->Void, onProgress:Event->Void, onError:Event->Void):Void {
		var image = new Image();
		image.onload = function() {
			if (onLoad != null) onLoad(image);
		};
		image.onerror = function() {
			if (onError != null) onError(null);
		};
		image.src = url;
	}
}

class Loader {

	public var manager:Loader;
	public var crossOrigin:String;
	public var path:String;

	public function new(manager:Loader) {
		this.manager = manager;
	}

	public function setCrossOrigin(value:String):Void {
		this.crossOrigin = value;
	}

	public function setPath(value:String):Void {
		this.path = value;
	}
}

enum SRGBColorSpace {
	SRGBColorSpace;
}