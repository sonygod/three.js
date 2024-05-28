package three.js.src.extras;

import js.html.Image;
import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.ImageData;
import js.html.Uint8Array;
import js.html.Uint8ClampedArray;
import three.math.ColorManagement;

class ImageUtils {
    static var _canvas:CanvasElement;

    public static function getDataURL(image:Dynamic):String {
        if (~/\bdbata:\/i.test(image.src)) {
            return image.src;
        }

        if (Browser.window.HTMLCanvasElement == null) {
            return image.src;
        }

        var canvas:CanvasElement;

        if (Std.is(image, CanvasElement)) {
            canvas = image;
        } else {
            if (_canvas == null) _canvas = Browser.document.createElementNS('http://www.w3.org/2000/svg', 'canvas');
            _canvas.width = image.width;
            _canvas.height = image.height;

            var context:CanvasRenderingContext2D = _canvas.getContext('2d');

            if (Std.is(image, ImageData)) {
                context.putImageData(image, 0, 0);
            } else {
                context.drawImage(image, 0, 0, image.width, image.height);
            }

            canvas = _canvas;
        }

        if (canvas.width > 2048 || canvas.height > 2048) {
            Browser.console.warn('THREE.ImageUtils.getDataURL: Image converted to jpg for performance reasons', image);
            return canvas.toDataURL('image/jpeg', 0.6);
        } else {
            return canvas.toDataURL('image/png');
        }
    }

    public static function sRGBToLinear(image:Dynamic):Dynamic {
        if (Std.is(image, Image) || Std.is(image, CanvasElement) || Std.is(image, ImageBitmap)) {
            var canvas:CanvasElement = Browser.document.createElementNS('http://www.w3.org/2000/svg', 'canvas');
            canvas.width = image.width;
            canvas.height = image.height;

            var context:CanvasRenderingContext2D = canvas.getContext('2d');
            context.drawImage(image, 0, 0, image.width, image.height);

            var imageData:ImageData = context.getImageData(0, 0, image.width, image.height);
            var data:Uint8ClampedArray = imageData.data;

            for (i in 0...data.length) {
                data[i] = Math.floor(ColorManagement.SRGBToLinear(data[i] / 255) * 255);
            }

            context.putImageData(imageData, 0, 0);

            return canvas;
        } else if (image.data != null) {
            var data:Uint8Array = image.data.copy();

            for (i in 0...data.length) {
                if (Std.is(data, Uint8Array) || Std.is(data, Uint8ClampedArray)) {
                    data[i] = Math.floor(ColorManagement.SRGBToLinear(data[i] / 255) * 255);
                } else {
                    data[i] = ColorManagement.SRGBToLinear(data[i]);
                }
            }

            return {
                data: data,
                width: image.width,
                height: image.height
            };
        } else {
            Browser.console.warn('THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied.');
            return image;
        }
    }
}