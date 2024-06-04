import haxe.io.Bytes;
import haxe.io.Output;
import haxe.io.StringOutput;
import three.extras.ImageUtils;
import three.math.MathUtils;

class Source {

	public var isSource:Bool = true;
	public var id:Int;
	public var uuid:String;
	public var data:Dynamic;
	public var dataReady:Bool = true;
	public var version:Int = 0;

	public function new(data:Dynamic = null) {
		this.id = _sourceId++;
		this.uuid = MathUtils.generateUUID();
		this.data = data;
	}

	public function set needsUpdate(value:Bool) {
		if (value) this.version++;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var isRootObject:Bool = (meta == null || Std.is(meta, String));

		if (!isRootObject && meta.images[this.uuid] != null) {
			return meta.images[this.uuid];
		}

		var output = {
			uuid: this.uuid,
			url: ""
		};

		var data = this.data;

		if (data != null) {
			var url:Dynamic;

			if (Std.is(data, Array)) {
				url = [];

				for (i in 0...data.length) {
					if (Reflect.getProperty(data[i], "isDataTexture")) {
						url.push(serializeImage(Reflect.getProperty(data[i], "image")));
					} else {
						url.push(serializeImage(data[i]));
					}
				}
			} else {
				url = serializeImage(data);
			}

			output.url = url;
		}

		if (!isRootObject) {
			meta.images[this.uuid] = output;
		}

		return output;
	}

}

static var _sourceId:Int = 0;

function serializeImage(image:Dynamic):Dynamic {
	if (Std.is(image, js.html.Image)) {
		// default images
		return ImageUtils.getDataURL(image);
	} else if (Std.is(image, js.html.Canvas)) {
		// default images
		return ImageUtils.getDataURL(image);
	} else if (Std.is(image, js.html.ImageBitmap)) {
		// default images
		return ImageUtils.getDataURL(image);
	} else {
		if (Reflect.hasField(image, "data")) {
			// images of DataTexture
			var data = Reflect.getProperty(image, "data");
			var width = Reflect.getProperty(image, "width");
			var height = Reflect.getProperty(image, "height");
			return {
				data: Array.from(data),
				width: width,
				height: height,
				type: data.constructor.name
			};
		} else {
			console.warn("THREE.Texture: Unable to serialize Texture.");
			return {};
		}
	}
}