import js.Browser.Window;
import js.html.Image;

class TextureLoader extends Loader {

	public function new(manager:Dynamic) {
		super(manager);
	}

	public function load(url:String, onLoad:Texture->Void, onProgress:Float->Void, onError:Dynamic->Void):Texture {
		var texture = Texture.createEmpty();
		var loader = ImageLoader.fromManager(manager);
		loader.setCrossOrigin(crossOrigin);
		loader.setPath(path);

		loader.load(url, function(image:Image) {
			texture.image = image;
			texture.needsUpdate = true;
			if (onLoad != null) {
				onLoad(texture);
			}
		}, onProgress, onError);

		return texture;
	}

}

class ImageLoader {

	public static function fromManager(manager:Dynamic):ImageLoader {
		return new ImageLoader(manager);
	}

	public function new(manager:Dynamic) {
		this.manager = manager;
	}

	public function load(url:String, onLoad:Image->Void, onProgress:Float->Void, onError:Dynamic->Void):Void {
		var image = Image.fromWindow(Window.window);
		image.onload = function() {
			onLoad(image);
		};
		image.src = url;
	}

	public function setCrossOrigin(crossOrigin:String):Void {
		this.crossOrigin = crossOrigin;
	}

	public function setPath(path:String):Void {
		this.path = path;
	}

	private manager:Dynamic;
	private crossOrigin:String;
	private path:String;

}

class Texture {

	public static function createEmpty():Texture {
		return new Texture();
	}

	public function new() {
		this.image = null;
		this.needsUpdate = false;
	}

	public var image:Image;
	public var needsUpdate:Bool;

}

class Loader {

	public function new(manager:Dynamic) {
		this.manager = manager;
	}

	public var manager:Dynamic;
	public var crossOrigin:String;
	public var path:String;

}