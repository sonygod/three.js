import js.Browser.Image;
import js.Browser.CanvasElement;
import js.Browser.ImageBitmap;
import js.Browser.ImageData;
import js.Browser.Window;

class Source {
	public var isSource:Bool = true;
	public var id:Int;
	public var uuid:String;
	public var data:Dynamic;
	public var dataReady:Bool = true;
	public var version:Int = 0;

	public function new(data:Dynamic = null) {
		id = _sourceId++;
		uuid = MathUtils.generateUUID();
		this.data = data;
	}

	public function set needsUpdate(value:Bool) {
		if (value) version++;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject = (meta == null || typeof meta == 'String');
		if (!isRootObject && Reflect.hasField(meta, 'images') && Reflect.hasField(meta.images, uuid)) {
			return meta.images[uuid];
		}

		var output = { uuid: uuid, url: '' };

		if (data != null) {
			var url:Dynamic;

			if (data is Array<Dynamic>) {
				// cube texture
				url = [];
				for (i in 0...data.length) {
					var image = data[i];
					if (image is DataTexture) {
						url.push(serializeImage(image.image));
					} else {
						url.push(serializeImage(image));
					}
				}
			} else {
				// texture
				url = serializeImage(data);
			}

			output.url = url;
		}

		if (!isRootObject) {
			meta.images[uuid] = output;
		}

		return output;
	}
}

function serializeImage(image:Dynamic):Dynamic {
	if (image is Image || image is CanvasElement || image is ImageBitmap) {
		// default images
		return ImageUtils.getDataURL(image);
	} else if (Reflect.hasField(image, 'data')) {
		// images of DataTexture
		var data = image.data;
		var width = image.width;
		var height = image.height;
		var type = Std.string(data.constructor);
		return { data: data.toArray(), width: width, height: height, type: type };
	} else {
		Window.alert('Unable to serialize Texture.');
		return {};
	}
}

var _sourceId:Int = 0;

class MathUtils {
	public static function generateUUID():String {
		// implementation of generateUUID() function...
	}
}

class ImageUtils {
	public static function getDataURL(image:Dynamic):String {
		// implementation of getDataURL() function...
	}
}

class DataTexture {
	public var image:Dynamic;
	// other properties and methods...
}