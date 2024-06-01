import haxe.ds.StringMap;
import three.ImageUtils;
import three.MathUtils;

private var _sourceId = 0;

class Source {
	public var isSource:Bool = true;
	public var id:Int;
	public var uuid:String;
	public var data:Dynamic;
	public var dataReady:Bool;
	public var version:Int;

	public function new(data:Dynamic = null) {
		this.id = _sourceId++;
		this.uuid = MathUtils.generateUUID();
		this.data = data;
		this.dataReady = true;
		this.version = 0;
	}

	public var needsUpdate(get, set):Bool;

	private function get_needsUpdate():Bool {
		return false; // Not used in this example
	}

	private function set_needsUpdate(value:Bool):Bool {
		if (value)
			this.version++;
		return value;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject:Bool = (meta == null || Reflect.typeof(meta) == TString);

		if (!isRootObject && (Reflect.field(meta.images, this.uuid) != null)) {
			return Reflect.field(meta.images, this.uuid);
		}

		var output = {
			uuid: this.uuid,
			url: ''
		};

		var data = this.data;

		if (data != null) {
			var url:Dynamic = null;

			if (Std.isOfType(data, Array)) {
				// cube texture
				url = [];

				for (i in 0...data.length) {
					if (Reflect.hasField(data[i], "isDataTexture")) {
						url.push(serializeImage(Reflect.field(data[i], "image")));
					} else {
						url.push(serializeImage(data[i]));
					}
				}
			} else {
				// texture
				url = serializeImage(data);
			}

			output.url = url;
		}

		if (!isRootObject) {
			if (meta.images == null) {
				meta.images = {};
			}
			Reflect.setField(meta.images, this.uuid, output);
		}

		return output;
	}
}

function serializeImage(image:Dynamic):Dynamic {
	if (Std.isOfType(image, js.html.Image)
		|| Std.isOfType(image, js.html.CanvasElement)
		|| Std.isOfType(image, js.html.ImageBitmap)) {
		// default images
		return ImageUtils.getDataURL(cast image);
	} else {
		if (Reflect.hasField(image, "data")) {
			// images of DataTexture
			return {
				data: untyped image.data.buffer, // Assuming 'data' is a typed array
				width: image.width,
				height: image.height,
				type: Type.getClassName(Type.getClass(image.data))
			};
		} else {
			trace('THREE.Texture: Unable to serialize Texture.');
			return {};
		}
	}
}