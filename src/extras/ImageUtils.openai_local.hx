import utils.createElementNS;
import math.ColorManagement.SRGBToLinear;

class ImageUtils {

    static var _canvas:CanvasElement;

    public static function getDataURL(image:Dynamic):String {

        if (~/^data:/i.match(image.src)) {
            return image.src;
        }

        if (Type.resolveClass("js.html.HTMLCanvasElement") == null) {
            return image.src;
        }

        var canvas:CanvasElement;

        if (Std.is(image, js.html.HTMLCanvasElement)) {
            canvas = cast image;
        } else {
            if (_canvas == null) _canvas = createElementNS('canvas');

            _canvas.width = image.width;
            _canvas.height = image.height;

            var context = _canvas.getContext('2d').cast<CanvasRenderingContext2D>();

            if (Std.is(image, js.html.ImageData)) {
                context.putImageData(cast image, 0, 0);
            } else {
                context.drawImage(cast image, 0, 0, image.width, image.height);
            }

            canvas = _canvas;
        }

        if (canvas.width > 2048 || canvas.height > 2048) {
            trace('THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons', image);
            return canvas.toDataURL('image/jpeg', 0.6);
        } else {
            return canvas.toDataURL('image/png');
        }
    }

    public static function sRGBToLinear(image:Dynamic):Dynamic {

        if ((Type.resolveClass("js.html.HTMLImageElement") != null && Std.is(image, js.html.HTMLImageElement)) ||
            (Type.resolveClass("js.html.HTMLCanvasElement") != null && Std.is(image, js.html.HTMLCanvasElement)) ||
            (Type.resolveClass("js.html.ImageBitmap") != null && Std.is(image, js.html.ImageBitmap))) {

            var canvas = createElementNS('canvas');

            canvas.width = image.width;
            canvas.height = image.height;

            var context = canvas.getContext('2d').cast<CanvasRenderingContext2D>();
            context.drawImage(cast image, 0, 0, image.width, image.height);

            var imageData = context.getImageData(0, 0, image.width, image.height);
            var data = imageData.data;

            for (i in 0...data.length) {
                data[i] = SRGBToLinear(data[i] / 255) * 255;
            }

            context.putImageData(imageData, 0, 0);

            return canvas;

        } else if (Reflect.hasField(image, "data")) {

            var data = image.data.slice(0);

            for (i in 0...data.length) {
                if (Std.is(data, Uint8Array) || Std.is(data, Uint8ClampedArray)) {
                    data[i] = Math.floor(SRGBToLinear(data[i] / 255) * 255);
                } else {
                    data[i] = SRGBToLinear(data[i]);
                }
            }

            return {
                data: data,
                width: image.width,
                height: image.height
            };

        } else {

            trace('THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.');
            return image;

        }

    }

}