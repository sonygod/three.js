import three.utils.Utils.createElementNS;
import three.math.ColorManagement.SRGBToLinear;

class ImageUtils {

	static function getDataURL(image:Dynamic):String {

		if (StringTools.startsWith(image.src,"data:")) {

			return image.src;

		}

		if (js.html.HTMLCanvasElement == null) {

			return image.src;

		}

		var canvas:js.html.HTMLCanvasElement;

		if (js.Boot.is(image, js.html.HTMLCanvasElement)) {

			canvas = image;

		} else {

			if (_canvas == null) _canvas = createElementNS("canvas");

			_canvas.width = image.width;
			_canvas.height = image.height;

			var context = _canvas.getContext("2d");

			if (js.Boot.is(image, js.html.ImageData)) {

				context.putImageData(image, 0, 0);

			} else {

				context.drawImage(image, 0, 0, image.width, image.height);

			}

			canvas = _canvas;

		}

		if (canvas.width > 2048 || canvas.height > 2048) {

			Sys.println("THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons " + image);

			return canvas.toDataURL("image/jpeg", 0.6);

		} else {

			return canvas.toDataURL("image/png");

		}

	}

	static function sRGBToLinear(image:Dynamic):Dynamic {

		if ((js.html.HTMLImageElement != null && js.Boot.is(image, js.html.HTMLImageElement)) ||
			(js.html.HTMLCanvasElement != null && js.Boot.is(image, js.html.HTMLCanvasElement)) ||
			(js.html.ImageBitmap != null && js.Boot.is(image, js.html.ImageBitmap))) {

			var canvas = createElementNS("canvas");

			canvas.width = image.width;
			canvas.height = image.height;

			var context = canvas.getContext("2d");
			context.drawImage(image, 0, 0, image.width, image.height);

			var imageData = context.getImageData(0, 0, image.width, image.height);
			var data = imageData.data;

			for (var i = 0; i < data.length; i++) {

				data[i] = Std.int(SRGBToLinear(data[i] / 255) * 255);

			}

			context.putImageData(imageData, 0, 0);

			return canvas;

		} else if (Reflect.hasField(image, "data")) {

			var data = Reflect.field(image, "data").copy();

			for (var i = 0; i < data.length; i++) {

				if (js.Boot.is(data, js.html.Uint8Array) || js.Boot.is(data, js.html.Uint8ClampedArray)) {

					data[i] = Std.int(SRGBToLinear(data[i] / 255) * 255);

				} else {

					// assuming float

					data[i] = SRGBToLinear(data[i]);

				}

			}

			return {
				data : data,
				width : image.width,
				height : image.height
			};

		} else {

			Sys.println("THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.");
			return image;

		}

	}

	static var _canvas:js.html.HTMLCanvasElement;
}