import js.Browser;
import js.html.CanvasElement;
import js.html.ImageData;
import js.html.ImageElement;
import js.html.HTMLImageElement;
import js.html.HTMLCanvasElement;
import js.html.ImageBitmap;

class ImageUtils {

    static var _canvas:CanvasElement;

    static function getDataURL(image:Dynamic):String {

        if (Browser.regexp('^data:/i').test(image.src)) {
            return image.src;
        }

        if (typeof HTMLCanvasElement == 'undefined') {
            return image.src;
        }

        var canvas:CanvasElement;

        if (Std.is(image, HTMLCanvasElement)) {
            canvas = cast(image, CanvasElement);
        } else {
            if (_canvas == null) _canvas = cast(Browser.document.createElementNS('canvas'), CanvasElement);

            _canvas.width = image.width;
            _canvas.height = image.height;

            var context = _canvas.getContext('2d');

            if (Std.is(image, ImageData)) {
                context.putImageData(cast(image, ImageData), 0, 0);
            } else {
                context.drawImage(cast(image, HTMLImageElement), 0, 0, image.width, image.height);
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

    static function sRGBToLinear(image:Dynamic):Dynamic {

        if ((typeof HTMLImageElement != 'undefined' && Std.is(image, HTMLImageElement)) ||
            (typeof HTMLCanvasElement != 'undefined' && Std.is(image, HTMLCanvasElement)) ||
            (typeof ImageBitmap != 'undefined' && Std.is(image, ImageBitmap))) {

            var canvas = cast(Browser.document.createElementNS('canvas'), CanvasElement);

            canvas.width = image.width;
            canvas.height = image.height;

            var context = canvas.getContext('2d');
            context.drawImage(cast(image, HTMLImageElement), 0, 0, image.width, image.height);

            var imageData = context.getImageData(0, 0, image.width, image.height);
            var data = imageData.data;

            for (i in 0...data.length) {
                data[i] = Math.floor(SRGBToLinear(data[i] / 255) * 255);
            }

            context.putImageData(imageData, 0, 0);

            return canvas;

        } else if (image.data) {

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